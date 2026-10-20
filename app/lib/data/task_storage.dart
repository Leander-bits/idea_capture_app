import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../models/achievement.dart';

class TaskSnapshot {
  TaskSnapshot(
    Iterable<Task> tasks, {
    this.nextTaskId = 0,
    List<Achievement> achievements = const [],
    Set<String> contributedTaskIds = const {},
    Map<String, DateTime> pendingCompletions = const {},
  }) : tasks = List.unmodifiable(tasks),
       achievements = List.unmodifiable(achievements),
       contributedTaskIds = Set.unmodifiable({
         ...contributedTaskIds,
         ...achievements.map((item) => item.taskId),
       }),
       pendingCompletions = Map.unmodifiable(pendingCompletions);

  final List<Task> tasks;
  final int nextTaskId;
  final List<Achievement> achievements;
  final Set<String> contributedTaskIds;
  final Map<String, DateTime> pendingCompletions;

  static const version = 7;

  String encode() => jsonEncode({
    'version': version,
    'nextTaskId': nextTaskId,
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'achievements': achievements.map((item) => item.toJson()).toList(),
    'contributedTaskIds': contributedTaskIds.toList(),
    'pendingCompletions': pendingCompletions.map(
      (id, time) => MapEntry(id, time.toUtc().toIso8601String()),
    ),
  });

  factory TaskSnapshot.decode(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    if (![1, 2, 3, 4, 5, 6, version].contains(json['version'])) {
      throw const FormatException('Unsupported task storage version');
    }
    final tasks = (json['tasks'] as List<dynamic>)
        .map((task) => Task.fromJson(task as Map<String, dynamic>))
        .toList();
    if (tasks.map((task) => task.id).toSet().length != tasks.length) {
      throw const FormatException('Duplicate task IDs');
    }
    final nextTaskId = json['nextTaskId'] as int;
    if (nextTaskId < 0) {
      throw const FormatException('Invalid task ID counter');
    }
    return TaskSnapshot(
      tasks,
      nextTaskId: nextTaskId,
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList(),
      contributedTaskIds: (json['contributedTaskIds'] as List<dynamic>? ?? [])
          .cast<String>()
          .toSet(),
      pendingCompletions:
          (json['pendingCompletions'] as Map<String, dynamic>? ?? {}).map(
            (id, time) => MapEntry(id, DateTime.parse(time as String).toUtc()),
          ),
    );
  }
}

abstract interface class TaskStorage {
  Future<TaskSnapshot> read();
  Future<void> write(TaskSnapshot snapshot);
}

class PreferencesTaskStorage implements TaskStorage {
  PreferencesTaskStorage() : _preferences = SharedPreferencesAsync();

  static const key = 'idea_capture.tasks.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<TaskSnapshot> read() async {
    final value = await _preferences.getString(key);
    if (value == null) return TaskSnapshot(const []);
    final snapshot = TaskSnapshot.decode(value);
    if ((jsonDecode(value) as Map<String, dynamic>)['version'] !=
        TaskSnapshot.version) {
      await write(snapshot);
    }
    return snapshot;
  }

  @override
  Future<void> write(TaskSnapshot snapshot) =>
      _preferences.setString(key, snapshot.encode());
}
