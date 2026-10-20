import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'recording_file.dart';

enum CapturePhase { idle, listening, ready }

abstract class CaptureAudioBackend {
  Stream<Object> get failures => const Stream.empty();
  Future<bool> requestPermission();
  Future<void> start();
  Future<String?> stop();
  Future<void> release();
  Future<void> play(String path, VoidCallback onComplete);
  Future<void> stopPlayback();
  Future<void> delete(String path);
}

class DeviceCaptureAudio extends CaptureAudioBackend {
  AudioRecorder? _recorder;
  AudioPlayer? _player;
  StreamSubscription<void>? _completion;
  StreamSubscription<RecordState>? _recordState;
  final _failures = StreamController<Object>.broadcast();
  bool _recording = false;
  String? _path;

  @override
  Stream<Object> get failures => _failures.stream;

  @override
  Future<bool> requestPermission() async =>
      (_recorder ??= AudioRecorder()).hasPermission();

  @override
  Future<void> start() async {
    _path = await recordingPath();
    _recordState = _recorder!.onStateChanged().listen((state) {
      if (state == RecordState.stop && _recording) {
        _failures.add(StateError('Recording interrupted'));
      }
    }, onError: (Object error) => _failures.add(error));
    await _recorder!.start(
      const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1),
      path: _path!,
    );
    _recording = true;
  }

  @override
  Future<String?> stop() async {
    _recording = false;
    final path = await _recorder?.stop();
    if (path != null) _path = null;
    return path;
  }

  @override
  Future<void> release() async {
    try {
      await stopPlayback();
    } finally {
      final recorder = _recorder;
      _recorder = null;
      _recording = false;
      try {
        await _recordState?.cancel();
        _recordState = null;
        await recorder?.dispose();
      } finally {
        if (_path case final path? when !kIsWeb) {
          // A failed start can leave an incomplete temporary file.
          await deleteRecording(path);
        }
        _path = null;
      }
    }
  }

  @override
  Future<void> play(String path, VoidCallback onComplete) async {
    await stopPlayback();
    final player = _player = AudioPlayer();
    _completion = player.onPlayerComplete.listen((_) => onComplete());
    await player.play(kIsWeb ? UrlSource(path) : DeviceFileSource(path));
  }

  @override
  Future<void> stopPlayback() async {
    await _completion?.cancel();
    _completion = null;
    final player = _player;
    _player = null;
    await player?.dispose();
  }

  @override
  Future<void> delete(String path) => deleteRecording(path);
}

class CaptureAudio extends ChangeNotifier {
  CaptureAudio({CaptureAudioBackend? backend})
    : _backend = backend ?? DeviceCaptureAudio() {
    _failureSubscription = _backend.failures.listen((_) {
      if (_disposed) return;
      unawaited(
        _enqueue(() async {
          if (phase == CapturePhase.listening) await _stop();
          throw StateError('Recording failed');
        }),
      );
    });
  }

  final CaptureAudioBackend _backend;
  late final StreamSubscription<Object> _failureSubscription;
  CapturePhase phase = CapturePhase.idle;
  String? recording;
  String? error;
  bool playing = false;
  bool busy = false;
  bool _active = true;
  bool _disposed = false;
  Future<void> _operations = Future.value();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _operations.then((_) async {
      busy = true;
      _notify();
      try {
        await operation();
      } catch (_) {
        error = '录音失败，请重试。';
        phase = recording == null ? CapturePhase.idle : CapturePhase.ready;
        playing = false;
        try {
          await _backend.release();
        } catch (_) {
          // Preserve the original failure message if cleanup also fails.
        }
      } finally {
        busy = false;
        _notify();
      }
    });
    _operations = next;
    return next;
  }

  void setActive(bool value) {
    _active = value;
    if (!value) unawaited(leave());
  }

  Future<void> record() => _enqueue(() async {
    if (!_active || _disposed) return;
    error = null;
    if (phase == CapturePhase.listening) {
      await _stop();
      return;
    }
    if (!await _backend.requestPermission()) {
      error = '请允许麦克风权限后再录音。';
      await _backend.release();
      return;
    }
    if (!_active || _disposed) {
      await _backend.release();
      return;
    }
    await _clearRecording();
    await _backend.start();
    phase = CapturePhase.listening;
    if (!_active || _disposed) await _stop();
  });

  Future<void> _stop() async {
    recording = await _backend.stop();
    if (recording == null) throw StateError('No recording returned');
    phase = CapturePhase.ready;
    await _backend.release();
  }

  Future<void> playback() => _enqueue(() async {
    if (!_active || recording == null) return;
    error = null;
    if (playing) {
      await _backend.stopPlayback();
      playing = false;
      return;
    }
    try {
      await _backend.play(recording!, () {
        playing = false;
        _notify();
      });
      playing = true;
    } catch (_) {
      playing = false;
      error = '无法回放，请重新录制。';
      await _backend.stopPlayback();
    }
  });

  Future<void> _clearRecording() async {
    await _backend.stopPlayback();
    playing = false;
    if (recording case final path?) await _backend.delete(path);
    recording = null;
    phase = CapturePhase.idle;
  }

  Future<void> clear() => _enqueue(() async {
    if (phase == CapturePhase.listening) await _stop();
    await _clearRecording();
    error = null;
    await _backend.release();
  });

  Future<void> leave() => _enqueue(() async {
    if (phase == CapturePhase.listening) await _stop();
    playing = false;
    await _backend.release();
  });

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    unawaited(_failureSubscription.cancel());
    unawaited(clear());
    super.dispose();
  }
}
