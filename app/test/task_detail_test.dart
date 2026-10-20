import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/data/mock_tasks.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/state/task_store.dart';

import 'reveal_today.dart';

Finder key(String value) => find.byKey(ValueKey(value));

Future<void> tap(WidgetTester tester, String value) async {
  if (value == 'detail-edit-bottom') {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      key(value),
      300,
      scrollable: find
          .descendant(
            of: key('detail-scroll'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  if (value.startsWith('open-') &&
      find.byKey(const PageStorageKey('today-scroll')).evaluate().isNotEmpty) {
    await revealToday(tester, key(value));
  } else {
    await tester.ensureVisible(key(value));
    await tester.pump();
  }
  await tester.tap(key(value));
  await tester.pumpAndSettle();
}

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('normal startup is empty and missing fields are omitted', (
    tester,
  ) async {
    await tester.pumpWidget(const IdeaCaptureApp());
    expect(find.text('整理网站改版思路'), findsNothing);
    await tap(tester, 'nav-tasks');
    expect(find.text('0 项待办'), findsOneWidget);
    await tester.pumpWidget(
      const IdeaCaptureApp(
        key: ValueKey('minimal'),
        initialTasks: [
          Task(id: 'minimal', title: '自己的任务', source: TaskSource.manual),
        ],
      ),
    );
    await tap(tester, 'open-minimal');
    expect(find.text('自己的任务'), findsOneWidget);
    expect(find.text('根据你的语音整理'), findsNothing);
    expect(find.text('分类'), findsOneWidget);
    expect(find.text('优先级'), findsOneWidget);
    expect(find.text('建议开始时间'), findsNothing);
    expect(find.text('建议的第一步'), findsNothing);
    expect(key('nav-today'), findsNothing);
    await tap(tester, 'detail-back');
    expect(key('nav-today'), findsOneWidget);
  });

  testWidgets(
    'both edit entries use the same flow and synchronize both lists',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
      await tap(tester, 'open-website');
      expect(find.text(mockTasks.first.description!), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
      await tap(tester, 'detail-edit-top');
      await tester.enterText(key('detail-title-input'), ' ');
      await tap(tester, 'detail-edit-bottom');
      expect(find.text('请输入任务标题'), findsOneWidget);
      await tester.enterText(key('detail-title-input'), ' 网站新标题 ');
      await tap(tester, 'detail-edit-bottom');
      expect(find.text('网站新标题'), findsOneWidget);
      expect(find.text(mockTasks.first.firstStep!), findsOneWidget);
      await tap(tester, 'detail-edit-bottom');
      await tester.enterText(key('detail-title-input'), '第二次修改');
      await tap(tester, 'detail-edit-top');
      await tap(tester, 'detail-back');
      expect(find.text('第二次修改'), findsOneWidget);
      await tap(tester, 'nav-tasks');
      expect(find.text('第二次修改'), findsOneWidget);
      expect(find.text('5 项待办'), findsOneWidget);
    },
  );

  testWidgets(
    'completion, deletion confirmation, source segment and scroll stay consistent',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
      await tap(tester, 'nav-tasks');
      await tap(tester, 'segment-recently');
      final list = find.byKey(const PageStorageKey('tasks-recently-scroll'));
      final originalPosition = tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      await tap(tester, 'open-dinners');
      expect(find.text('明天'), findsOneWidget);
      expect(find.text('建议的第一步'), findsNothing);
      await tap(tester, 'detail-toggle');
      await tap(tester, 'detail-back');
      expect(find.text('0 项待办'), findsOneWidget);
      expect(find.text('已完成：安排这周的晚餐'), findsOneWidget);
      await tap(tester, 'undo-completion');
      expect(find.text('1 项待办'), findsOneWidget);
      expect(
        tester
            .state<ScrollableState>(
              find.descendant(of: list, matching: find.byType(Scrollable)),
            )
            .position
            .pixels,
        originalPosition,
      );
      await tap(tester, 'open-dinners');
      await tap(tester, 'detail-delete');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(key('detail-scroll'), findsOneWidget);
      await tap(tester, 'detail-delete');
      await tap(tester, 'confirm-delete');
      expect(key('detail-scroll'), findsNothing);
      expect(find.text('0 项待办'), findsOneWidget);
      expect(list, findsOneWidget);
      expect(find.text('安排这周的晚餐'), findsNothing);
    },
  );

  testWidgets('Today delete returns to Today and removes the task from Tasks', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
    await tap(tester, 'open-website');
    await tap(tester, 'detail-delete');
    await tap(tester, 'confirm-delete');
    expect(find.text('今天待办'), findsOneWidget);
    expect(find.text('4 项待办'), findsOneWidget);
    await tap(tester, 'nav-tasks');
    expect(find.text('4 项待办'), findsOneWidget);
    expect(find.text('整理网站改版思路'), findsNothing);
  });

  testWidgets('detail scrolls with keyboard insets and enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
    await tap(tester, 'open-website');
    await tap(tester, 'detail-edit-top');
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.enterText(key('detail-title-input'), '窄屏标题');
    await tap(tester, 'detail-edit-top');
    tester.view.resetViewInsets();
    await tester.pump();
    await tester.scrollUntilVisible(
      key('detail-delete'),
      250,
      scrollable: find.byType(Scrollable),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'detail restores completion and returns to a scrolled source list',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
      await tap(tester, 'nav-tasks');
      final list = find.byKey(const PageStorageKey('tasks-today-scroll'));
      await tester.drag(list, const Offset(0, -200));
      await tester.pumpAndSettle();
      final offset = tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position
          .pixels;
      expect(offset, greaterThan(0));
      await tester.tap(key('open-reading'));
      await tester.pumpAndSettle();
      await tap(tester, 'detail-toggle');
      expect(find.text('已完成：读完书里的下一章'), findsOneWidget);
      await tap(tester, 'detail-toggle');
      expect(find.text('已完成：读完书里的下一章'), findsNothing);
      await tap(tester, 'detail-back');
      expect(
        tester
            .state<ScrollableState>(
              find.descendant(of: list, matching: find.byType(Scrollable)),
            )
            .position
            .pixels,
        offset,
      );
      expect(find.text('5 项待办'), findsOneWidget);
    },
  );

  testWidgets('rename retains fields and delete cancels pending completion', (
    tester,
  ) async {
    final store = TaskStore(mockTasks);
    addTearDown(store.dispose);
    store.toggle('website');
    expect(store.rename('website', ''), isFalse);
    expect(store.rename('website', '新标题'), isTrue);
    final task = store.taskById('website')!;
    expect(task.done, isTrue);
    expect(task.description, mockTasks.first.description);
    expect(task.firstStep, mockTasks.first.firstStep);
    expect(task.source, TaskSource.voice);
    store.delete('website');
    expect(store.latestPending, isNull);
    await tester.pump(const Duration(seconds: 6));
    expect(store.taskById('website'), isNull);
    expect(store.completed, isEmpty);
  });
}
