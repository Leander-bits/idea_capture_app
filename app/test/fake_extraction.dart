import 'dart:async';

import 'package:idea_capture/models/task_draft.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/models/extraction_plan.dart';
import 'package:idea_capture/services/task_extraction_service.dart';

class FakeExtractionService implements TaskExtractionService {
  bool automatic = true;
  final inputs = <String>[];
  final requests = <Completer<ExtractionPlan>>[];
  final existing = <List<Task>>[];

  @override
  Future<ExtractionPlan> extract(
    String text, {
    List<Task> existingTasks = const [],
  }) {
    inputs.add(text);
    existing.add(existingTasks);
    if (automatic) {
      return Future.value(
        ExtractionPlan(tasks: [TaskDraft(title: text.trim())]),
      );
    }
    final request = Completer<ExtractionPlan>();
    requests.add(request);
    return request.future;
  }

  @override
  void dispose() {}
}

FakeExtractionService fakeExtraction() => FakeExtractionService();
