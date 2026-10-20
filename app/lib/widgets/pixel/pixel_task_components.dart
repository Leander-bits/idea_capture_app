import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/task_draft.dart';
import '../../theme/pixel_theme.dart';
import 'pixel_art.dart';
import 'achievement_art.dart';
import '../../models/achievement.dart';
import 'pixel_reward_motion.dart';
import 'pixel_components.dart';

class PixelTaskRow extends StatelessWidget {
  const PixelTaskRow({
    super.key,
    required this.task,
    required this.now,
    required this.onToggle,
    required this.onOpen,
    this.divider = false,
  });
  final Task task;
  final DateTime now;
  final VoidCallback onToggle, onOpen;
  final bool divider;
  static const _metadata = TextStyle(fontSize: 11, color: PixelColors.muted);
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Container(
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: PixelColors.border))
            : null,
      ),
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
                      color: task.done ? PixelColors.secondary : null,
                      border: Border.all(
                        color: task.done
                            ? PixelColors.primary
                            : PixelColors.edge,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: PixelColors.shadow,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: task.done
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: PixelColors.primary,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 18, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: PixelIcon(
                            task.category == '工作' ? 'sword' : 'scroll',
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              height: 24 / 14,
                              fontWeight: FontWeight.w500,
                              color: task.done
                                  ? PixelColors.muted
                                  : PixelColors.text,
                              decoration: task.done
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: PixelColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(task.category, style: _metadata),
                        PriorityBadge(priority: task.priority),
                        if (task.suggestedStart != null) ...[
                          const Text('·', style: _metadata),
                          Text(
                            '${task.startSuggested ? '建议 ' : ''}${startLabel(task.suggestedStart!, task.startPeriod)}',
                            style: _metadata.copyWith(
                              color: task.priority == TaskPriority.high
                                  ? PixelColors.primary
                                  : PixelColors.muted,
                            ),
                          ),
                        ],
                        if (task.isOverdue(now))
                          const Text(
                            '已逾期',
                            style: TextStyle(
                              fontSize: 11,
                              color: PixelColors.danger,
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
    ),
  );
}

Color priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.high => PixelColors.pink,
  TaskPriority.medium => PixelColors.gold,
  TaskPriority.low => PixelColors.purple,
};

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});
  final TaskPriority priority;
  @override
  Widget build(BuildContext context) => Text(
    '■ ${priority.label}',
    style: TextStyle(fontSize: 11, color: priorityColor(priority)),
  );
}

class PixelUndoNotice extends StatelessWidget {
  const PixelUndoNotice({
    super.key,
    required this.task,
    required this.onUndo,
    this.alreadyCollected = false,
  });
  final Task task;
  final VoidCallback onUndo;
  final bool alreadyCollected;
  @override
  Widget build(BuildContext context) {
    final type = matchAchievement(task);
    return PixelCompletionMotion(
      key: ValueKey('${task.id}-${task.completedAt}'),
      child: Semantics(
        liveRegion: true,
        child: PixelSurface(
          borderColor: PixelColors.primary,
          shadow: 4,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              AchievementArt(type: type, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '已完成：${task.title}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${type.name} · ${alreadyCollected ? '已收集' : '待收集'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: PixelColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('undo-completion'),
                onPressed: onUndo,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('撤销', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
