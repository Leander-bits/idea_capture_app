import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/data/task_storage.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/models/task_draft.dart';
import 'package:idea_capture/state/task_store.dart';

import 'reveal_today.dart';

void main() {
  test('device calendar grouping uses start first, +3/+4 boundary and manual override', () {
    var now = DateTime(2026, 10, 8, 23, 59);
    final store = TaskStore([
      const Task(
        id: 'past',
        title: '过去',
        suggestedStart: '2026-10-07',
        horizon: TaskHorizon.later,
      ),
      const Task(id: 'today', title: '今天', suggestedStart: '2026-10-08'),
      const Task(id: 'three', title: '三天后', suggestedStart: '2026-10-11'),
      const Task(id: 'four', title: '四天后', suggestedStart: '2026-10-12'),
      Task(
        id: 'start',
        title: '开始优先',
        suggestedStart: '2026-10-12',
        deadline: DateTime(2026, 10, 8),
      ),
      Task(id: 'end', title: '仅截止', deadline: DateTime(2026, 10, 9)),
      const Task(id: 'none', title: '无日期', horizon: TaskHorizon.later),
      const Task(
        id: 'manual',
        title: '手动',
        suggestedStart: '2026-10-08',
        horizon: TaskHorizon.later,
        manualHorizon: true,
      ),
      const Task(
        id: 'done',
        title: '已完成',
        suggestedStart: '2026-10-08',
        horizon: TaskHorizon.later,
        done: true,
      ),
    ], clock: () => now);
    addTearDown(store.dispose);
    expect(store.tasks.map((task) => task.horizon), [
      TaskHorizon.today,
      TaskHorizon.today,
      TaskHorizon.recently,
      TaskHorizon.later,
      TaskHorizon.later,
      TaskHorizon.recently,
      TaskHorizon.later,
      TaskHorizon.later,
      TaskHorizon.later,
    ]);
    now = DateTime(2026, 10, 9);
    store.refreshDates();
    expect(store.taskById('four')!.horizon, TaskHorizon.recently);
    expect(store.taskById('end')!.horizon, TaskHorizon.today);
    expect(store.taskById('manual')!.horizon, TaskHorizon.later);
    expect(store.taskById('done')!.horizon, TaskHorizon.later);
    store.editDetail(
      'manual',
      '手动',
      '2026-10-08',
      updateAll: true,
      manualHorizon: false,
    );
    expect(store.taskById('manual')!.horizon, TaskHorizon.today);
  });

  test(
    'deadline date/period expires after day ends; start never means overdue',
    () {
      final date = Task(
        id: 'date',
        title: '截止日',
        deadline: DateTime(2026, 10, 8),
        deadlineDateOnly: true,
        deadlinePeriod: '上午',
      );
      expect(date.isOverdue(DateTime(2026, 10, 8, 23, 59, 59)), isFalse);
      expect(date.isOverdue(DateTime(2026, 10, 9)), isTrue);
      final midnight = Task(
        id: 'clock',
        title: '零点',
        deadline: DateTime(2026, 10, 8),
      );
      expect(midnight.isOverdue(DateTime(2026, 10, 8, 0, 1)), isTrue);
      expect(
        date.withCompletion(true).isOverdue(DateTime(2026, 10, 9)),
        isFalse,
      );
      expect(
        const Task(
          id: 'start',
          title: '仅开始',
          suggestedStart: '2026-10-07',
        ).isOverdue(DateTime(2026, 10, 9)),
        isFalse,
      );
    },
  );

  test('three precision levels, fields and advice survive storage; v2 remains readable', () {
    final draft = TaskDraft.fromJson({
      'title': '买鸡蛋',
      'description': null,
      'category': '生活',
      'priority': 'medium',
      'horizon': 'today',
      'suggestedStart': '2026-10-08',
      'startPeriod': '晚上',
      'deadline': '2026-10-09T00:00+02:00',
      'deadlinePeriod': null,
      'firstStep': '先确认鸡蛋数量',
      'firstStepReason': '明确数量便于购买',
    });
    final restored = TaskSnapshot.decode(
      TaskSnapshot([draft.toTask('egg')]).encode(),
    ).tasks.single;
    expect(
      startLabel(restored.suggestedStart!, restored.startPeriod),
      '2026年10月08日 晚上',
    );
    expect(startLabel('2026-10-08'), '2026年10月08日');
    expect(
      startLabel(minuteValue(DateTime(2026, 10, 8, 15, 30))),
      '2026年10月08日 15:30',
    );
    expect(restored.deadlineDateOnly, isFalse);
    expect(restored.firstStep, '先确认鸡蛋数量');
    expect(restored.firstStepReason, '明确数量便于购买');
    final legacy = restored.toJson()
      ..remove('deadlineDateOnly')
      ..remove('startPeriod')
      ..remove('manualHorizon');
    legacy['deadline'] = '2026-10-09T00:00:00.000';
    final migrated = TaskSnapshot.decode(
      jsonEncode({
        'version': 2,
        'nextTaskId': 0,
        'tasks': [legacy],
      }),
    ).tasks.single;
    expect(migrated.deadlineDateOnly, isTrue);
    expect(migrated.startPeriod, isNull);
  });

  testWidgets(
    'midnight timer and foreground update without extraction; first step remains read only',
    (tester) async {
      var now = DateTime(2026, 10, 8, 23, 59, 59);
      final store = TaskStore(const [
        Task(
          id: 'egg',
          title: '买鸡蛋',
          suggestedStart: '2026-10-09',
          startPeriod: '晚上',
          firstStep: '先确认鸡蛋数量',
          firstStepReason: '明确数量便于购买',
        ),
      ], clock: () => now);
      await tester.pumpWidget(IdeaCaptureApp(taskStore: store));
      now = DateTime(2026, 10, 9);
      await tester.pump(const Duration(seconds: 1));
      expect(store.tasks.single.horizon, TaskHorizon.today);
      await revealToday(tester, find.byKey(const ValueKey('open-egg')));
      await tester.tap(find.byKey(const ValueKey('open-egg')));
      await tester.pumpAndSettle();
      expect(find.text('2026年10月09日 晚上'), findsOneWidget);
      expect(find.text('先确认鸡蛋数量'), findsOneWidget);
      expect(find.text('明确数量便于购买'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('detail-edit-top')));
      await tester.pumpAndSettle();
      final scroll = find.byKey(const ValueKey('detail-scroll'));
      await tester.drag(scroll, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('detail-step-input')), findsNothing);
      expect(find.byKey(const ValueKey('detail-reason-input')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('detail-edit-top')));
      await tester.pumpAndSettle();
      expect(store.tasks.single.firstStep, '先确认鸡蛋数量');
      final future = store.createExtractedTasks(const [
        TaskDraft(title: '未来任务', suggestedStart: '2026-10-13'),
      ]).single;
      expect(future.horizon, TaskHorizon.later);
      now = DateTime(2026, 10, 13);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(store.taskById(future.id)!.horizon, TaskHorizon.today);
      expect(store.taskById('egg')!.horizon, TaskHorizon.today);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('editing and clearing dates/periods/advice preserves the independent fields and manual group', () {
    final store = TaskStore(const [
      Task(
        id: 'task',
        title: '买鸡蛋',
        suggestedStart: '2026-10-08',
        startPeriod: '晚上',
        firstStep: '先确认数量',
        firstStepReason: '方便购买',
      ),
    ], clock: () => DateTime(2026, 10, 8));
    addTearDown(store.dispose);
    store.editDetail(
      'task',
      '买鸡蛋',
      '2026-10-08',
      startPeriod: '晚上',
      deadlineValue: '2026-10-09',
      deadlinePeriod: '下午',
      firstStep: '先确认数量',
      firstStepReason: '方便购买',
      horizon: TaskHorizon.later,
      manualHorizon: true,
      updateAll: true,
    );
    var task = TaskSnapshot.decode(TaskSnapshot(store.tasks).encode())
        .tasks
        .single;
    expect(task.startPeriod, '晚上');
    expect(task.deadlinePeriod, '下午');
    expect(task.firstStep, '先确认数量');
    expect(task.firstStepReason, '方便购买');
    expect(task.manualHorizon, isTrue);
    expect(task.horizon, TaskHorizon.later);
    store.editDetail(
      'task',
      '买鸡蛋',
      null,
      deadlineValue: '2026-10-09',
      deadlinePeriod: '下午',
      firstStep: '',
      firstStepReason: '',
      updateAll: true,
    );
    task = TaskSnapshot.decode(TaskSnapshot(store.tasks).encode()).tasks.single;
    expect(task.suggestedStart, isNull);
    expect(task.startPeriod, isNull);
    expect(task.deadlinePeriod, '下午');
    expect(task.deadlineDateOnly, isTrue);
    expect(task.firstStep, '先确认数量');
    expect(task.firstStepReason, '方便购买');
    store.editDetail('task', '买鸡蛋', '2026-10-10', updateAll: true);
    expect(store.tasks.single.deadline, isNull);
    expect(store.tasks.single.deadlinePeriod, isNull);
    expect(store.tasks.single.suggestedStart, '2026-10-10');
  });

  testWidgets(
    'period pickers and manual grouping edit through the shared detail UI',
    (tester) async {
      final store = TaskStore(const [
        Task(
          id: 'task',
          title: '买鸡蛋',
          suggestedStart: '2026-10-08',
          startPeriod: '晚上',
        ),
      ], clock: () => DateTime(2026, 10, 8));
      await tester.pumpWidget(IdeaCaptureApp(taskStore: store));
      await revealToday(tester, find.byKey(const ValueKey('open-task')));
      await tester.tap(find.byKey(const ValueKey('open-task')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('detail-edit-top')));
      await tester.pumpAndSettle();
      final deadline = find.byKey(const ValueKey('detail-deadline-input'));
      await tester.ensureVisible(deadline);
      await tester.enterText(deadline, '2026-10-09');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final period = find.byKey(const ValueKey('detail-deadline-period'));
      await tester.ensureVisible(period);
      await tester.pumpAndSettle();
      await tester.tap(period);
      await tester.pumpAndSettle();
      await tester.tap(find.text('下午').last);
      await tester.pumpAndSettle();
      final group = find.byKey(const ValueKey('detail-group-auto'));
      await tester.ensureVisible(group);
      await tester.pumpAndSettle();
      await tester.tap(group);
      await tester.pumpAndSettle();
      await tester.tap(find.text('手动：以后').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('detail-edit-top')));
      await tester.pumpAndSettle();
      var task = store.tasks.single;
      expect(task.startPeriod, '晚上');
      expect(task.deadlinePeriod, '下午');
      expect(task.deadlineDateOnly, isTrue);
      expect(task.manualHorizon, isTrue);
      expect(task.horizon, TaskHorizon.later);
      await tester.tap(find.byKey(const ValueKey('detail-edit-top')));
      await tester.pumpAndSettle();
      final manual = find.byKey(const ValueKey('detail-group-later'));
      await tester.ensureVisible(manual);
      await tester.pumpAndSettle();
      await tester.tap(manual);
      await tester.pumpAndSettle();
      await tester.tap(find.text('自动按日期分组').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('detail-edit-top')));
      await tester.pumpAndSettle();
      task = TaskSnapshot.decode(TaskSnapshot(store.tasks).encode())
          .tasks
          .single;
      expect(task.manualHorizon, isFalse);
      expect(task.horizon, TaskHorizon.today);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
