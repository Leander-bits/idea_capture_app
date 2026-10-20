import 'package:idea_capture/widgets/pixel/pixel_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/audio/capture_audio.dart';

import 'fake_capture_audio.dart';

import 'package:idea_capture/widgets/pixel/pixel_status.dart';

import 'fake_transcription.dart';
import 'fake_extraction.dart';

Finder key(String value) => find.byKey(ValueKey(value));
Future<void> tap(WidgetTester tester, String value) async {
  await tester.ensureVisible(key(value));
  await tester.pumpAndSettle();
  await tester.tap(key(value));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'successful transcript removes empty status and extra spacing at phone width',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakeTranscriptionService()..automatic = false;
      await tester.pumpWidget(
        IdeaCaptureApp(
          captureAudioFactory: fakeAudio,
          extractionFactory: fakeExtraction,
          transcriptionFactory: () => service,
        ),
      );
      await tap(tester, 'nav-capture');
      await tap(tester, 'capture-control');
      await tap(tester, 'capture-control');
      expect(find.text('正在转写…'), findsOneWidget);
      service.requests.single.complete('写代码');
      await tester.pumpAndSettle();
      expect(find.byType(PixelStatusMessage), findsNothing);
      expect(key('capture-playback'), findsOneWidget);
      expect(
        tester.widget<TextField>(key('capture-text')).controller!.text,
        '写代码',
      );
      final playbackBottom = tester.getBottomLeft(key('capture-playback')).dy;
      final editorTop = tester.getTopLeft(key('capture-text')).dy;
      expect(editorTop - playbackBottom, closeTo(24, 0.1));
      await tap(tester, 'capture-playback');
      expect(find.text('停止回放'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed transcription retains replay and retries only once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = FakeTranscriptionService()..automatic = false;
    final backend = FakeCaptureBackend();
    await tester.pumpWidget(
      IdeaCaptureApp(
        captureAudioFactory: () => CaptureAudio(backend: backend),
        extractionFactory: fakeExtraction,
        transcriptionFactory: () => service,
      ),
    );
    await tap(tester, 'nav-capture');
    await tap(tester, 'capture-control');
    await tap(tester, 'capture-control');
    expect(find.text('正在转写…'), findsOneWidget);
    expect(service.requests.length, 1);
    service.requests.single.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('转写失败，录音已保留，请重试。'), findsOneWidget);
    await tap(tester, 'capture-playback');
    expect(backend.playing, isTrue);
    final retry = tester
        .widget<PixelButton>(key('capture-retry-transcription'))
        .onPressed!;
    retry();
    retry();
    await tester.pumpAndSettle();
    expect(service.requests.length, 2);
    service.requests.last.complete('明天预约检查。');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(key('capture-text')).controller!.text,
      '明天预约检查。',
    );
    expect(backend.deleted, isEmpty);
  });

  testWidgets(
    'new recording rejects stale result and user edits survive pending result',
    (tester) async {
      final service = FakeTranscriptionService()..automatic = false;
      await tester.pumpWidget(
        IdeaCaptureApp(
          captureAudioFactory: fakeAudio,
          extractionFactory: fakeExtraction,
          transcriptionFactory: () => service,
        ),
      );
      await tap(tester, 'nav-capture');
      await tap(tester, 'capture-control');
      await tap(tester, 'capture-control');
      await tap(tester, 'capture-control');
      service.requests.first.complete('旧录音结果');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(key('capture-text')).controller!.text,
        isEmpty,
      );
      await tap(tester, 'capture-control');
      await tester.enterText(key('capture-text'), '我的修改');
      service.requests.last.complete('新录音结果');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(key('capture-text')).controller!.text,
        '我的修改',
      );
      await tap(tester, 'capture-generate');
      expect(find.text('我的修改'), findsOneWidget);
      expect(service.requests.length, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
