import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import 'task_row.dart';

class TaskGroup extends StatelessWidget {
  const TaskGroup({
    super.key,
    required this.tasks,
    required this.onToggle,
    required this.onOpen,
    this.completed = false,
    this.now,
  });

  final List<Task> tasks;
  final ValueChanged<String> onToggle;
  final ValueChanged<Task> onOpen;
  final bool completed;
  final DateTime? now;

  @override
  Widget build(BuildContext context) => TaskSurface(
    child: ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++)
            TaskRow(
              task: tasks[i],
              now: now,
              divider: i < tasks.length - 1 || completed,
              onToggle: () => onToggle(tasks[i].id),
              onOpen: () => onOpen(tasks[i]),
            ),
          if (completed)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '点一下勾选，即可恢复到原来的位置。',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
