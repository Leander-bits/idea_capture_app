import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:idea_capture/models/task.dart';
import 'package:idea_capture/services/task_extraction_service.dart';

void main() {
  test(
    'backend Chinese validation error reaches Capture without partial results',
    () async {
      const message = '模型返回的任务未通过校验，文字和录音已保留，未保存任何待办，请重试。';
      final service = LocalTaskExtractionService(
        deviceContext: () async => {
          'current_time': '2026-10-11T12:00:00Z',
          'timezone': 'Europe/Berlin',
        },
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': message}),
            502,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.extract('原文'),
        throwsA(
          isA<TaskExtractionException>().having(
            (e) => e.message,
            'message',
            message,
          ),
        ),
      );
    },
  );

  test('request sends edited text, actual clock and IANA timezone; parses multiple tasks', () async {
    final service = LocalTaskExtractionService(
      deviceContext: () async => {
        'current_time': '2026-10-08T22:30:00Z',
        'timezone': 'Asia/Shanghai',
      },
      client: MockClient((request) async {
        expect(request.url.path, '/extract-tasks');
        expect(jsonDecode(request.body), {
          'text': '修改后的文字',
          'current_time': '2026-10-08T22:30:00Z',
          'timezone': 'Asia/Shanghai',
          'existing_tasks': [],
        });
        return http.Response(
          jsonEncode({
            'cancellations': [],
            'tasks': [
              {
                'title': '买牛奶',
                'description': null,
                'category': '生活',
                'horizon': 'recently',
                'deadline': null,
                'priority': 'medium',
                'suggestedStart': '2026-10-10',
              },
              {
                'title': '提交报告',
                'description': '给经理',
                'category': '工作',
                'horizon': 'later',
                'deadline': '2026-10-10',
                'priority': 'high',
                'suggestedStart': null,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(service.dispose);
    final tasks = (await service.extract(' 修改后的文字 ')).tasks;
    expect(tasks.length, 2);
    expect(tasks.first.horizon, TaskHorizon.recently);
    expect(tasks.first.deadline, isNull);
    expect(tasks.last.deadline, DateTime(2026, 10, 10));
    expect(tasks.last.description, '给经理');
  });

  test('a malformed task rejects the entire batch', () async {
    final service = LocalTaskExtractionService(
      deviceContext: () async => {
        'current_time': '2026-10-08T22:30:00Z',
        'timezone': 'UTC',
      },
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'tasks': [
              {
                'title': '有效任务',
                'description': null,
                'category': '生活',
                'horizon': 'today',
                'deadline': null,
                'priority': 'medium',
              },
              {
                'title': '无效任务',
                'description': null,
                'category': '生活',
                'horizon': 'invented',
                'deadline': null,
                'priority': 'medium',
              },
            ],
          }),
          200,
        ),
      ),
    );
    addTearDown(service.dispose);
    await expectLater(service.extract('原文'), throwsArgumentError);
  });
}
