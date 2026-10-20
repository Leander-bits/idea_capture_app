import 'task_draft.dart';

class TaskCancellation {
  const TaskCancellation({required this.target, required this.candidateIds});
  final String target;
  final List<String> candidateIds;

  factory TaskCancellation.fromJson(Map<String, dynamic> json) =>
      TaskCancellation(
        target: json['target'] as String,
        candidateIds: (json['candidate_ids'] as List<dynamic>).cast<String>(),
      );
}

class ExtractionPlan {
  const ExtractionPlan({
    this.tasks = const [],
    this.cancellations = const [],
    this.timings = const {},
  });
  final List<TaskDraft> tasks;
  final List<TaskCancellation> cancellations;
  final Map<String, dynamic> timings;
  bool get isEmpty => tasks.isEmpty && cancellations.isEmpty;
}

class ConfirmedExtraction {
  const ConfirmedExtraction({required this.tasks, this.deleteIds = const []});
  final List<TaskDraft> tasks;
  final List<String> deleteIds;
}
