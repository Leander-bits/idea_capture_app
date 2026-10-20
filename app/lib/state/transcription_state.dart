import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/transcription_service.dart';

enum TranscriptionStatus { idle, running, complete, failed }

class TranscriptionState extends ChangeNotifier {
  TranscriptionState(this._service);

  final TranscriptionService _service;
  TranscriptionStatus status = TranscriptionStatus.idle;
  String? text;
  String? error;
  String? _recording;
  int _revision = 0;
  bool _disposed = false;

  void setRecording(String? recording) {
    if (recording == _recording) return;
    _revision++;
    _service.cancel();
    _recording = recording;
    status = TranscriptionStatus.idle;
    text = null;
    error = null;
    if (recording != null) {
      unawaited(retry());
    } else if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> retry() async {
    final recording = _recording;
    if (_disposed ||
        recording == null ||
        status == TranscriptionStatus.running) {
      return;
    }
    final revision = ++_revision;
    status = TranscriptionStatus.running;
    text = null;
    error = null;
    notifyListeners();
    try {
      final result = await _service.transcribe(recording);
      if (_disposed || revision != _revision) return;
      text = result;
      status = TranscriptionStatus.complete;
    } catch (_) {
      if (_disposed || revision != _revision) return;
      error = '转写失败，录音已保留，请重试。';
      status = TranscriptionStatus.failed;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _service.dispose();
    super.dispose();
  }
}
