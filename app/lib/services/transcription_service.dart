import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../audio/recording_file.dart';
import 'backend_url.dart';

abstract interface class TranscriptionService {
  Future<String> transcribe(String recording);
  void cancel();
  void dispose();
}

class LocalTranscriptionService implements TranscriptionService {
  LocalTranscriptionService({Uri? baseUrl})
    : _baseUrl = baseUrl ?? backendBaseUrl();

  final Uri _baseUrl;
  http.Client? _client;

  @override
  Future<String> transcribe(String recording) async {
    cancel();
    final client = _client = http.Client();
    try {
      final bytes = await readRecording(recording);
      if (_client != client) throw StateError('Transcription cancelled');
      final request =
          http.MultipartRequest('POST', _baseUrl.resolve('/transcribe'))
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                bytes,
                filename: 'recording.wav',
              ),
            );
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(minutes: 15));
      if (response.statusCode != 200) throw StateError('Transcription failed');
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return (data['text'] as String).trim();
    } finally {
      client.close();
      if (_client == client) _client = null;
    }
  }

  @override
  void cancel() {
    _client?.close();
    _client = null;
  }

  @override
  void dispose() => cancel();
}
