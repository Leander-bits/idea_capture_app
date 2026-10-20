import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/state/transcription_state.dart';

import 'fake_transcription.dart';

void main() {
  test(
    'auto transcribes once and blocks repeated retry during a request',
    () async {
      final service = FakeTranscriptionService()..automatic = false;
      final state = TranscriptionState(service);
      state.setRecording('first.wav');
      state.setRecording('first.wav');
      await state.retry();
      expect(service.requests.length, 1);
      service.requests.single.complete('中文结果。');
      await Future<void>.delayed(Duration.zero);
      expect(state.text, '中文结果。');
      expect(state.status, TranscriptionStatus.complete);
      state.dispose();
    },
  );
  test('failure can retry the same recording', () async {
    final service = FakeTranscriptionService()..automatic = false;
    final state = TranscriptionState(service);
    state.setRecording('first.wav');
    service.requests.single.completeError(StateError('Offline'));
    await Future<void>.delayed(Duration.zero);
    expect(state.status, TranscriptionStatus.failed);
    final retried = state.retry();
    service.requests.last.complete('重试结果。');
    await retried;
    expect(state.text, '重试结果。');
    state.dispose();
  });
  test('old success and failure cannot replace a new draft', () async {
    final service = FakeTranscriptionService()..automatic = false;
    final state = TranscriptionState(service);
    state.setRecording('first.wav');
    state.setRecording(null);
    state.setRecording('second.wav');
    service.requests.first.complete('旧结果');
    await Future<void>.delayed(Duration.zero);
    expect(state.status, TranscriptionStatus.running);
    expect(state.text, isNull);
    service.requests.last.complete('新结果');
    await Future<void>.delayed(Duration.zero);
    expect(state.text, '新结果');
    state.setRecording('third.wav');
    state.dispose();
    service.requests.last.completeError(StateError('Old failure'));
    await Future<void>.delayed(Duration.zero);
  });
}
