import 'package:idea_capture/widgets/pixel/pixel_components.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/data/task_storage.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/models/task_draft.dart';
import 'package:idea_capture/models/extraction_plan.dart';
import 'package:idea_capture/state/task_store.dart';

import 'reveal_today.dart';
import 'fake_capture_audio.dart';
import 'fake_transcription.dart';
import 'fake_extraction.dart';

class MemoryStorage implements TaskStorage {
  String? value;
  int writes = 0;
  @override
  Future<TaskSnapshot> read() async =>
      value == null ? TaskSnapshot([]) : TaskSnapshot.decode(value!);
  @override
  Future<void> write(TaskSnapshot snapshot) async {
    value = snapshot.encode();
    writes++;
  }
}

Finder key(String name) => find.byKey(ValueKey(name));
Future<void> tap(WidgetTester tester, String name) async {
  if (name == 'detail-edit-bottom') {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      key(name),
      300,
      scrollable: find
          .descendant(
            of: key('detail-scroll'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  if (name.startsWith('open-') &&
      find.byKey(const PageStorageKey('today-scroll')).evaluate().isNotEmpty) {
    await revealToday(tester, key(name));
  } else {
    await tester.ensureVisible(key(name));
  }
  await tester.pumpAndSettle();
  await tester.tap(key(name));
  await tester.pumpAndSettle();
}

Future<void> capture(
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
      extractionFactory: () => service,
      captureAudioFactory: fakeAudio,
      transcriptionFactory: fakeTranscription,
    ),
  );
  await tap(tester, 'nav-capture');
  await tap(tester, 'capture-control');
  await tap(tester, 'capture-control');
  await tester.enterText(key('capture-text'), '不用买牛奶了，明天只买鸡蛋');
  await tester.pump();
}

const eggs = TaskDraft(
  title: '买鸡蛋',
  suggestedStart: '2026-10-09',
  horizon: TaskHorizon.recently,
);

void main() {
  test('v1 migrates priority/category and preserves the existing planned-time field', () {
    final old = TaskSnapshot.decode(
      jsonEncode({
        'version': 1,
        'nextTaskId': 7,
        'tasks': [
          {
            ...const Task(
              id: 'old',
              title: '晚上跑步',
              suggestedStart: '17:00',
            ).toJson(),
            'priority': '普通',
            'category': '健康',
          },
        ],
      }),
    );
    expect(old.tasks.single.priority, TaskPriority.medium);
    expect(old.tasks.single.priority.label, '中优先级');
    expect(old.tasks.single.category, '健康');
    expect(old.tasks.single.suggestedStart, '17:00');
    final encoded = jsonDecode(old.encode()) as Map<String, dynamic>;
    expect(encoded['version'], TaskSnapshot.version);
    expect(encoded['tasks'][0]['priority'], 'medium');
    expect((encoded['tasks'][0] as Map).containsKey('startTime'), isFalse);
  });

  test('date and explicit midnight precision persist; clearing start leaves deadline intact', () async {
    final storage = MemoryStorage();
    final store = TaskStore([], storage: storage);
    final task = store.createExtractedTasks([
      TaskDraft(
        title: '提交申请',
        category: '工作',
        priority: TaskPriority.high,
        suggestedStart: '2026-10-09',
        deadline: DateTime(2026, 10, 10, 17),
      ),
    ]).single;
    expect(startLabel(task.suggestedStart!), '2026年10月09日');
    store.editDetail(task.id, task.title, '2026-10-09T00:00');
    await store.flush();
    final restored = await TaskStore.load(storage);
    expect(
      startLabel(restored.tasks.single.suggestedStart!),
      '2026年10月09日 00:00',
    );
    expect(restored.tasks.single.deadline, DateTime(2026, 10, 10, 17));
    restored.editDetail(task.id, task.title, null);
    await restored.flush();
    final cleared = await TaskStore.load(storage);
    expect(cleared.tasks.single.suggestedStart, isNull);
    expect(cleared.tasks.single.deadline, DateTime(2026, 10, 10, 17));
    store.dispose();
    restored.dispose();
    cleared.dispose();
  });

  test(
    'stale or completed cancellation candidates reject the entire batch',
    () {
      const milk = Task(id: 'milk', title: '买牛奶');
      final store = TaskStore([milk]);
      addTearDown(store.dispose);
      store.rename('milk', '买鲜牛奶');
      expect(
        () => store.applyExtraction(
          [eggs],
          deleteIds: ['milk'],
          expectedTasks: [milk],
        ),
        throwsStateError,
      );
      expect(store.tasks.length, 1);
      final current = store.tasks.single;
      store.toggle('milk');
      expect(
        () => store.applyExtraction(
          [eggs],
          deleteIds: ['milk'],
          expectedTasks: [current],
        ),
        throwsStateError,
      );
      expect(store.tasks.length, 1);
    },
  );

  testWidgets(
    'cancelling proposal changes nothing; confirmation deletes ID and saves additions once',
    (tester) async {
      const milk = Task(id: 'milk', title: '买牛奶');
      const done = Task(id: 'done', title: '买牛奶', done: true);
      final storage = MemoryStorage();
      final store = TaskStore([milk, done], storage: storage);
      final service = FakeExtractionService()..automatic = false;
      await capture(tester, store, service);
      const plan = ExtractionPlan(
        tasks: [eggs],
        cancellations: [
          TaskCancellation(target: '买牛奶', candidateIds: ['milk']),
        ],
      );
      await tap(tester, 'capture-generate');
      expect(service.existing.single.map((task) => task.id), ['milk']);
      service.requests.last.complete(plan);
      await tester.pumpAndSettle();
      expect(find.text('拟删除'), findsOneWidget);
      expect(find.text('拟新增'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(store.tasks.map((task) => task.id), ['milk', 'done']);
      expect(storage.writes, 0);
      expect(
        tester.widget<TextField>(key('capture-text')).controller!.text,
        '不用买牛奶了，明天只买鸡蛋',
      );
      await tap(tester, 'capture-generate');
      service.requests.last.complete(plan);
      await tester.pumpAndSettle();
      final confirm = tester
          .widget<PixelButton>(key('confirm-save-tasks'))
          .onPressed!;
      confirm();
      confirm();
      await tester.pumpAndSettle();
      await store.flush();
      expect(storage.writes, 1);
      expect(store.taskById('milk'), isNull);
      expect(store.taskById('done'), isNotNull);
      expect(store.tasks.last.title, '买鸡蛋');
      final restored = await TaskStore.load(storage);
      expect(
        restored.tasks.map((task) => task.id),
        store.tasks.map((task) => task.id),
      );
      restored.dispose();
    },
  );

  testWidgets('ambiguous deletion requires explicit user selection', (
    tester,
  ) async {
    final store = TaskStore(const [
      Task(id: 'a', title: '买牛奶'),
      Task(id: 'b', title: '买牛奶', horizon: TaskHorizon.later),
    ]);
    final service = FakeExtractionService()..automatic = false;
    await capture(tester, store, service);
    await tap(tester, 'capture-generate');
    service.requests.last.complete(
      const ExtractionPlan(
        tasks: [eggs],
        cancellations: [
          TaskCancellation(target: '买牛奶', candidateIds: ['a', 'b']),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<PixelButton>(key('confirm-save-tasks')).onPressed,
      isNull,
    );
    await tap(tester, 'choose-delete-0');
    await tester.tap(find.text('买牛奶 · 以后').last);
    await tester.pumpAndSettle();
    await tap(tester, 'confirm-save-tasks');
    expect(store.taskById('a'), isNotNull);
    expect(store.taskById('b'), isNull);
    expect(store.tasks.last.title, '买鸡蛋');
  });

  testWidgets(
    'both detail edit entries edit start with precision and optional clearing',
    (tester) async {
      final store = TaskStore([
        Task(
          id: 'task',
          title: '申请',
          category: '工作',
          priority: TaskPriority.high,
          suggestedStart: '2026-10-09',
          deadline: DateTime(2026, 10, 10),
        ),
      ], clock: () => DateTime(2026, 10, 8, 12));
      await tester.pumpWidget(IdeaCaptureApp(taskStore: store));
      await tap(tester, 'nav-tasks');
      await tap(tester, 'segment-recently');
      await tap(tester, 'open-task');
      expect(find.text('高优先级'), findsOneWidget);
      expect(find.text('2026年10月09日'), findsOneWidget);
      await tap(tester, 'detail-edit-top');
      await tester.enterText(key('detail-start-input'), '2026-02-30');
      await tap(tester, 'detail-edit-bottom');
      expect(find.text('开始和截止时间请输入有效年月日，可加时分'), findsOneWidget);
      expect(store.tasks.single.suggestedStart, '2026-10-09');
      await tester.enterText(key('detail-start-input'), '2026-10-09 00:00');
      await tap(tester, 'detail-edit-bottom');
      expect(find.text('2026年10月09日 00:00'), findsOneWidget);
      await tap(tester, 'detail-edit-bottom');
      await tester.enterText(key('detail-start-input'), '');
      await tap(tester, 'detail-edit-top');
      expect(store.tasks.single.suggestedStart, isNull);
      expect(store.tasks.single.deadline, DateTime(2026, 10, 10));
    },
  );
}
