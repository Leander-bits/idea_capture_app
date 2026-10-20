import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<String> recordingPath() async => '';

Future<void> deleteRecording(String path) async {
  web.URL.revokeObjectURL(path);
}

Future<Uint8List> readRecording(String path) async {
  final response = await web.window.fetch(path.toJS).toDart;
  if (!response.ok) throw StateError('Cannot read recording');
  return (await response.arrayBuffer().toDart).toDart.asUint8List();
}
