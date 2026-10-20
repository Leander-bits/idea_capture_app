import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/task_store.dart';
import '../theme/pixel_theme.dart';
import 'achievements_screen.dart';
import '../widgets/pixel/pixel_art.dart';
import '../widgets/pixel/pixel_components.dart';
import '../widgets/pixel/pixel_task_components.dart';
import '../widgets/pixel/pixel_task_sections.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.store,
    required this.onShowTasks,
    required this.onOpenTask,
    required this.onShowCapture,
    this.active = true,
  });
  final TaskStore store;
  final VoidCallback onShowTasks, onShowCapture;
  final ValueChanged<Task> onOpenTask;
  final bool active;
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _showCompleted = false;
  Widget _group(List<Task> tasks) => PixelTaskGroup(
    tasks: tasks,
    now: widget.store.now,
    onToggle: widget.store.toggle,
    onOpen: widget.onOpenTask,
  );
  @override
  Widget build(BuildContext context) => Theme(
    data: PixelTheme.dark,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PixelColors.sky, PixelColors.background],
          stops: [0, .45],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) {
            final store = widget.store;
            final today = store.pendingFor(TaskHorizon.today);
            final other = today;
            final completed = store.completed;
            final pending = store.latestPending;
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ListView(
                        key: const PageStorageKey('today-scroll'),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  '今天待办',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              PixelButton(
                                key: const ValueKey('today-achievements'),
                                label: '成就墙',
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        AchievementsScreen(store: store),
                                  ),
                                ),
                                child: Text(
                                  '成就墙 · ${store.achievements.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: PixelColors.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '今日已完成 ${store.completedTodayCount} 项',
                              key: const ValueKey('today-completion-count'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: PixelColors.muted,
                              ),
                            ),
                          ),
                          if (!today.any((task) => !task.done)) ...[
                            const SizedBox(height: 24),
                            PixelSurface(
                              leftAccent: true,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const PixelIcon(
                                    'scroll',
                                    color: PixelColors.purple,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '今天暂时没有待办',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: PixelColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '有了想法，随时记下来。',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: PixelColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  PixelButton(
                                    key: const ValueKey('today-empty-capture'),
                                    onPressed: widget.onShowCapture,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.mic_none_outlined,
                                          size: 20,
                                          color: PixelColors.primary,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '记录一个想法',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: PixelColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          PixelSectionHeading(
                            '${today.where((task) => !task.done).length} 项待办',
                            trailing: TextButton(
                              key: const ValueKey('today-all-tasks'),
                              onPressed: widget.onShowTasks,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('全部', style: TextStyle(fontSize: 12)),
                                  Icon(Icons.chevron_right, size: 13),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (other.isNotEmpty) _group(other),
                          if (completed.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Semantics(
                              expanded: _showCompleted,
                              child: InkWell(
                                key: const ValueKey('completed-section-toggle'),
                                onTap: () => setState(
                                  () => _showCompleted = !_showCompleted,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '已完成 · ${completed.length}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: PixelColors.muted,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        _showCompleted
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
                            if (_showCompleted) ...[
                              _group(completed),
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  '点一下勾选，即可恢复到原来的位置。',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: PixelColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                      if (pending == null)
                        Positioned(
                          bottom: 24,
                          right: 20,
                          child: PixelButton(
                            key: const ValueKey('today-capture'),
                            label: '记录一个想法',
                            onPressed: widget.onShowCapture,
                            child: const Icon(
                              Icons.mic_none_outlined,
                              size: 24,
                              color: PixelColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (pending != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: PixelUndoNotice(
                      task: pending,
                      alreadyCollected: store.hasContributed(pending.id),
                      onUndo: () => store.toggle(pending.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
