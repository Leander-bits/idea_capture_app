import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/data/mock_tasks.dart';

import 'reveal_today.dart';

Finder keyed(String key) => find.byKey(ValueKey(key));

Future<void> select(WidgetTester tester, String key) async {
  await tester.tap(keyed(key));
  await tester.pump();
}

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

ScrollPosition position(WidgetTester tester, Finder list) => tester
    .state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)),
    )
    .position;

void main() {
  testWidgets('completion and undo synchronize between Today and Tasks', (
    tester,
  ) async {
    viewport(tester, const Size(393, 852));
    await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
    await revealToday(tester, keyed('toggle-dentist'));
    await select(tester, 'toggle-dentist');
    await select(tester, 'nav-tasks');
    expect(find.text('4 项待办'), findsOneWidget);
    expect(find.text('已完成：预约牙齿检查'), findsOneWidget);
    await select(tester, 'undo-completion');
    expect(find.text('5 项待办'), findsOneWidget);
    await select(tester, 'nav-today');
    expect(find.text('5 项待办'), findsOneWidget);

    await select(tester, 'nav-tasks');
    await revealToday(tester, keyed('toggle-dentist'));
    await select(tester, 'toggle-dentist');
    await tester.pump(const Duration(seconds: 6));
    await tester.ensureVisible(keyed('completed-section-toggle'));
    await select(tester, 'completed-section-toggle');
    await revealToday(tester, keyed('toggle-dentist'));
    await select(tester, 'toggle-dentist');
    expect(find.text('5 项待办'), findsOneWidget);
    await select(tester, 'nav-today');
    expect(find.text('5 项待办'), findsOneWidget);
    expect(find.text('已完成 · 1'), findsNothing);
    expect(find.textContaining('分钟'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'segments, expansion, page scroll, and segment scroll survive navigation',
    (tester) async {
      viewport(tester, const Size(320, 568));
      await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
      await revealToday(tester, keyed('toggle-dentist'));
      await select(tester, 'toggle-dentist');
      await tester.pump(const Duration(seconds: 6));
      await select(tester, 'nav-tasks');
      final todayList = find.byKey(const PageStorageKey('tasks-today-scroll'));
      await tester.drag(todayList, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.ensureVisible(keyed('completed-section-toggle'));
      await select(tester, 'completed-section-toggle');
      final todayOffset = position(tester, todayList).pixels;
      expect(todayOffset, greaterThan(0));

      await select(tester, 'segment-recently');
      expect(find.text('安排这周的晚餐'), findsOneWidget);
      expect(find.text('1 项待办'), findsOneWidget);
      final recentList = find.byKey(
        const PageStorageKey('tasks-recently-scroll'),
      );
      await tester.drag(recentList, const Offset(0, -100));
      await tester.pumpAndSettle();
      final recentOffset = position(tester, recentList).pixels;
      expect(recentOffset, greaterThan(0));

      await select(tester, 'segment-later');
      expect(find.text('找一堂周末陶艺课'), findsOneWidget);
      expect(
        position(
          tester,
          find.byKey(const PageStorageKey('tasks-later-scroll')),
        ).pixels,
        0,
      );
      await select(tester, 'segment-today');
      expect(position(tester, todayList).pixels, todayOffset);
      await select(tester, 'segment-recently');
      expect(position(tester, recentList).pixels, recentOffset);
      expect(keyed('toggle-dentist'), findsOneWidget);

      await select(tester, 'nav-today');
      expect(keyed('toggle-dentist'), findsNothing);
      final homeList = find.byKey(const PageStorageKey('today-scroll'));
      await tester.ensureVisible(keyed('today-all-tasks'));
      await tester.pumpAndSettle();
      await tester.drag(homeList, const Offset(0, 180));
      await tester.pumpAndSettle();
      final homeOffset = position(tester, homeList).pixels;
      await select(tester, 'today-all-tasks');
      expect(recentList, findsOneWidget);
      expect(position(tester, recentList).pixels, recentOffset);
      expect(keyed('toggle-dentist'), findsOneWidget);
      await select(tester, 'nav-today');
      expect(position(tester, homeList).pixels, homeOffset);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Tasks supports large text and opens Capture from the add entry',
    (tester) async {
      viewport(tester, const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
      await select(tester, 'nav-tasks');
      await select(tester, 'segment-recently');
      await select(tester, 'toggle-dinners');
      expect(find.text('0 项待办'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('这里暂时没有待办。'), findsOneWidget);
      await tester.ensureVisible(keyed('completed-section-toggle'));
      await select(tester, 'completed-section-toggle');
      final addButton = tester.widget<TextButton>(keyed('add-task-recently'));
      expect(addButton.onPressed, isNotNull);
      await tester.tap(keyed('tasks-add'));
      await tester.pump();
      expect(find.text('灵感收集站'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
