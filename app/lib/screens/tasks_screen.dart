import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/task_store.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel/pixel_art.dart';
import '../widgets/pixel/pixel_components.dart';
import '../widgets/pixel/pixel_task_components.dart';
import '../widgets/pixel/pixel_task_sections.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    super.key,
    required this.store,
    required this.onOpenTask,
    required this.onShowCapture,
  });

  final TaskStore store;
  final ValueChanged<Task> onOpenTask;
  final VoidCallback onShowCapture;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskHorizon _selected = TaskHorizon.today;
  bool _showCompleted = false;
  final _scrollControllers = {
    for (final horizon in TaskHorizon.values) horizon: ScrollController(),
  };

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _list(TaskHorizon horizon) {
    final store = widget.store;
    final tasks = store.pendingFor(horizon);
    return ListView(
      key: PageStorageKey('tasks-${horizon.name}-scroll'),
      controller: _scrollControllers[horizon],
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (tasks.isNotEmpty)
          PixelTaskGroup(
            tasks: tasks,
            now: store.now,
            onToggle: store.toggle,
            onOpen: widget.onOpenTask,
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              horizon == TaskHorizon.today &&
                      store.tasks.any((task) => task.horizon == horizon)
                  ? '今天的待办都完成了。'
                  : '这里暂时没有待办。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: PixelColors.muted),
            ),
          ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: ValueKey('add-task-${horizon.name}'),
            onPressed: widget.onShowCapture,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: PixelColors.primary,
              textStyle: const TextStyle(fontSize: 13),
            ),
            icon: const Icon(Icons.add, size: 17),
            label: const Text('添加待办'),
          ),
        ),
        PixelCompletedSection(
          tasks: store.completed,
          now: store.now,
          expanded: _showCompleted,
          onExpansionChanged: () =>
              setState(() => _showCompleted = !_showCompleted),
          onToggle: store.toggle,
          onOpen: widget.onOpenTask,
        ),
      ],
    );
  }

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
            final pending = widget.store.latestPending;
            final count = widget.store.tasks
                .where((task) => task.horizon == _selected && !task.done)
                .length;
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const PixelIcon('scroll', color: PixelColors.gold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '任务',
                              style: const TextStyle(
                                fontSize: 31,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: PixelColors.text,
                                shadows: [
                                  Shadow(
                                    color: PixelColors.shadow,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Semantics(
                            label: '添加任务',
                            button: true,
                            onTap: widget.onShowCapture,
                            child: InkWell(
                              key: const ValueKey('tasks-add'),
                              onTap: widget.onShowCapture,
                              excludeFromSemantics: true,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                child: Center(
                                  child: PixelSurface(
                                    color: PixelColors.card,
                                    borderColor: PixelColors.edge,
                                    child: const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Icon(
                                        Icons.add,
                                        size: 21,
                                        color: PixelColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PixelHorizonSwitcher(
                        selected: _selected,
                        onSelected: (value) =>
                            setState(() => _selected = value),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '$count 项待办',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PixelColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: IndexedStack(
                          index: _selected.index,
                          children: [
                            for (final horizon in TaskHorizon.values)
                              _list(horizon),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (pending != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: PixelUndoNotice(
                      task: pending,
                      alreadyCollected: widget.store.hasContributed(pending.id),
                      onUndo: () => widget.store.toggle(pending.id),
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
