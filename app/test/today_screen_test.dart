import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/app.dart';
import 'package:idea_capture/data/mock_tasks.dart';
import 'package:idea_capture/models/task.dart';

import 'reveal_today.dart';

void main() {
  testWidgets('scrolled completion keeps undo visible outside task viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      IdeaCaptureApp(
        initialTasks: [
          for (var i = 0; i < 15; i++) Task(id: 'scroll-$i', title: '滚动任务 $i'),
        ],
      ),
    );
    final target = find.byKey(const ValueKey('toggle-scroll-10'));
    await revealToday(tester, target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    final undo = find.byKey(const ValueKey('undo-completion'));
    expect(undo.hitTestable(), findsOneWidget);
    final listBottom = tester.getRect(find.byType(ListView)).bottom;
    expect(tester.getRect(undo).top, greaterThanOrEqualTo(listBottom));
    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(find.text('撤销'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('complete, undo, archive, expand, and restore from Today', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
    expect(find.text('5 项待办'), findsOneWidget);
    await revealToday(tester, find.byKey(const ValueKey('toggle-dentist')));
    await tester.tap(find.byKey(const ValueKey('toggle-dentist')));
    await tester.pump();
    expect(find.text('4 项待办'), findsOneWidget);
    expect(find.text('已完成：预约牙齿检查'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('undo-completion')));
    await tester.pump();
    expect(find.text('5 项待办'), findsOneWidget);
    await revealToday(tester, find.byKey(const ValueKey('toggle-dentist')));
    await tester.tap(find.byKey(const ValueKey('toggle-dentist')));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('撤销'), findsNothing);
    expect(find.text('预约牙齿检查'), findsNothing);
    final header = find.byKey(const ValueKey('completed-section-toggle'));
    await revealToday(tester, header);
    await tester.tap(header);
    await tester.pump();
    final restore = find.byKey(const ValueKey('toggle-dentist'));
    await revealToday(tester, restore);
    await tester.tap(restore);
    await tester.pump();
    expect(find.text('已完成 · 1'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('5 项待办'), findsOneWidget);
    expect(find.text('预约牙齿检查'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('task body is separate from completion control', (tester) async {
    await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
    await revealToday(tester, find.byKey(const ValueKey('open-website')));
    await tester.tap(find.byKey(const ValueKey('open-website')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detail-scroll')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-today')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('detail-back')));
    await tester.pumpAndSettle();
    expect(find.text('5 项待办'), findsOneWidget);
    expect(find.text('撤销'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'narrow viewport and enlarged Chinese text scroll without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const IdeaCaptureApp(initialTasks: mockTasks));
      await revealToday(tester, find.byKey(const ValueKey('toggle-website')));
      await tester.tap(find.byKey(const ValueKey('toggle-website')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 6));
      final header = find.byKey(const ValueKey('completed-section-toggle'));
      await tester.scrollUntilVisible(header, 200);
      await tester.tap(header);
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
