import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/data/mock_tasks.dart';
import 'package:idea_capture/state/task_store.dart';

void main() {
  testWidgets('completion grace period and restoration preserve task order', (
    tester,
  ) async {
    final store = TaskStore(mockTasks);
    addTearDown(store.dispose);
    final originalIds = store.tasks.map((task) => task.id).toList();
    store.toggle('dentist');
    expect(store.tasks[1].done, isTrue);
    expect(store.completed, isEmpty);
    expect(store.latestPending?.id, 'dentist');
    await tester.pump(const Duration(milliseconds: 5999));
    expect(store.completed, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(store.completed.single.id, 'dentist');
    expect(store.latestPending, isNull);
    store.toggle('dentist');
    expect(store.completed, isEmpty);
    expect(store.tasks[1].done, isFalse);
    expect(store.tasks.map((task) => task.id), originalIds);
  });

  testWidgets(
    'undo cancels timer and simultaneous completions are independent',
    (tester) async {
      final store = TaskStore(mockTasks);
      addTearDown(store.dispose);
      store.toggle('website');
      await tester.pump(const Duration(seconds: 2));
      store.toggle('dentist');
      expect(store.latestPending?.id, 'dentist');
      store.toggle('dentist');
      expect(store.latestPending?.id, 'website');
      await tester.pump(const Duration(seconds: 4));
      expect(store.completed.map((task) => task.id), ['website']);
      expect(store.tasks[1].done, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(store.completed.map((task) => task.id), ['website']);
    },
  );
}
