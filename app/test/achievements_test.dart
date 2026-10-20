import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/data/task_storage.dart';
import 'package:idea_capture/models/achievement.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/state/task_store.dart';
import 'package:idea_capture/screens/achievements_screen.dart';
import 'package:idea_capture/theme/pixel_theme.dart';

class _Storage implements TaskStorage {
  String? value;
  @override
  Future<TaskSnapshot> read() async =>
      value == null ? TaskSnapshot([]) : TaskSnapshot.decode(value!);
  @override
  Future<void> write(TaskSnapshot snapshot) async {
    value = snapshot.encode();
  }
}

void main() {
  testWidgets('undo stays reachable during achievement particles', (
    tester,
  ) async {
    final store = TaskStore([const Task(id: 'code', title: '写代码')]);
    await tester.pumpWidget(IdeaCaptureApp(taskStore: store));
    await tester.tap(find.byKey(const ValueKey('toggle-code')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('undo-completion')));
    await tester.pump();
    expect(store.tasks.single.done, isFalse);
    await tester.pump(const Duration(seconds: 6));
    expect(store.achievements, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'activity matching precedes broad types and category-independent fallback',
    () {
      final examples = {
        '写代码': 'code',
        '做美食': 'cooking',
        '去旅游': 'travel',
        '游泳': 'swimming',
        '健身': 'fitness',
        '化妆拍照': 'photo',
        '出去吃好吃的': 'dining',
        '化妆': 'makeup',
        '打扫房间': 'life',
        '看电影': 'fun',
        '跑步': 'sport',
        '工作报告': 'work',
        '给朋友打电话': 'social',
      };
      for (final entry in examples.entries) {
        expect(
          matchAchievement(
            Task(id: entry.key, title: entry.key, category: '其他'),
          ).id,
          entry.value,
        );
      }
      expect(
        matchAchievement(const Task(id: 'x', title: '想法落地', category: '其他')).id,
        'general',
      );
      expect(
        matchAchievement(const Task(id: 'x', title: '旅行', category: '生活')).id,
        'travel',
      );
    },
  );

  testWidgets(
    'undo and delete within window award nothing; all groups contribute once',
    (tester) async {
      final store = TaskStore([
        for (final group in TaskHorizon.values)
          Task(id: group.name, title: '写代码 ${group.name}', horizon: group),
      ]);
      store.toggle('today');
      await tester.pump(const Duration(seconds: 5));
      expect(store.achievements, isEmpty);
      store.toggle('today');
      await tester.pump(const Duration(seconds: 2));
      expect(store.achievements, isEmpty);
      store.toggle('recently');
      store.delete('recently');
      await tester.pump(const Duration(seconds: 6));
      expect(store.achievements, isEmpty);
      store.toggle('today');
      store.toggle('later');
      await tester.pump(const Duration(seconds: 6));
      expect(store.achievements.length, 2);
      store.toggle('later');
      store.toggle('later');
      await tester.pump(const Duration(seconds: 6));
      expect(store.achievements.length, 2);
      store.dispose();
    },
  );

  testWidgets(
    'pending window survives reload, completed snapshots survive restore/delete/reload',
    (tester) async {
      var now = DateTime(2026, 10, 11, 12);
      final storage = _Storage();
      var store = TaskStore(
        const [
          Task(
            id: 'code',
            title: '写代码',
            description: '实际字段',
            firstStep: '打开编辑器',
            firstStepReason: '推进工作',
          ),
        ],
        storage: storage,
        clock: () => now,
      );
      store.toggle('code');
      await store.flush();
      now = now.add(const Duration(seconds: 2));
      store.dispose();
      store = await TaskStore.load(storage, clock: () => now);
      expect(store.latestPending!.id, 'code');
      await tester.pump(const Duration(seconds: 3));
      expect(store.achievements, isEmpty);
      now = now.add(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
      await store.flush();
      expect(store.achievements.length, 1);
      final earned = store.achievements.single;
      expect(earned.obtainedAt, now.toUtc());
      store.toggle('code');
      store.rename('code', '改过的标题');
      store.delete('code');
      await store.flush();
      store.dispose();
      store = await TaskStore.load(storage, clock: () => now);
      expect(store.tasks, isEmpty);
      expect(store.hasContributed('code'), isTrue);
      expect(store.achievements.single.snapshot.title, '写代码');
      expect(store.achievements.single.snapshot.description, '实际字段');
      expect(store.achievements.single.snapshot.firstStepReason, '推进工作');
      store.dispose();
    },
  );

  test('legacy completed tasks do not receive backfilled achievements; categories migrate exactly', () {
    const values = {
      '运动': '健康',
      '项目': '工作',
      '旅游': '生活',
      '社交': '生活',
      '未知': '其他',
      '健康': '健康',
    };
    for (final entry in values.entries) {
      expect(migrateCategory(entry.key, '旅游'), entry.value);
    }
    final old = TaskSnapshot.decode(
      jsonEncode({
        'version': 6,
        'nextTaskId': 0,
        'tasks': [const Task(id: 'old', title: '写代码', done: true).toJson()],
        'rewards': {
          '2026-10-10': {'opened': true},
        },
      }),
    );
    final store = TaskStore(old.tasks);
    expect(store.achievements, isEmpty);
    store.dispose();
  });

  test('priority order uses original creation order for ties, persisted through editing', () async {
    final storage = _Storage();
    final store = TaskStore(const [
      Task(id: 'low', title: '低', priority: TaskPriority.low),
      Task(id: 'high1', title: '高一', priority: TaskPriority.high),
      Task(id: 'medium', title: '中'),
      Task(id: 'high2', title: '高二', priority: TaskPriority.high),
    ], storage: storage);
    expect(store.pendingFor(TaskHorizon.today).map((task) => task.id), [
      'high1',
      'high2',
      'medium',
      'low',
    ]);
    store.editDetail(
      'low',
      '低',
      null,
      priority: TaskPriority.high,
      category: '健康',
    );
    await store.flush();
    expect(store.pendingFor(TaskHorizon.today).map((task) => task.id), [
      'low',
      'high1',
      'high2',
      'medium',
    ]);
    final decoded = TaskSnapshot.decode(storage.value!);
    expect(decoded.tasks.first.category, '健康');
    expect(decoded.tasks.first.priority, TaskPriority.high);
    store.dispose();
  });

  testWidgets(
    '320px achievement wall, history and edit controls do not overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final task = const Task(
        id: 'code',
        title: '写代码',
        suggestedStart: '2026-10-11',
        startPeriod: '晚上',
        firstStep: '打开编辑器',
        firstStepReason: '推进代码工作',
      );
      final store = TaskStore(
        [task],
        achievements: [
          Achievement(
            typeId: 'code',
            taskId: 'old',
            obtainedAt: DateTime.utc(2026, 10, 11),
            snapshot: task,
          ),
        ],
      );
      await tester.pumpWidget(IdeaCaptureApp(taskStore: store));
      await tester.tap(find.byKey(const ValueKey('today-achievements')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('achievement-type-code')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('achievement-history-old')));
      await tester.pumpAndSettle();
      expect(find.text('写代码'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      final editStore = TaskStore([task]);
      await tester.pumpWidget(IdeaCaptureApp(taskStore: editStore));
      await tester.tap(find.byKey(const ValueKey('open-code')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('detail-edit-top')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detail-step-input')), findsNothing);
      expect(
        find.byKey(const ValueKey('detail-category-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('detail-priority-input')),
        findsOneWidget,
      );
      Future<void> choose(String key, String value) async {
        final field = find.byKey(ValueKey(key));
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text(value).last);
        await tester.pumpAndSettle();
      }

      await choose('detail-category-input', '健康');
      await choose('detail-priority-input', '高优先级');
      final clear = find.byKey(const ValueKey('clear-start-time'));
      await tester.ensureVisible(clear);
      await tester.pumpAndSettle();
      await tester.tap(clear);
      await tester.pumpAndSettle();
      final period = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: find.byKey(const ValueKey('detail-start-period')),
          matching: find.byType(DropdownButton<String>),
        ),
      );
      expect(period.value, isNull);
      await tester.tap(find.byKey(const ValueKey('detail-edit-top')));
      await tester.pumpAndSettle();
      expect(editStore.tasks.single.category, '健康');
      expect(editStore.tasks.single.priority, TaskPriority.high);
      expect(editStore.tasks.single.suggestedStart, isNull);
      expect(editStore.tasks.single.startPeriod, isNull);
      expect(editStore.tasks.single.firstStep, '打开编辑器');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.dark,
          home: AchievementsScreen(store: TaskStore([])),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
