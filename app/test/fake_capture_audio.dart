import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:idea_capture/audio/capture_audio.dart';

class FakeCaptureBackend extends CaptureAudioBackend {
  bool permission = true, failStart = false, failPlayback = false;
  bool recording = false, playing = false;
  int starts = 0, releases = 0;
  final List<String> deleted = [];
  Completer<bool>? permissionRequest;
  VoidCallback? completed;
  @override
  Future<bool> requestPermission() async =>
      permissionRequest == null ? permission : permissionRequest!.future;
  @override
  Future<void> start() async {
    if (failStart) throw StateError('Recorder failed');
    recording = true;
    starts++;
  }

  @override
  Future<String?> stop() async {
    recording = false;
    return 'recording-$starts.wav';
  }

  @override
  Future<void> release() async {
    releases++;
    recording = false;
    playing = false;
  }

  @override
  Future<void> play(String path, VoidCallback onComplete) async {
    if (failPlayback) throw StateError('Playback failed');
    playing = true;
    completed = onComplete;
  }

  @override
  Future<void> stopPlayback() async => playing = false;
  @override
  Future<void> delete(String path) async => deleted.add(path);
}

CaptureAudio fakeAudio() => CaptureAudio(backend: FakeCaptureBackend());
