import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';
import 'task_group.dart';

class CompletedSection extends StatelessWidget {
  const CompletedSection({
    super.key,
    required this.tasks,
    required this.expanded,
    required this.onExpansionChanged,
    required this.onToggle,
    required this.onOpen,
  });

  final List<Task> tasks;
  final bool expanded;
  final VoidCallback onExpansionChanged;
  final ValueChanged<String> onToggle;
  final ValueChanged<Task> onOpen;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Semantics(
            expanded: expanded,
            child: InkWell(
              key: const ValueKey('completed-section-toggle'),
              onTap: onExpansionChanged,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '已完成 · ${tasks.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.chevron_right,
                      size: 15,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            TaskGroup(
              tasks: tasks,
              completed: true,
              onToggle: onToggle,
              onOpen: onOpen,
            ),
        ],
      ),
    );
  }
}
