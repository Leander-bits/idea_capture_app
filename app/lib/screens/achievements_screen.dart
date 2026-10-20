import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../models/task.dart';
import '../models/task_draft.dart';
import '../state/task_store.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel/achievement_art.dart';
import '../widgets/pixel/pixel_components.dart';
import '../widgets/pixel/pixel_task_components.dart';
import '../widgets/detail_components.dart';
import 'task_detail_screen.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.store});
  final TaskStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('成就墙')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            key: const ValueKey('achievement-wall'),
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 500 ? 3 : 2,
              mainAxisExtent:
                  148 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: achievementTypes.length,
            itemBuilder: (context, i) {
              final type = achievementTypes[i];
              final count = store.achievements
                  .where((item) => item.typeId == type.id)
                  .length;
              return PixelButton(
                key: ValueKey('achievement-type-${type.id}'),
                label: '${type.label}，${count == 0 ? '未收集' : '已获得 $count 次'}',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        _AchievementTypeScreen(store: store, type: type),
                  ),
                ),
                borderColor: count == 0 ? PixelColors.border : PixelColors.gold,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AchievementArt(type: type, collected: count > 0),
                    const SizedBox(height: 10),
                    Text(
                      type.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      count == 0 ? '未收集' : '已获得 $count 次',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: count == 0
                            ? PixelColors.muted
                            : PixelColors.gold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _AchievementTypeScreen extends StatelessWidget {
  const _AchievementTypeScreen({required this.store, required this.type});
  final TaskStore store;
  final AchievementType type;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(type.name)),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final items = store.achievements
              .where((item) => item.typeId == type.id)
              .toList()
              .reversed
              .toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: AchievementArt(
                  type: type,
                  size: 80,
                  collected: items.isNotEmpty,
                ),
              ),
              const SizedBox(height: 24),
              if (items.isEmpty)
                const Text('还没有收集到这项成就。', textAlign: TextAlign.center),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PixelButton(
                    key: ValueKey('achievement-history-${item.taskId}'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => _AchievementHistoryScreen(
                          store: store,
                          achievement: item,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.snapshot.title),
                        const SizedBox(height: 6),
                        Text(
                          '获得于 ${startLabel(minuteValue(item.obtainedAt))}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: PixelColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _AchievementHistoryScreen extends StatelessWidget {
  const _AchievementHistoryScreen({
    required this.store,
    required this.achievement,
  });
  final TaskStore store;
  final Achievement achievement;
  @override
  Widget build(BuildContext context) {
    final task = achievement.snapshot;
    final type = achievementType(achievement.typeId);
    return Scaffold(
      appBar: AppBar(title: const Text('成就详情')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: AchievementArt(type: type, size: 80)),
            const SizedBox(height: 16),
            Text(
              type.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, color: PixelColors.gold),
            ),
            const SizedBox(height: 12),
            Text(
              '获得于 ${startLabel(minuteValue(achievement.obtainedAt))}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: PixelColors.muted),
            ),
            const SizedBox(height: 24),
            Text(task.title, style: const TextStyle(fontSize: 22)),
            if (task.description case final text?) ...[
              const SizedBox(height: 12),
              Text(text.split('\n建议理由：').first.trim()),
            ],
            const SizedBox(height: 20),
            PixelSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('分类：${task.category}'),
                  const SizedBox(height: 10),
                  PriorityBadge(priority: task.priority),
                  const SizedBox(height: 10),
                  Text('分组：${horizonLabel(task.horizon)}'),
                  if (task.suggestedStart case final value?)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '${task.startSuggested ? '建议开始' : '开始'}：${startLabel(value, task.startPeriod)}',
                      ),
                    ),
                  if (task.deadline case final value?)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '截止：${deadlineLabel(value, dateOnly: task.deadlineDateOnly, period: task.deadlinePeriod)}',
                      ),
                    ),
                  if (task.source != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        '来源：${task.source == TaskSource.voice ? '语音' : '手动'}',
                      ),
                    ),
                ],
              ),
            ),
            if (task.firstStep != null || task.firstStepReason != null) ...[
              const SizedBox(height: 24),
              const Text('建议的第一步'),
              const SizedBox(height: 12),
              NextStepCard(step: task.firstStep, reason: task.firstStepReason),
            ],
            const SizedBox(height: 24),
            const Text(
              '以上为获得成就时的任务快照。',
              style: TextStyle(fontSize: 11, color: PixelColors.muted),
            ),
            if (store.taskById(achievement.taskId) case final current?) ...[
              const SizedBox(height: 16),
              PixelButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        TaskDetailScreen(store: store, taskId: current.id),
                  ),
                ),
                child: const Text('查看当前任务'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
