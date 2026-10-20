import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> revealToday(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('today-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
  }
  await Scrollable.ensureVisible(tester.element(target), alignment: .2);
  await tester.pump();
}
