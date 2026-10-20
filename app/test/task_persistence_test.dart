import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:idea_capture/data/mock_tasks.dart';
import 'package:idea_capture/data/task_storage.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/models/task_draft.dart';
import 'package:idea_capture/state/task_store.dart';

class MemoryStorage implements TaskStorage {
  String? value;
  int writes = 0;
  Completer<void>? firstWrite;

  @override
  Future<TaskSnapshot> read() async =>
      value == null ? TaskSnapshot(const []) : TaskSnapshot.decode(value!);

  @override
  Future<void> write(TaskSnapshot snapshot) async {
    writes++;
    if (writes == 1) await firstWrite?.future;
    value = snapshot.encode();
  }
}

void main() {
  test(
    'confirmed extraction saves all fields and order in one batch',
    () async {
      final storage = MemoryStorage();
      final store = await TaskStore.load(storage);
      final created = store.createExtractedTasks([
        const TaskDraft(title: '第一项', category: '生活'),
        TaskDraft(
          title: '第二项',
          description: '说明',
          category: '工作',
          horizon: TaskHorizon.recently,
          priority: TaskPriority.high,
          deadline: DateTime(2026, 10, 10),
        ),
      ]);
      await store.flush();
      expect(storage.writes, 1);
      final reopened = await TaskStore.load(storage);
      expect(
        reopened.tasks.map((task) => task.toJson()),
        created.map((task) => task.toJson()),
      );
      expect(reopened.tasks.last.id, isNot(reopened.tasks.first.id));
      store.dispose();
      reopened.dispose();
    },
  );
  test('snapshot preserves every field, nulls, completion, and order', () {
    final full = Task(
      id: 'full',
      title: '完整字段',
      horizon: TaskHorizon.later,
      importantToday: true,
      category: '生活',
      suggestedStart: '下周',
      duration: '20分钟',
      priority: TaskPriority.high,
      description: '描述',
      firstStep: '第一步',
      firstStepReason: '原因',
      deadline: DateTime.utc(2026, 10, 8, 12),
      source: TaskSource.manual,
      done: true,
    );
    const empty = Task(id: 'empty', title: '缺失字段');
    final before = TaskSnapshot([full, empty, ...mockTasks], nextTaskId: 19);
    final after = TaskSnapshot.decode(before.encode());
    expect(after.nextTaskId, 19);
    expect(
      after.tasks.map((task) => task.toJson()).toList(),
      before.tasks.map((task) => task.toJson()).toList(),
    );
    expect(after.tasks[1].source, isNull);
    expect(after.tasks[1].deadline, isNull);
  });

  test('create/edit/complete/restore/delete survive store restart', () async {
    final storage = MemoryStorage();
    final store = await TaskStore.load(storage);
    expect(store.tasks, isEmpty);
    expect(storage.writes, 0);
    final created = store.createVoiceTasks(['第一项', '第二项']);
    store.rename(created.first.id, '编辑后');
    store.toggle(created.first.id);
    await store.flush();
    store.dispose();

    final restored = await TaskStore.load(storage);
    expect(
      restored.tasks.map((task) => task.id),
      created.map((task) => task.id),
    );
    expect(restored.tasks.first.title, '编辑后');
    expect(restored.completed, isEmpty);
    expect(restored.latestPending?.id, created.first.id);
    restored.toggle(created.first.id);
    await restored.flush();
    restored.dispose();

    final recovered = await TaskStore.load(storage);
    expect(recovered.tasks.first.done, isFalse);
    recovered.delete(created.first.id);
    recovered.delete(created.last.id);
    await recovered.flush();
    recovered.dispose();

    final deleted = await TaskStore.load(storage);
    expect(deleted.tasks, isEmpty);
    expect(deleted.createVoiceTasks(['新任务']).single.id, 'capture-3');
    await deleted.flush();
    deleted.dispose();
  });

  test(
    'rapid changes queue immutable snapshots and undo wins after restart',
    () async {
      final storage = MemoryStorage()..firstWrite = Completer<void>();
      final store = await TaskStore.load(storage);
      final task = store.createVoiceTasks(['原文']).single;
      store.rename(task.id, '最终标题');
      store.toggle(task.id);
      store.toggle(task.id);
      await Future<void>.delayed(Duration.zero);
      expect(storage.writes, 1);
      storage.firstWrite!.complete();
      await store.flush();
      expect(storage.writes, 4);
      final reopened = await TaskStore.load(storage);
      expect(reopened.tasks.single.title, '最终标题');
      expect(reopened.tasks.single.done, isFalse);
      store.dispose();
      reopened.dispose();
    },
  );

  test('example-mode mutations do not touch normal stored tasks', () async {
    final storage = MemoryStorage();
    final normal = await TaskStore.load(storage);
    normal.createVoiceTasks(['正常数据']);
    await normal.flush();
    final saved = storage.value;
    final examples = TaskStore(mockTasks);
    examples.rename(mockTasks.first.id, '示例修改');
    examples.toggle(mockTasks.first.id);
    examples.delete(mockTasks.last.id);
    examples.createVoiceTasks(['示例新增']);
    await examples.flush();
    expect(storage.value, saved);
    expect((await storage.read()).tasks.single.title, '正常数据');
    normal.dispose();
    examples.dispose();
  });

  test(
    'invalid stored data is not overwritten with an empty snapshot',
    () async {
      final storage = MemoryStorage()..value = '{"version":99}';
      await expectLater(TaskStore.load(storage), throwsFormatException);
      expect(storage.value, '{"version":99}');
      expect(storage.writes, 0);
    },
  );
}
