import 'dart:async';

import 'package:idea_capture/services/transcription_service.dart';

class FakeTranscriptionService implements TranscriptionService {
  final List<Completer<String>> requests = [];
  bool automatic = true;
  @override
  Future<String> transcribe(String recording) {
    final request = Completer<String>();
    requests.add(request);
    if (automatic) request.complete('');
    return request.future;
  }

  @override
  void cancel() {}
  @override
  void dispose() {}
}

TranscriptionService fakeTranscription() => FakeTranscriptionService();
