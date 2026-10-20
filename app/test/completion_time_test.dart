import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/data/task_storage.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/state/task_store.dart';

import 'reveal_today.dart';

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
  test(
    'complete, undo, restore and edits persist exact completion instant',
    () async {
      var clock = DateTime(2026, 10, 10, 12);
      final storage = _Storage();
      final store = TaskStore(
        [const Task(id: 't', title: '测试')],
        storage: storage,
        clock: () => clock,
      );
      expect(store.completedTodayCount, 0);
      store.toggle('t');
      expect(store.taskById('t')!.completedAt, clock.toUtc());
      expect(store.completedTodayCount, 1); // Counts during the undo window.
      store.rename('t', '改名');
      expect(store.taskById('t')!.completedAt, clock.toUtc());
      await store.flush();
      var reopened = await TaskStore.load(storage, clock: () => clock);
      expect(reopened.completedTodayCount, 1);
      expect(reopened.taskById('t')!.completedAt, clock.toUtc());
      reopened.toggle('t');
      expect(reopened.completedTodayCount, 0);
      expect(reopened.taskById('t')!.completedAt, isNull);
      await reopened.flush();
      reopened.dispose();
      reopened = await TaskStore.load(storage, clock: () => clock);
      expect(reopened.completedTodayCount, 0);
      expect(reopened.taskById('t')!.completedAt, isNull);
      clock = clock.add(const Duration(hours: 2));
      reopened.toggle('t');
      expect(reopened.taskById('t')!.completedAt, clock.toUtc());
      reopened.toggle('t'); // Undo also clears and saves the timestamp.
      await reopened.flush();
      reopened.dispose();
      reopened = await TaskStore.load(storage, clock: () => clock);
      expect(reopened.completedTodayCount, 0);
      expect(reopened.taskById('t')!.completedAt, isNull);
      reopened.dispose();
      store.dispose();
    },
  );

  test(
    'old completed tasks migrate without inventing completion time',
    () async {
      final storage = _Storage();
      final old = const Task(id: 'old', title: '旧任务', done: true).toJson()
        ..remove('completedAt');
      for (final version in [1, 2, 3]) {
        storage.value = jsonEncode({
          'version': version,
          'nextTaskId': 0,
          'tasks': [old],
        });
        final store = await TaskStore.load(
          storage,
          clock: () => DateTime(2026, 10, 10),
        );
        expect(store.tasks.single.done, isTrue);
        expect(store.tasks.single.completedAt, isNull);
        expect(store.completedTodayCount, 0);
        store.dispose();
      }
    },
  );

  test('local calendar day ignores horizon and excludes yesterday, future and unfinished', () {
    var clock = DateTime(2026, 10, 10, 23, 59);
    final store = TaskStore([
      Task(
        id: 'today',
        title: '今天完成',
        horizon: TaskHorizon.later,
        done: true,
        completedAt: DateTime(2026, 10, 10, 0, 5).toUtc(),
      ),
      Task(
        id: 'yesterday',
        title: '昨天完成',
        done: true,
        completedAt: DateTime(2026, 10, 9, 23, 59).toUtc(),
      ),
      Task(
        id: 'tomorrow',
        title: '以后完成',
        done: true,
        completedAt: DateTime(2026, 10, 11, 0, 5).toUtc(),
      ),
      Task(id: 'unfinished', title: '未完成', completedAt: clock.toUtc()),
      const Task(id: 'old', title: '未知完成时间', done: true),
    ], clock: () => clock);
    expect(store.completedTodayCount, 1);
    clock = DateTime(2026, 10, 11, 0, 6);
    store.refreshDates();
    expect(store.completedTodayCount, 1);
    store.toggle('tomorrow');
    expect(store.completedTodayCount, 0);
    store.dispose();
  });

  test('count has no three-task cap and updates after deletion', () {
    final store = TaskStore([
      for (var i = 0; i < 5; i++) Task(id: '$i', title: '$i'),
    ], clock: () => DateTime(2026, 10, 10, 12));
    for (var i = 0; i < 5; i++) {
      store.toggle('$i');
    }
    expect(store.completedTodayCount, 5);
    store.delete('4');
    expect(store.completedTodayCount, 4);
    store.dispose();
  });

  testWidgets(
    'empty Today has zero count, achievement entry and working Capture entry',
    (tester) async {
      await tester.pumpWidget(const IdeaCaptureApp());
      expect(find.text('今日已完成 0 项'), findsOneWidget);
      expect(find.byKey(const ValueKey('today-achievements')), findsOneWidget);
      expect(find.textContaining('预览'), findsNothing);
      await revealToday(
        tester,
        find.byKey(const ValueKey('today-empty-capture')),
      );
      await tester.tap(find.byKey(const ValueKey('today-empty-capture')));
      await tester.pump();
      expect(find.text('灵感收集站'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Today count follows completion, undo, archive and restore', (
    tester,
  ) async {
    final store = TaskStore([
      const Task(id: 't', title: '实际任务'),
    ], clock: () => DateTime(2026, 10, 10, 12));
    await tester.pumpWidget(IdeaCaptureApp(taskStore: store));
    expect(find.text('今日已完成 0 项'), findsOneWidget);
    await revealToday(tester, find.byKey(const ValueKey('toggle-t')));
    await tester.tap(find.byKey(const ValueKey('toggle-t')));
    await tester.pump();
    expect(find.text('今日已完成 1 项'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('undo-completion')));
    await tester.pump();
    expect(find.text('今日已完成 0 项'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toggle-t')));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('今日已完成 1 项'), findsOneWidget);
    await revealToday(
      tester,
      find.byKey(const ValueKey('completed-section-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('completed-section-toggle')));
    await tester.pump();
    await revealToday(tester, find.byKey(const ValueKey('toggle-t')));
    await tester.tap(find.byKey(const ValueKey('toggle-t')));
    await tester.pump();
    expect(find.text('今日已完成 0 项'), findsOneWidget);
    expect(store.taskById('t')!.completedAt, isNull);
    expect(find.byKey(const ValueKey('today-achievements')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
