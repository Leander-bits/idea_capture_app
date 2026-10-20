import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../models/task_draft.dart';
import '../models/achievement.dart';
import '../data/task_storage.dart';

class TaskStore extends ChangeNotifier {
  TaskStore(
    List<Task> tasks, {
    TaskStorage? storage,
    int nextTaskId = 0,
    DateTime Function()? clock,
    bool scheduleUpdates = false,
    List<Achievement> achievements = const [],
    Set<String> contributedTaskIds = const {},
    Map<String, DateTime> pendingCompletions = const {},
  }) : this._(
         tasks,
         storage,
         nextTaskId,
         clock,
         scheduleUpdates,
         achievements,
         contributedTaskIds,
         pendingCompletions,
       );

  TaskStore._(
    List<Task> tasks,
    this._storage,
    this._nextTaskId,
    DateTime Function()? clock,
    bool scheduleUpdates,
    List<Achievement> achievements,
    Set<String> contributedTaskIds,
    Map<String, DateTime> pendingCompletions,
  ) : _tasks = List.of(tasks),
      _achievements = List.of(achievements),
      _contributedTaskIds = {
        ...contributedTaskIds,
        ...achievements.map((item) => item.taskId),
      },
      _pendingCompletions = Map.of(pendingCompletions),
      _clock = clock ?? DateTime.now {
    refreshDates();
    _restorePendingCompletions();
    if (scheduleUpdates) startDateUpdates();
  }

  static Future<TaskStore> load(
    TaskStorage storage, {
    DateTime Function()? clock,
  }) async {
    final snapshot = await storage.read();
    return TaskStore(
      snapshot.tasks,
      storage: storage,
      nextTaskId: snapshot.nextTaskId,
      clock: clock,
      achievements: snapshot.achievements,
      contributedTaskIds: snapshot.contributedTaskIds,
      pendingCompletions: snapshot.pendingCompletions,
    );
  }

  static const undoWindow = Duration(seconds: 6);
  final List<Task> _tasks;
  final DateTime Function() _clock;
  Timer? _dateTimer;
  final List<Achievement> _achievements;
  final Set<String> _contributedTaskIds;
  final Map<String, DateTime> _pendingCompletions;
  DateTime get now => _clock().toLocal();
  List<Achievement> get achievements => List.unmodifiable(_achievements);
  bool hasContributed(String id) => _contributedTaskIds.contains(id);

  void _restorePendingCompletions() {
    for (final entry in _pendingCompletions.entries.toList()) {
      final task = taskById(entry.key);
      if (task == null || !task.done) {
        _pendingCompletions.remove(entry.key);
        _save();
        continue;
      }
      final remaining = entry.value.add(undoWindow).difference(now.toUtc());
      if (remaining <= Duration.zero) {
        _finalizeCompletion(entry.key);
      } else {
        _pending[entry.key] = Timer(
          remaining,
          () => _finalizeCompletion(entry.key),
        );
      }
    }
  }

  void _finalizeCompletion(String id) {
    _pending.remove(id)?.cancel();
    _pendingCompletions.remove(id);
    final task = taskById(id);
    if (task != null && task.done && _contributedTaskIds.add(id)) {
      _achievements.add(
        Achievement(
          typeId: matchAchievement(task).id,
          taskId: id,
          obtainedAt: now.toUtc(),
          snapshot: task,
        ),
      );
    }
    _save();
    notifyListeners();
  }

  List<Task> pendingFor(TaskHorizon horizon) {
    final order = {for (var i = 0; i < _tasks.length; i++) _tasks[i].id: i};
    return _tasks
        .where((task) => task.horizon == horizon && !isArchived(task))
        .toList()
      ..sort((a, b) {
        final priority = a.priority.index.compareTo(b.priority.index);
        return priority != 0 ? priority : order[a.id]!.compareTo(order[b.id]!);
      });
  }

