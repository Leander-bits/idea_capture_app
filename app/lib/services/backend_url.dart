import 'package:flutter/foundation.dart';

// A LAN HTTPS build shares the page origin; native/local previews keep loopback.
Uri backendBaseUrl() {
  const configured = String.fromEnvironment(
    'TRANSCRIPTION_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  if (configured == 'same-origin') {
    if (!kIsWeb) throw StateError('Same-origin backend requires Web');
    return Uri.base.resolve('/');
  }
  return Uri.parse(configured);
}
