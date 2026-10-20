import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/audio/capture_audio.dart';

import 'fake_capture_audio.dart';

void main() {
  test('stop, playback, and re-record remove the old recording', () async {
    final backend = FakeCaptureBackend();
    final audio = CaptureAudio(backend: backend);
    await audio.record();
    expect(audio.phase, CapturePhase.listening);
    await audio.record();
    expect(audio.phase, CapturePhase.ready);
    expect(backend.recording, isFalse);
    await audio.playback();
    expect(audio.playing, isTrue);
    backend.completed!();
    expect(audio.playing, isFalse);
    await audio.record();
    expect(backend.deleted, ['recording-1.wav']);
    expect(audio.recording, isNull);
    expect(backend.starts, 2);
    await audio.clear();
    audio.dispose();
  });
  test('permission denial and recorder failure release resources', () async {
    final backend = FakeCaptureBackend()..permission = false;
    final audio = CaptureAudio(backend: backend);
    await audio.record();
    expect(audio.error, '请允许麦克风权限后再录音。');
    expect(backend.starts, 0);
    backend.permission = true;
    backend.failStart = true;
    await audio.record();
    expect(audio.error, '录音失败，请重试。');
    expect(audio.phase, CapturePhase.idle);
    expect(backend.recording, isFalse);
    expect(backend.releases, 2);
    audio.dispose();
  });
  test('leaving releases recording and playback but preserves draft', () async {
    final backend = FakeCaptureBackend();
    final audio = CaptureAudio(backend: backend);
    await audio.record();
    audio.setActive(false);
    await audio.leave();
    expect(backend.recording, isFalse);
    expect(audio.phase, CapturePhase.ready);
    expect(audio.recording, 'recording-1.wav');
    audio.setActive(true);
    await audio.playback();
    audio.setActive(false);
    await audio.leave();
    expect(backend.playing, isFalse);
    expect(audio.playing, isFalse);
    audio.dispose();
  });
  test('leaving during permission prompt cannot start recording', () async {
    final backend = FakeCaptureBackend()..permissionRequest = Completer<bool>();
    final audio = CaptureAudio(backend: backend);
    final starting = audio.record();
    await Future<void>.delayed(Duration.zero);
    audio.setActive(false);
    backend.permissionRequest!.complete(true);
    await starting;
    await audio.leave();
    expect(backend.starts, 0);
    expect(backend.recording, isFalse);
    audio.dispose();
  });
  test('playback failure preserves draft for retry', () async {
    final backend = FakeCaptureBackend()..failPlayback = true;
    final audio = CaptureAudio(backend: backend);
    await audio.record();
    await audio.record();
    await audio.playback();
    expect(audio.error, '无法回放，请重新录制。');
    expect(audio.recording, isNotNull);
    expect(audio.playing, isFalse);
    audio.dispose();
  });
}
