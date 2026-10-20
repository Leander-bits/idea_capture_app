import 'package:idea_capture/widgets/pixel/pixel_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/state/task_store.dart';

import 'fake_capture_audio.dart';
import 'fake_transcription.dart';
import 'fake_extraction.dart';

Finder key(String value) => find.byKey(ValueKey(value));

Future<void> tap(WidgetTester tester, String value) async {
  await tester.ensureVisible(key(value));
  await tester.pumpAndSettle();
  await tester.tap(key(value));
  await tester.pumpAndSettle();
}

void phone(WidgetTester tester, [Size size = const Size(393, 852)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test('voice creation trims text, avoids ID collisions, and leaves optional fields empty', () {
    final store = TaskStore(const [Task(id: 'capture-1', title: '已有任务')]);
    addTearDown(store.dispose);
    expect(store.createVoiceTasks([' ', '\n']), isEmpty);
    final created = store.createVoiceTasks([' 第一个想法 ', '第二个想法']);
    expect(created.map((task) => task.id).toSet().length, 2);
    expect(created.first.id, isNot('capture-1'));
    expect(created.first.title, '第一个想法');
    for (final task in created) {
      expect(task.horizon, TaskHorizon.today);
      expect(task.source, TaskSource.voice);
      expect(task.importantToday, isFalse);
      expect(task.category, '生活');
      expect(task.priority, TaskPriority.medium);
      expect(task.suggestedStart, isNull);
      expect(task.description, isNull);
      expect(task.firstStep, isNull);
      expect(task.firstStepReason, isNull);
      expect(task.deadline, isNull);
      expect(task.duration, isNull);
    }
  });

  testWidgets('all Capture entries open the same retained screen', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      IdeaCaptureApp(
        captureAudioFactory: fakeAudio,
        extractionFactory: fakeExtraction,
        transcriptionFactory: fakeTranscription,
      ),
    );
    await tap(tester, 'today-capture');
    expect(find.text('有什么想法？'), findsOneWidget);
    await tap(tester, 'capture-control');
    await tester.enterText(key('capture-text'), '未生成的想法');
    await tap(tester, 'nav-tasks');
    await tap(tester, 'tasks-add');
    expect(
      tester.widget<TextField>(key('capture-text')).controller!.text,
      '未生成的想法',
    );
    await tap(tester, 'nav-tasks');
    await tap(tester, 'add-task-today');
    expect(find.text('想法，接住了。'), findsOneWidget);
    await tap(tester, 'nav-today');
    await tap(tester, 'nav-capture');
    expect(find.text('想法，接住了。'), findsOneWidget);
  });

  testWidgets(
    'blank generation is disabled and record again starts a fresh thought',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        IdeaCaptureApp(
          captureAudioFactory: fakeAudio,
          extractionFactory: fakeExtraction,
          transcriptionFactory: fakeTranscription,
        ),
      );
      await tap(tester, 'nav-capture');
      await tap(tester, 'capture-control');
      await tester.enterText(key('capture-text'), '  ');
      await tap(tester, 'capture-control');
      expect(find.text('想法，接住了。'), findsOneWidget);
      expect(
        tester.widget<PixelButton>(key('capture-generate')).onPressed,
        isNull,
      );
      await tester.enterText(key('capture-text'), '重新记录前的文字');
      await tester.pump();
      expect(
        tester.widget<PixelButton>(key('capture-generate')).onPressed,
        isNotNull,
      );
      await tap(tester, 'capture-control');
      expect(find.text('我在听。'), findsOneWidget);
      expect(
        tester.widget<TextField>(key('capture-text')).controller!.text,
        isEmpty,
      );
      await tap(tester, 'capture-control');
      expect(
        tester.widget<PixelButton>(key('capture-generate')).onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'edited input generates once, opens detail, and synchronizes Today and Tasks',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        IdeaCaptureApp(
          captureAudioFactory: fakeAudio,
          extractionFactory: fakeExtraction,
          transcriptionFactory: fakeTranscription,
        ),
      );
      await tap(tester, 'nav-capture');
      await tap(tester, 'capture-control');
      await tester.enterText(key('capture-text'), '原来的想法');
      await tap(tester, 'capture-control');
      await tester.enterText(key('capture-text'), ' 修改后的想法 ');
      final generate = tester
          .widget<PixelButton>(key('capture-generate'))
          .onPressed!;
      generate();
      generate();
      await tester.pumpAndSettle();
      expect(find.text('修改后的想法'), findsOneWidget);
      expect(find.text('根据你的语音整理'), findsNothing);
      expect(find.text('分类'), findsOneWidget);
      expect(find.text('开始时间'), findsNothing);
      expect(find.text('建议的第一步'), findsNothing);
      expect(key('nav-capture'), findsNothing);
      await tap(tester, 'detail-back');
      expect(find.text('有什么想法？'), findsOneWidget);
      expect(key('capture-text'), findsNothing);
      await tap(tester, 'nav-tasks');
      expect(find.text('1 项待办'), findsOneWidget);
      expect(find.text('修改后的想法'), findsOneWidget);
      await tap(tester, 'nav-today');
      expect(find.text('修改后的想法'), findsOneWidget);
      await tap(tester, 'today-capture');
      await tap(tester, 'capture-control');
      expect(
        tester.widget<TextField>(key('capture-text')).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets(
    'Capture scrolls with keyboard and large text and keeps input across tabs',
    (tester) async {
      phone(tester, const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        IdeaCaptureApp(
          captureAudioFactory: fakeAudio,
          extractionFactory: fakeExtraction,
          transcriptionFactory: fakeTranscription,
        ),
      );
      await tap(tester, 'nav-capture');
      await tap(tester, 'capture-control');
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.enterText(key('capture-text'), '窄屏输入内容');
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pump();
      await tap(tester, 'capture-control');
      await tap(tester, 'capture-generate');
      expect(find.text('窄屏输入内容'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
