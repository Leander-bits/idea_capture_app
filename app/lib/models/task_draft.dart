import 'task.dart';
import 'task_time.dart';
export 'task_time.dart';

class TaskDraft {
  const TaskDraft({
    required this.title,
    this.description,
    this.category = '生活',
    this.horizon = TaskHorizon.today,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.suggestedStart,
    this.startSuggested = false,
    this.prioritySuggested = false,
    this.startPeriod,
    this.deadlinePeriod,
    this.deadlineDateOnly = false,
    this.firstStep,
    this.firstStepReason,
  });

  final String title;
  final String? description;
  final String category;
  final TaskHorizon horizon;
  final DateTime? deadline;
  final TaskPriority priority;
  final String? suggestedStart;
  final bool startSuggested, prioritySuggested;
  final String? startPeriod;
  final String? deadlinePeriod;
  final bool deadlineDateOnly;
  final String? firstStep;
  final String? firstStepReason;

  factory TaskDraft.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String).trim();
    if (title.isEmpty) throw const FormatException('Empty task title');
    final priority = json['priority'] as String;
    if (!TaskPriority.values.any((value) => value.name == priority)) {
      throw const FormatException('Invalid priority');
    }
    final category = json['category'] as String;
    if (!taskCategories.contains(category)) {
      throw const FormatException('Invalid category');
    }
    final start = json['suggestedStart'] == null
        ? null
        : validateStart(json['suggestedStart'] as String);
    final deadline = json['deadline'] == null
        ? null
        : validateStart(json['deadline'] as String);
    for (final field in ['startPeriod', 'deadlinePeriod']) {
      final period = json[field];
      final time = field == 'startPeriod' ? start : deadline;
      if (period != null &&
          (!taskPeriods.contains(period) ||
              time == null ||
              time.contains('T'))) {
        throw const FormatException('Invalid date period');
      }
    }
    return TaskDraft(
      title: title,
      description: json['description'] as String?,
      category: category,
      horizon: TaskHorizon.values.byName(json['horizon'] as String),
      deadline: deadline == null ? null : DateTime.parse(deadline).toLocal(),
      deadlineDateOnly: deadline != null && !deadline.contains('T'),
      priority: TaskPriority.values.byName(priority),
      suggestedStart: start,
      startSuggested:
          start != null && (json['startSuggested'] as bool? ?? false),
      prioritySuggested: json['prioritySuggested'] as bool? ?? false,
      startPeriod: json['startPeriod'] as String?,
      deadlinePeriod: json['deadlinePeriod'] as String?,
      firstStep: json['firstStep'] as String?,
      firstStepReason: json['firstStepReason'] as String?,
    );
  }

  Task toTask(String id) => Task(
    id: id,
    title: title.trim(),
    description: description,
    category: category,
    horizon: horizon,
    deadline: deadline,
    priority: priority,
    suggestedStart: suggestedStart,
    startSuggested: startSuggested,
    prioritySuggested: prioritySuggested,
    startPeriod: startPeriod,
    deadlinePeriod: deadlinePeriod,
    deadlineDateOnly: deadlineDateOnly,
    firstStep: firstStep,
    firstStepReason: firstStepReason,
    source: TaskSource.voice,
  );
}

String horizonLabel(TaskHorizon value) => switch (value) {
  TaskHorizon.today => '今天',
  TaskHorizon.recently => '近期',
  TaskHorizon.later => '以后',
};
