import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_draft.dart';
import '../theme/app_theme.dart';

class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onOpen,
    this.divider = false,
    this.now,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final bool divider;
  final DateTime? now;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: '${task.done ? '恢复任务' : '完成任务'}：${task.title}',
          button: true,
          checked: task.done,
          onTap: onToggle,
          child: InkWell(
            key: ValueKey('toggle-${task.id}'),
            onTap: onToggle,
            excludeFromSemantics: true,
            child: SizedBox(
              width: 48,
              height: 61,
              child: Center(
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: task.done ? AppColors.secondary : null,
                    border: Border.all(
                      color: task.done ? AppColors.primary : AppColors.circle,
                      width: 1.5,
                    ),
                  ),
                  child: task.done
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: InkWell(
            key: ValueKey('open-${task.id}'),
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.only(top: 18, bottom: 18, right: 16),
              decoration: BoxDecoration(
                border: divider
                    ? const Border(bottom: BorderSide(color: AppColors.divider))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      height: 24 / 14,
                      fontWeight: FontWeight.w500,
                      color: task.done ? AppColors.muted : AppColors.text,
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(task.category, style: _metadata),
                      if (task.suggestedStart != null)
                        const Text('·', style: _metadata),
                      if (task.suggestedStart != null)
                        Text(
                          startLabel(task.suggestedStart!, task.startPeriod),
                          style: _metadata.copyWith(
                            color: task.priority == TaskPriority.high
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                        ),
                      if (task.isOverdue(now ?? DateTime.now()))
                        const Text(
                          '已逾期',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.destructive,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  static const _metadata = TextStyle(fontSize: 11, color: AppColors.muted);
}

class TaskSurface extends StatelessWidget {
  const TaskSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppTheme.taskRadius),
    child: child,
  );
}
