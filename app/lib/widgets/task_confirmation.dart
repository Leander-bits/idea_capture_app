import 'package:flutter/material.dart';

import '../models/task_draft.dart';
import '../models/task.dart';
import '../models/extraction_plan.dart';
import '../theme/pixel_theme.dart';
import 'pixel/pixel_components.dart';

class TaskConfirmation extends StatefulWidget {
  const TaskConfirmation({
    super.key,
    required this.tasks,
    this.cancellations = const [],
    this.candidates = const [],
  });
  final List<TaskDraft> tasks;
  final List<TaskCancellation> cancellations;
  final List<Task> candidates;

  @override
  State<TaskConfirmation> createState() => _TaskConfirmationState();
}

class _TaskConfirmationState extends State<TaskConfirmation> {
  late final _selected = List.filled(widget.tasks.length, true);
  bool _submitted = false;
  late final Map<int, String> _deletions = {
    for (var i = 0; i < widget.cancellations.length; i++)
      if (widget.cancellations[i].candidateIds.length == 1)
        i: widget.cancellations[i].candidateIds.single,
  };

  Widget _cancellation(int index) {
    final item = widget.cancellations[index];
    final matches = widget.candidates
        .where((task) => item.candidateIds.contains(task.id))
        .toList();
    if (matches.length == 1) {
      return PixelSurface(
        borderColor: PixelColors.danger,
        shadow: 0,
        child: Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            key: ValueKey('confirm-delete-$index'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: PixelColors.danger,
            title: Text(
              matches.single.title,
              style: const TextStyle(fontSize: 14, color: PixelColors.danger),
            ),
            subtitle: const Text(
              '确认后删除',
              style: TextStyle(fontSize: 12, color: PixelColors.muted),
            ),
            value: (_deletions[index] ?? '').isNotEmpty,
            onChanged: (value) => setState(
              () => _deletions[index] = value! ? matches.single.id : '',
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('choose-delete-$index'),
        initialValue: _deletions[index],
        isExpanded: true,
        borderRadius: BorderRadius.zero,
        dropdownColor: PixelColors.card,
        decoration: InputDecoration(
          labelText: '取消「${item.target}」',
          helperText: '匹配到多项，请选择；也可保留旧任务',
          helperMaxLines: 3,
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('保留旧任务')),
          for (final task in matches)
            DropdownMenuItem(
              value: task.id,
              child: Text(
                '${task.title} · ${horizonLabel(task.horizon)}${task.suggestedStart == null ? '' : ' · ${startLabel(task.suggestedStart!)}'}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
        onChanged: (id) => setState(() => _deletions[index] = id!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.where((value) => value).length;
    final deleteIds = _deletions.values
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final resolved = _deletions.length == widget.cancellations.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.cancellations.isEmpty ? '确认待办' : '确认任务变更',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (widget.tasks.any((task) => task.startSuggested))
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        '建议安排可在详情修改或清空，确认后才保存。',
                        style: TextStyle(
                          fontSize: 12,
                          color: PixelColors.muted,
                        ),
                      ),
                    ),
                  if (widget.cancellations.isNotEmpty) ...[
                    const Text(
                      '拟删除',
                      style: TextStyle(fontSize: 13, color: PixelColors.danger),
                    ),
                    for (var i = 0; i < widget.cancellations.length; i++)
                      _cancellation(i),
                  ],
                  if (widget.tasks.isNotEmpty &&
                      widget.cancellations.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('拟新增', style: TextStyle(fontSize: 13)),
                    ),
                  for (var index = 0; index < widget.tasks.length; index++)
                    Builder(
                      builder: (context) {
                        final task = widget.tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PixelSurface(
                            leftAccent: true,
                            shadow: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: CheckboxListTile(
                                key: ValueKey('confirm-task-$index'),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: _selected[index],
                                onChanged: _submitted
                                    ? null
                                    : (value) => setState(
                                        () => _selected[index] = value!,
                                      ),
                                title: Text(
                                  task.title,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  [
                                    ?task.description,
                                    [
                                      horizonLabel(task.horizon),
                                      task.category,
                                      '${task.priority.label}${task.prioritySuggested ? '（建议）' : ''}',
                                      if (task.suggestedStart case final start?)
                                        '${task.startSuggested ? '建议开始' : '开始'} ${startLabel(start, task.startPeriod)}',
                                      if (task.deadline case final date?)
                                        '截止 ${deadlineLabel(date, dateOnly: task.deadlineDateOnly, period: task.deadlinePeriod)}',
                                    ].join(' · '),
                                  ].join('\n'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: PixelColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PixelButton(
              key: const ValueKey('confirm-save-tasks'),
              onPressed:
                  (count == 0 && deleteIds.isEmpty) || !resolved || _submitted
                  ? null
                  : () {
                      if (_submitted) return;
                      _submitted = true;
                      Navigator.of(context).pop(
                        ConfirmedExtraction(
                          tasks: [
                            for (var i = 0; i < widget.tasks.length; i++)
                              if (_selected[i]) widget.tasks[i],
                          ],
                          deleteIds: deleteIds,
                        ),
                      );
                    },
              child: Text(
                widget.cancellations.isEmpty
                    ? '保存 $count 项待办'
                    : '确认删除 ${deleteIds.length} 项，新增 $count 项',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      (count == 0 && deleteIds.isEmpty) ||
                          !resolved ||
                          _submitted
                      ? PixelColors.muted
                      : PixelColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
}
