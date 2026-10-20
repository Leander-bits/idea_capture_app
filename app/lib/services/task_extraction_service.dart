import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/task_draft.dart';
import '../models/task.dart';
import '../models/extraction_plan.dart';
import 'backend_url.dart';

class TaskExtractionException implements Exception {
  const TaskExtractionException(this.message);
  final String message;
}

abstract interface class TaskExtractionService {
  Future<ExtractionPlan> extract(
    String text, {
    List<Task> existingTasks = const [],
  });
  void dispose();
}

class LocalTaskExtractionService implements TaskExtractionService {
  LocalTaskExtractionService({
    Uri? baseUrl,
    http.Client? client,
    Future<Map<String, String>> Function()? deviceContext,
  }) : _baseUrl = baseUrl ?? backendBaseUrl(),
       _client = client ?? http.Client(),
       _deviceContext = deviceContext ?? _readDeviceContext;

  final Uri _baseUrl;
  final http.Client _client;
  final Future<Map<String, String>> Function() _deviceContext;

  static Future<Map<String, String>> _readDeviceContext() async {
    final zone = await FlutterTimezone.getLocalTimezone();
    return {
      'current_time': DateTime.now().toUtc().toIso8601String(),
      'timezone': zone.identifier,
    };
  }

  @override
  Future<ExtractionPlan> extract(
    String text, {
    List<Task> existingTasks = const [],
  }) async {
    final elapsed = Stopwatch()..start();
    final device = await _deviceContext();
    final response = await _client
        .post(
          _baseUrl.resolve('/extract-tasks'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'text': text.trim(),
            ...device,
            'existing_tasks': [
              for (final task in existingTasks)
                if (!task.done)
                  {
                    'id': task.id,
                    'title': task.title,
                    'description': task.description,
                    'suggestedStart':
                        task.suggestedStart != null &&
                            RegExp(r'^\d{4}-\d{2}-\d{2}')
                                .hasMatch(task.suggestedStart!)
                        ? task.suggestedStart
                        : null,
                    'startPeriod': task.startPeriod,
                    'deadline': task.deadline == null
                        ? null
                        : task.deadlineDateOnly
                        ? dateValue(task.deadline!)
                        : minuteValue(task.deadline!),
                  },
            ],
          }),
        )
        .timeout(
          const Duration(minutes: 3),
          onTimeout: () =>
              throw const TaskExtractionException('任务整理超时，文字和录音已保留，请重试。'),
        );
    if (response.statusCode != 200) {
      String? message;
      try {
        final detail = (jsonDecode(
          utf8.decode(response.bodyBytes),
        ) as Map<String, dynamic>)['detail'];
        if (detail is String && RegExp(r'[\u4e00-\u9fff]').hasMatch(detail)) {
          message = detail;
        }
      } on FormatException {
        // A proxy may return HTML instead of the backend's JSON error.
      } on TypeError {
        // Invalid error bodies never expose technical messages to the UI.
      }
      throw TaskExtractionException(message ?? '提取失败，文字和录音已保留，请重试。');
    }
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final tasks = data['tasks'] as List<dynamic>;
    final drafts = tasks
        .map((value) => TaskDraft.fromJson(value as Map<String, dynamic>))
        .toList();
    final cancellations = (data['cancellations'] as List<dynamic>)
        .map(
          (value) => TaskCancellation.fromJson(value as Map<String, dynamic>),
        )
        .toList();
    final activeIds = existingTasks
        .where((task) => !task.done)
        .map((task) => task.id)
        .toSet();
    if (cancellations.any(
      (item) =>
          item.candidateIds.isEmpty ||
          item.candidateIds.any((id) => !activeIds.contains(id)),
    )) {
      throw const FormatException('Invalid cancellation candidates');
    }
    final timings = {
      ...?data['timings'] as Map<String, dynamic>?,
      'client_elapsed_ms': elapsed.elapsedMicroseconds / 1000,
    };
    debugPrint('Extraction timings: ${jsonEncode(timings)}');
    return ExtractionPlan(
      tasks: drafts,
      cancellations: cancellations,
      timings: timings,
    );
  }

  @override
  void dispose() => _client.close();
}