  Task _grouped(Task task) {
    if (task.done || task.manualHorizon) return task;
    final date =
        taskDate(task.suggestedStart) ??
        (task.deadline == null
            ? null
            : taskDate(dateValue(task.deadline!.toLocal())));
    if (date == null) return task;
    final today = now;
    // Calendar-day arithmetic stays correct across daylight-saving transitions.
    final days = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final horizon = days <= 0
        ? TaskHorizon.today
        : days <= 3
        ? TaskHorizon.recently
        : TaskHorizon.later;
    return horizon == task.horizon ? task : task.copyWith(horizon: horizon);
  }

  void refreshDates() {
    var changed = false;
    for (var i = 0; i < _tasks.length; i++) {
      final grouped = _grouped(_tasks[i]);
      changed |= !identical(grouped, _tasks[i]);
      _tasks[i] = grouped;
    }
    if (changed) _save();
    notifyListeners();
  }

  void startDateUpdates() {
    _dateTimer?.cancel();
    final current = now;
    final delay =
        const Duration(minutes: 1) -
        Duration(
          seconds: current.second,
          milliseconds: current.millisecond,
          microseconds: current.microsecond,
        );
    _dateTimer = Timer(delay, () {
      refreshDates();
      startDateUpdates();
    });
  }

  final Map<String, Timer> _pending = {};
  int _nextTaskId;
  final TaskStorage? _storage;
  Future<void> _saving = Future.value();
  Object? _saveError;

