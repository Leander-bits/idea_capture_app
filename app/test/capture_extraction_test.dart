import 'package:idea_capture/widgets/pixel/pixel_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/models/task_draft.dart';
import 'package:idea_capture/models/extraction_plan.dart';
import 'package:idea_capture/state/task_store.dart';

import 'fake_capture_audio.dart';
import 'fake_transcription.dart';
import 'fake_extraction.dart';

import 'package:idea_capture/services/task_extraction_service.dart';

Finder key(String value) => find.byKey(ValueKey(value));
Future<void> tap(WidgetTester tester, String value) async {
  await tester.ensureVisible(key(value));
  await tester.pumpAndSettle();
  await tester.tap(key(value));
  await tester.pumpAndSettle();
}

Future<void> ready(
  WidgetTester tester,
  TaskStore store,
  FakeExtractionService service,
) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    IdeaCaptureApp(
      taskStore: store,
      captureAudioFactory: fakeAudio,
      transcriptionFactory: fakeTranscription,
      extractionFactory: () => service,
    ),
  );
  await tap(tester, 'nav-capture');
  await tap(tester, 'capture-control');
  await tap(tester, 'capture-control');
  await tester.enterText(key('capture-text'), '今天买牛奶，再提交报告');
  await tester.pump();
}

void main() {
  testWidgets(
    'inferred priority alone requires confirmation without changing UI',
    (tester) async {
      final store = TaskStore([]);
      final service = FakeExtractionService()..automatic = false;
      await ready(tester, store, service);
      await tap(tester, 'capture-generate');
      service.requests.last.complete(
        const ExtractionPlan(
          tasks: [
            TaskDraft(
              title: '写代码',
              suggestedStart: '2026-10-11',
              prioritySuggested: true,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('确认待办'), findsOneWidget);
      expect(store.tasks, isEmpty);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(store.tasks, isEmpty);
    },
  );

  testWidgets(
    'one suggested arrangement requires confirmation and cancel saves nothing',
    (tester) async {
      final store = TaskStore([]);
      final service = FakeExtractionService()..automatic = false;
      await ready(tester, store, service);
      final draft = TaskDraft(
        title: '整理房间',
        suggestedStart: '2026-10-11T13:00+02:00',
        startSuggested: true,
        prioritySuggested: true,
      );
      await tap(tester, 'capture-generate');
      service.requests.last.complete(ExtractionPlan(tasks: [draft]));
      await tester.pumpAndSettle();
      expect(find.text('确认待办'), findsOneWidget);
      expect(find.textContaining('建议开始'), findsOneWidget);
      expect(store.tasks, isEmpty);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(store.tasks, isEmpty);
      await tap(tester, 'capture-generate');
      service.requests.last.complete(ExtractionPlan(tasks: [draft]));
      await tester.pumpAndSettle();
      await tap(tester, 'confirm-save-tasks');
      expect(key('detail-scroll'), findsOneWidget);
      expect(find.text('开始时间（建议）'), findsOneWidget);
      expect(store.tasks.single.startSuggested, isTrue);
      final restored = Task.fromJson(store.tasks.single.toJson());
      expect(restored.startSuggested, isTrue);
      expect(restored.prioritySuggested, isTrue);
      expect(
        restored
            .copyWith(suggestedStart: '2026-10-12', updateSuggestedStart: true)
            .startSuggested,
        isFalse,
      );
      expect(
        restored
            .copyWith(suggestedStart: null, updateSuggestedStart: true)
            .startSuggested,
        isFalse,
      );
    },
  );

  testWidgets(
    'failure and empty results retain text; double requests do not create twice',
    (tester) async {
      final store = TaskStore([]);
      final service = FakeExtractionService()..automatic = false;
      await ready(tester, store, service);
      final generate = tester
          .widget<PixelButton>(key('capture-generate'))
          .onPressed!;
      generate();
      generate();
      await tester.pumpAndSettle();
      expect(service.inputs, ['今天买牛奶，再提交报告']);
      service.requests.last.completeError(
        const TaskExtractionException('模型返回的任务未通过校验，文字和录音已保留，未保存任何待办，请重试。'),
      );
      await tester.pumpAndSettle();
      expect(find.text('重试生成'), findsOneWidget);
      expect(find.text('模型返回的任务未通过校验，文字和录音已保留，未保存任何待办，请重试。'), findsOneWidget);
      expect(store.tasks, isEmpty);
      expect(
        tester.widget<TextField>(key('capture-text')).controller!.text,
        '今天买牛奶，再提交报告',
      );
      expect(key('capture-playback'), findsOneWidget);
      await tap(tester, 'capture-generate');
      service.requests.last.complete(const ExtractionPlan());
      await tester.pumpAndSettle();
      expect(find.text('未发现待办，可以修改文字后重试。'), findsOneWidget);
      expect(store.tasks, isEmpty);
    },
  );

  testWidgets(
    'multiple tasks are saved only after confirmation with all existing fields',
    (tester) async {
      final store = TaskStore([], clock: () => DateTime(2026, 10, 8, 12));
      final service = FakeExtractionService()..automatic = false;
      await ready(tester, store, service);
      final drafts = [
        const TaskDraft(title: '买牛奶', category: '生活'),
        TaskDraft(
          title: '提交报告',
          description: '给经理',
          horizon: TaskHorizon.recently,
          priority: TaskPriority.high,
          deadline: DateTime(2026, 10, 10),
        ),
      ];
      await tap(tester, 'capture-generate');
      service.requests.last.complete(ExtractionPlan(tasks: drafts));
      await tester.pumpAndSettle();
      expect(find.text('确认待办'), findsOneWidget);
      expect(store.tasks, isEmpty);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(store.tasks, isEmpty);
      await tap(tester, 'capture-generate');
      service.requests.last.complete(ExtractionPlan(tasks: drafts));
      await tester.pumpAndSettle();
      final save = tester
          .widget<PixelButton>(key('confirm-save-tasks'))
          .onPressed!;
      save();
      save();
      await tester.pumpAndSettle();
      expect(store.tasks.length, 2);
      expect(store.tasks[1].horizon, TaskHorizon.recently);
      expect(store.tasks[1].deadline, DateTime(2026, 10, 10));
      expect(store.tasks[1].description, '给经理');
      expect(store.tasks[1].priority, TaskPriority.high);
      expect(
        store.tasks.every((task) => task.source == TaskSource.voice),
        isTrue,
      );
      expect(key('capture-text'), findsNothing);
      await tap(tester, 'nav-tasks');
      expect(find.text('买牛奶'), findsOneWidget);
      await tap(tester, 'segment-recently');
      expect(find.text('提交报告'), findsOneWidget);
    },
  );

  testWidgets('editing while extracting discards old result', (tester) async {
    final store = TaskStore([]);
    final service = FakeExtractionService()..automatic = false;
    await ready(tester, store, service);
    await tap(tester, 'capture-generate');
    await tester.enterText(key('capture-text'), '新的内容');
    service.requests.last.complete(
      const ExtractionPlan(tasks: [TaskDraft(title: '旧内容')]),
    );
    await tester.pumpAndSettle();
    expect(store.tasks, isEmpty);
    expect(find.text('文字已修改，请重新生成。'), findsOneWidget);
    expect(
      tester.widget<TextField>(key('capture-text')).controller!.text,
      '新的内容',
    );
  });
}
