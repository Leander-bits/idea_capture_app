import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../theme/pixel_theme.dart';
import 'pixel_art.dart';
import 'pixel_components.dart';
import 'pixel_task_components.dart';

class PixelTaskGroup extends StatelessWidget {
  const PixelTaskGroup({
    super.key,
    required this.tasks,
    required this.now,
    required this.onToggle,
    required this.onOpen,
  });
  final List<Task> tasks;
  final DateTime now;
  final ValueChanged<String> onToggle;
  final ValueChanged<Task> onOpen;
  @override
  Widget build(BuildContext context) => PixelSurface(
    leftAccent: true,
    child: Column(
      children: [
        for (var i = 0; i < tasks.length; i++)
          PixelTaskRow(
            task: tasks[i],
            now: now,
            divider: i < tasks.length - 1,
            onToggle: () => onToggle(tasks[i].id),
            onOpen: () => onOpen(tasks[i]),
          ),
      ],
    ),
  );
}

class PixelHorizonSwitcher extends StatelessWidget {
  const PixelHorizonSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final TaskHorizon selected;
  final ValueChanged<TaskHorizon> onSelected;
  @override
  Widget build(BuildContext context) => PixelSurface(
    color: PixelColors.mutedSurface,
    shadow: 0,
    padding: const EdgeInsets.all(4),
    child: Row(
      children: [
        for (final horizon in TaskHorizon.values) ...[
          if (horizon.index > 0) const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              selected: selected == horizon,
              button: true,
              child: Material(
                color: selected == horizon
                    ? PixelColors.secondary
                    : Colors.transparent,
                child: InkWell(
                  key: ValueKey('segment-${horizon.name}'),
                  onTap: () => onSelected(horizon),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected == horizon
                              ? PixelColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PixelIcon(
                          switch (horizon) {
                            TaskHorizon.today => 'sword',
                            TaskHorizon.recently => 'scroll',
                            TaskHorizon.later => 'chest',
                          },
                          size: 14,
                          color: selected == horizon
                              ? PixelColors.primary
                              : PixelColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            switch (horizon) {
                              TaskHorizon.today => '今天',
                              TaskHorizon.recently => '近期',
                              TaskHorizon.later => '以后',
                            },
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected == horizon
                                  ? PixelColors.primary
                                  : PixelColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class PixelCompletedSection extends StatelessWidget {
  const PixelCompletedSection({
    super.key,
    required this.tasks,
    required this.now,
    required this.expanded,
    required this.onExpansionChanged,
    required this.onToggle,
    required this.onOpen,
  });
  final List<Task> tasks;
  final DateTime now;
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
                          color: PixelColors.muted,
                        ),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.chevron_right,
                      size: 15,
                      color: PixelColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded)
            PixelTaskGroup(
              tasks: tasks,
              now: now,
              onToggle: onToggle,
              onOpen: onOpen,
            ),
        ],
      ),
    );
  }
}