  // Capture each mutation and serialize writes so older saves cannot win a race.
  void _save() {
    final storage = _storage;
    if (storage == null) return;
    final snapshot = TaskSnapshot(
      _tasks,
      nextTaskId: _nextTaskId,
      achievements: _achievements,
      contributedTaskIds: _contributedTaskIds,
      pendingCompletions: _pendingCompletions,
    );
    _saving = _saving.then((_) async {
      try {
        await storage.write(snapshot);
        _saveError = null;
      } catch (error, stack) {
        _saveError = error;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'task persistence',
            context: ErrorDescription('while saving local tasks'),
          ),
        );
      }
    });
  }

  Future<void> flush() async {
    await _saving;
    if (_saveError case final error?) throw error;
  }

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get completed => List.unmodifiable(
    _tasks.where((task) => task.done && !_pending.containsKey(task.id)),
  );

  /// Count actual completions on the device's local calendar day, including undo-pending tasks.
  int get completedTodayCount {
    final today = now;
    return _tasks.where((task) {
      final date = task.completedAt?.toLocal();
      return task.done &&
          date != null &&
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).length;
  }

  Task? get latestPending {
    if (_pending.isEmpty) return null;
    final id = _pending.keys.last;
    return _tasks.firstWhere((task) => task.id == id);
  }

  bool isArchived(Task task) => task.done && !_pending.containsKey(task.id);

  List<Task> createVoiceTasks(Iterable<String> titles) {
    final created = <Task>[];
    for (final text in titles) {
      final title = text.trim();
      if (title.isEmpty) continue;
      String id;
      do {
        id = 'capture-${++_nextTaskId}';
      } while (_tasks.any((task) => task.id == id));
      final task = Task(id: id, title: title, source: TaskSource.voice);
      _tasks.add(task);
      created.add(task);
    }
    if (created.isNotEmpty) {
      _save();
      notifyListeners();
    }
    return List.unmodifiable(created);
  }

  List<Task> createExtractedTasks(Iterable<TaskDraft> drafts) {
    return applyExtraction(drafts);
  }

  List<Task> applyExtraction(
    Iterable<TaskDraft> drafts, {
    Iterable<String> deleteIds = const [],
    List<Task> expectedTasks = const [],
  }) {
    final removals = deleteIds.toSet();
    // Validate the complete proposal before touching either list or persistence.
    for (final id in removals) {
      final current = taskById(id);
      final expected = expectedTasks.where((task) => task.id == id).firstOrNull;
      if (current == null ||
          current.done ||
          expected == null ||
          !identical(current, expected)) {
        throw StateError('Cancellation candidate changed');
      }
    }
    final additions = drafts.toList();
    for (final draft in additions) {
      if (draft.title.trim().isEmpty ||
          !taskCategories.contains(draft.category)) {
        throw const FormatException('Invalid task draft');
      }
      if (draft.suggestedStart case final value?) validateStart(value);
    }
    final created = <Task>[];
    for (final draft in additions) {
      String id;
      do {
        id = 'capture-${++_nextTaskId}';
      } while (_tasks.any((task) => task.id == id));
      final task = _grouped(draft.toTask(id));
      _tasks.add(task);
      created.add(task);
    }
    for (final id in removals) {
      _pending.remove(id)?.cancel();
      _pendingCompletions.remove(id);
    }
    _tasks.removeWhere((task) => removals.contains(task.id));
    if (created.isNotEmpty || removals.isNotEmpty) {
      _save();
      notifyListeners();
    }
    return List.unmodifiable(created);
  }

  Task? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  bool rename(String id, String title) {
    final trimmed = title.trim();
    final index = _tasks.indexWhere((task) => task.id == id);
    if (trimmed.isEmpty || index < 0) return false;
    _tasks[index] = _tasks[index].copyWith(title: trimmed);
    _save();
    notifyListeners();
    return true;
  }

  bool editDetail(
    String id,
    String title,
    String? suggestedStart, {
    String? startPeriod,
    String? deadlineValue,
    String? deadlinePeriod,
    String? firstStep,
    String? firstStepReason,
    TaskHorizon? horizon,
    bool? manualHorizon,
    TaskPriority? priority,
    String? category,
    bool updateAll = false,
  }) {
    final trimmed = title.trim();
    final index = _tasks.indexWhere((task) => task.id == id);
    if (trimmed.isEmpty || index < 0) return false;
    if (category != null && !taskCategories.contains(category)) {
      throw const FormatException('Invalid category');
    }
    final original = _tasks[index];
    if (suggestedStart != null && suggestedStart != original.suggestedStart) {
      suggestedStart = validateStart(suggestedStart);
    }
    final end = deadlineValue == null ? null : validateStart(deadlineValue);
    if (updateAll) {
      if ((startPeriod != null &&
              (!taskPeriods.contains(startPeriod) ||
                  suggestedStart == null ||
                  suggestedStart.contains('T'))) ||
          (deadlinePeriod != null &&
              (!taskPeriods.contains(deadlinePeriod) ||
                  end == null ||
                  end.contains('T')))) {
        throw const FormatException('Invalid date period');
      }
    }
    _tasks[index] = _grouped(
      original.copyWith(
        title: trimmed,
        suggestedStart: suggestedStart,
        updateSuggestedStart: true,
        startPeriod: startPeriod,
        deadline: end == null ? null : DateTime.parse(end).toLocal(),
        deadlinePeriod: deadlinePeriod,
        deadlineDateOnly: updateAll ? end != null && !end.contains('T') : null,
        updateTimes: updateAll,
        firstStep: firstStep?.trim().isEmpty == true ? null : firstStep,
        firstStepReason: firstStepReason?.trim().isEmpty == true
            ? null
            : firstStepReason,
        updateSteps: false,
        priority: priority,
        category: category,
        horizon: horizon,
        manualHorizon: manualHorizon,
      ),
    );
    _save();
    notifyListeners();
    return true;
  }

  void delete(String id) {
    if (taskById(id) == null) return;
    _pending.remove(id)?.cancel();
    _pendingCompletions.remove(id);
    _tasks.removeWhere((task) => task.id == id);
    _save();
    notifyListeners();
  }

  void toggle(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) return;
    final done = !_tasks[index].done;
    _tasks[index] = _grouped(
      _tasks[index].withCompletion(done, completedAt: done ? now : null),
    );
    _pending.remove(id)?.cancel();
    _pendingCompletions.remove(id);
    if (done) {
      _pendingCompletions[id] = now.toUtc();
      _pending[id] = Timer(undoWindow, () => _finalizeCompletion(id));
    }
    _save();
    notifyListeners();
  }

  @override
  void dispose() {
    _dateTimer?.cancel();
    for (final timer in _pending.values) {
      timer.cancel();
    }
    _pending.clear();
    super.dispose();
  }
}
