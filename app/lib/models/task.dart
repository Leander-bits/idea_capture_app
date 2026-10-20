import 'task_time.dart';

enum TaskHorizon { today, recently, later }

enum TaskSource { manual, voice }

enum TaskPriority {
  high('高优先级'),
  medium('中优先级'),
  low('低优先级');

  const TaskPriority(this.label);
  final String label;
  static TaskPriority fromStored(String? value) => switch (value) {
    'high' || '高' || '高优先级' => high,
    'low' || '低' || '低优先级' || '底优先级' => low,
    'medium' || '中' || '中优先级' || '普通' => medium,
    _ => medium,
  };
}

const taskCategories = ['工作', '生活', '健康', '学习', '其他'];

String migrateCategory(String? value, String title) => switch (value) {
  '运动' => '健康',
  '项目' => '工作',
  '旅游' || '社交' => '生活',
  '工作' || '生活' || '健康' || '学习' || '其他' => value!,
  _ => '其他',
};

class Task {
  const Task({
    required this.id,
    required this.title,
    this.horizon = TaskHorizon.today,
    this.importantToday = false,
    this.category = '生活',
    this.suggestedStart,
    this.startSuggested = false,
    this.prioritySuggested = false,
    this.startPeriod,
    this.deadlinePeriod,
    this.deadlineDateOnly = false,
    this.manualHorizon = false,
    this.duration,
    this.priority = TaskPriority.medium,
    this.description,
    this.firstStep,
    this.firstStepReason,
    this.deadline,
    this.source,
    this.done = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final TaskHorizon horizon;
  final bool importantToday;
  final String category;
  final String? suggestedStart;
  final bool startSuggested, prioritySuggested;
  final String? startPeriod;
  final String? deadlinePeriod;
  final bool deadlineDateOnly;
  final bool manualHorizon;
  final String? duration;
  final TaskPriority priority;
  final String? description;
  final String? firstStep;
  final String? firstStepReason;
  final DateTime? deadline;
  final TaskSource? source;
  final bool done;
  final DateTime? completedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'horizon': horizon.name,
    'importantToday': importantToday,
    'category': category,
    'suggestedStart': suggestedStart,
    'startSuggested': startSuggested,
    'prioritySuggested': prioritySuggested,
    'startPeriod': startPeriod,
    'deadlinePeriod': deadlinePeriod,
    'deadlineDateOnly': deadlineDateOnly,
    'manualHorizon': manualHorizon,
    'duration': duration,
    'priority': priority.name,
    'description': description,
    'firstStep': firstStep,
    'firstStepReason': firstStepReason,
    'deadline': deadline == null
        ? null
        : deadlineDateOnly
        ? dateValue(deadline!.toLocal())
        : minuteValue(deadline!),
    'source': source?.name,
    'done': done,
    'completedAt': done ? completedAt?.toUtc().toIso8601String() : null,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    title: json['title'] as String,
    horizon: TaskHorizon.values.byName(json['horizon'] as String),
    importantToday: json['importantToday'] as bool,
    category: migrateCategory(
      json['category'] as String?,
      json['title'] as String,
    ),
    suggestedStart: _migrateStart(json['suggestedStart'] as String?),
    startSuggested:
        json['suggestedStart'] != null &&
        (json['startSuggested'] as bool? ?? false),
    prioritySuggested: json['prioritySuggested'] as bool? ?? false,
    startPeriod: taskPeriods.contains(json['startPeriod'])
        ? json['startPeriod'] as String
        : null,
    deadlinePeriod: taskPeriods.contains(json['deadlinePeriod'])
        ? json['deadlinePeriod'] as String
        : null,
    deadlineDateOnly:
        json['deadlineDateOnly'] as bool? ??
        _legacyDateOnly(json['deadline'] as String?),
    manualHorizon: json['manualHorizon'] as bool? ?? false,
    duration: json['duration'] as String?,
    priority: TaskPriority.fromStored(json['priority'] as String?),
    description: json['description'] as String?,
    firstStep: json['firstStep'] as String?,
    firstStepReason: json['firstStepReason'] as String?,
    deadline: json['deadline'] == null
        ? null
        : DateTime.parse(json['deadline'] as String).toLocal(),
    source: json['source'] == null
        ? null
        : TaskSource.values.byName(json['source'] as String),
    done: json['done'] as bool,
    completedAt: json['done'] == true && json['completedAt'] is String
        ? DateTime.tryParse(json['completedAt'] as String)?.toUtc()
        : null,
  );

  Task withCompletion(bool value, {DateTime? completedAt}) => copyWith(
    done: value,
    completedAt: value ? completedAt?.toUtc() : null,
    updateCompletionTime: true,
  );

  bool isOverdue(DateTime now) {
    if (done || deadline == null) return false;
    final local = deadline!.toLocal();
    final boundary = deadlineDateOnly
        ? DateTime(local.year, local.month, local.day + 1)
        : local;
    return deadlineDateOnly ? !now.isBefore(boundary) : now.isAfter(boundary);
  }

  static bool _legacyDateOnly(String? value) {
    if (value == null) return false;
    final parsed = DateTime.tryParse(value)?.toLocal();
    return !value.contains('T') || (parsed?.hour == 0 && parsed?.minute == 0);
  }

  static String? _migrateStart(String? value) {
    if (value == null) return null;
    try {
      return validateStart(value);
    } on FormatException {
      return value; // Keep old unanchored mock text without inventing a date.
    }
  }

  Task copyWith({
    String? title,
    String? category,
    TaskPriority? priority,
    bool? done,
    DateTime? completedAt,
    bool updateCompletionTime = false,
    String? suggestedStart,
    bool updateSuggestedStart = false,
    String? startPeriod,
    String? deadlinePeriod,
    DateTime? deadline,
    bool? deadlineDateOnly,
    bool updateTimes = false,
    String? firstStep,
    String? firstStepReason,
    bool updateSteps = false,
    TaskHorizon? horizon,
    bool? manualHorizon,
  }) => Task(
    id: id,
    title: title ?? this.title,
    horizon: horizon ?? this.horizon,
    manualHorizon: manualHorizon ?? this.manualHorizon,
    importantToday: importantToday,
    category: category ?? this.category,
    suggestedStart: updateSuggestedStart ? suggestedStart : this.suggestedStart,
    startSuggested:
        (updateSuggestedStart && suggestedStart != this.suggestedStart) ||
            (updateTimes && startPeriod != this.startPeriod)
        ? false
        : startSuggested,
    prioritySuggested: priority == null ? prioritySuggested : false,
    startPeriod: updateTimes ? startPeriod : this.startPeriod,
    deadlinePeriod: updateTimes ? deadlinePeriod : this.deadlinePeriod,
    deadlineDateOnly: deadlineDateOnly ?? this.deadlineDateOnly,
    duration: duration,
    priority: priority ?? this.priority,
    description: description,
    firstStep: updateSteps ? firstStep : this.firstStep,
    firstStepReason: updateSteps ? firstStepReason : this.firstStepReason,
    deadline: updateTimes ? deadline : this.deadline,
    source: source,
    done: done ?? this.done,
    completedAt: (done ?? this.done)
        ? (updateCompletionTime ? completedAt : this.completedAt)
        : null,
  );
}
