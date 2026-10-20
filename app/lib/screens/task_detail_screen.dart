import 'package:flutter/material.dart';

import '../models/task.dart';
import '../models/task_draft.dart';
import '../state/task_store.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel/pixel_components.dart';
import '../widgets/pixel/pixel_task_components.dart';
import '../widgets/detail_components.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.store,
    required this.taskId,
  });

  final TaskStore store;
  final String taskId;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _scrollController = ScrollController();
  final _startController = TextEditingController();
  final _deadlineController = TextEditingController();
  String? _startPeriod;
  String? _deadlinePeriod;
  TaskHorizon? _manualGroup;
  TaskPriority _priority = TaskPriority.medium;
  String _category = '其他';
  final _titleFocus = FocusNode();
  bool _editing = false;
  String? _titleError;
  String? _startError;

  static ThemeData get _detailTheme => PixelTheme.dark.copyWith(
    inputDecorationTheme: const InputDecorationThemeData(
      filled: true,
      fillColor: PixelColors.sky,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: TextStyle(fontSize: 13, color: PixelColors.muted),
      hintStyle: TextStyle(fontSize: 12, color: PixelColors.muted),
      helperStyle: TextStyle(
        fontSize: 11,
        height: 1.6,
        color: PixelColors.muted,
      ),
      errorStyle: TextStyle(
        fontSize: 11,
        height: 1.6,
        color: PixelColors.danger,
      ),
      helperMaxLines: 3,
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PixelColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PixelColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PixelColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PixelColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: PixelColors.danger, width: 2),
      ),
    ),
  );

  @override
  void dispose() {
    _titleController.dispose();
    _scrollController.dispose();
    _startController.dispose();
    _deadlineController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _edit() {
    if (_editing) {
      final original = widget.store.taskById(widget.taskId);
      if (original == null) return;
      String? start;
      String? deadline;
      try {
        final input = _startController.text.trim();
        start = input.isEmpty
            ? null
            : input == timeInput(original.suggestedStart)
            ? original.suggestedStart
            : validateStart(input);
        final endInput = _deadlineController.text.trim();
        deadline = endInput.isEmpty ? null : validateStart(endInput);
      } on FormatException {
        setState(() => _startError = '开始和截止时间请输入有效年月日，可加时分');
        _showFormTop();
        return;
      }
      if (!widget.store.editDetail(
        widget.taskId,
        _titleController.text,
        start,
        startPeriod: start != null && !start.contains('T')
            ? _startPeriod
            : null,
        deadlineValue: deadline,
        deadlinePeriod: deadline != null && !deadline.contains('T')
            ? _deadlinePeriod
            : null,
        priority: _priority,
        category: _category,
        horizon: _manualGroup,
        manualHorizon: _manualGroup != null,
        updateAll: true,
      )) {
        setState(() => _titleError = '请输入任务标题');
        _showFormTop();
        return;
      }
      _titleFocus.unfocus();
      setState(() {
        _editing = false;
        _titleError = null;
        _startError = null;
      });
      _showFormTop();
    } else {
      final task = widget.store.taskById(widget.taskId);
      if (task == null) return;
      _titleController.text = task.title;
      _startController.text = timeInput(task.suggestedStart);
      _deadlineController.text = task.deadline == null
          ? ''
          : timeInput(
              task.deadlineDateOnly
                  ? dateValue(task.deadline!.toLocal())
                  : minuteValue(task.deadline!),
            );
      _startPeriod = task.startPeriod;
      _deadlinePeriod = task.deadlinePeriod;
      _manualGroup = task.manualHorizon ? task.horizon : null;
      _priority = task.priority;
      _category = migrateCategory(task.category, task.title);
      setState(() => _editing = true);
      _titleFocus.requestFocus();
      _showFormTop();
    }
  }

  void _showFormTop() {
    if (_scrollController.hasClients) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _delete() async {
    final task = widget.store.taskById(widget.taskId);
    if (task == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: PixelColors.canvas.withValues(alpha: .8),
      builder: (context) => Theme(
        data: _detailTheme,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          shape: const RoundedRectangleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: PixelSurface(
              borderColor: PixelColors.purple,
              borderWidth: 2,
              shadow: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '删除这项任务？',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '「${task.title}」将被删除，此操作无法撤销。',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.9,
                        color: PixelColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: PixelButton(
                            onPressed: () => Navigator.pop(context, false),
                            color: PixelColors.card,
                            child: const Text(
                              '取消',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: PixelColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PixelButton(
                            key: const ValueKey('confirm-delete'),
                            onPressed: () => Navigator.pop(context, true),
                            color: PixelColors.accent,
                            borderColor: PixelColors.danger,
                            child: const Text(
                              '删除',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: PixelColors.danger),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || confirmed != true) return;
    widget.store.delete(widget.taskId);
    Navigator.of(context).pop();
  }

  static String? _present(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  Widget _metadata(Task task) {
    final rows =
        <({IconData icon, String label, String value, bool highlight})>[];
    if (_present(task.category) case final String category) {
      rows.add((
        icon: Icons.sell_outlined,
        label: '分类',
        value: category,
        highlight: false,
      ));
    }
    rows.add((
      icon: Icons.checklist_outlined,
      label: '优先级',
      value: '${task.priority.label}${task.prioritySuggested ? '（建议）' : ''}',
      highlight: true,
    ));
    if (_editing || task.suggestedStart != null) {
      rows.add((
        icon: Icons.calendar_month_outlined,
        label: task.startSuggested ? '开始时间（建议）' : '开始时间',
        value: task.suggestedStart == null
            ? ''
            : startLabel(task.suggestedStart!, task.startPeriod),
        highlight: false,
      ));
    }
    if (task.deadline case final deadline?) {
      rows.add((
        icon: Icons.event_outlined,
        label: '截止时间',
        value: deadlineLabel(
          deadline,
          dateOnly: task.deadlineDateOnly,
          period: task.deadlinePeriod,
        ),
        highlight: false,
      ));
    }
    if (task.isOverdue(widget.store.now)) {
      rows.add((
        icon: Icons.schedule,
        label: '状态',
        value: '已逾期',
        highlight: false,
      ));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: PixelSurface(
        borderColor: PixelColors.edge,
        shadow: 4,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++)
              if (!_editing ||
                  (!rows[i].label.startsWith('开始时间') &&
                      rows[i].label != '截止时间' &&
                      rows[i].label != '分类' &&
                      rows[i].label != '优先级'))
                DetailMetadataRow(
                  icon: rows[i].icon,
                  label: rows[i].label,
                  value: rows[i].value,
                  highlight: rows[i].highlight,
                  valueColor: rows[i].label == '优先级'
                      ? priorityColor(task.priority)
                      : null,
                  divider: i < rows.length - 1,
                ),
            if (_editing) ...[
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('detail-category-input'),
                  initialValue: _category,
                  isExpanded: true,
                  dropdownColor: PixelColors.card,
                  borderRadius: BorderRadius.zero,
                  decoration: const InputDecoration(labelText: '分类'),
                  items: [
                    for (final category in taskCategories)
                      DropdownMenuItem(value: category, child: Text(category)),
                  ],
                  onChanged: (value) => setState(() => _category = value!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<TaskPriority>(
                  key: const ValueKey('detail-priority-input'),
                  initialValue: _priority,
                  isExpanded: true,
                  dropdownColor: PixelColors.card,
                  borderRadius: BorderRadius.zero,
                  decoration: const InputDecoration(labelText: '优先级'),
                  items: [
                    for (final priority in TaskPriority.values)
                      DropdownMenuItem(
                        value: priority,
                        child: Text(
                          priority.label,
                          style: TextStyle(color: priorityColor(priority)),
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _priority = value!),
                ),
              ),
              _timeEditor(
                '开始时间',
                'start',
                _startController,
                _startPeriod,
                (value) => setState(() => _startPeriod = value),
              ),
              _timeEditor(
                '截止时间',
                'deadline',
                _deadlineController,
                _deadlinePeriod,
                (value) => setState(() => _deadlinePeriod = value),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<TaskHorizon>(
                  key: ValueKey('detail-group-${_manualGroup?.name ?? 'auto'}'),
                  initialValue: _manualGroup,
                  isExpanded: true,
                  dropdownColor: PixelColors.card,
                  borderRadius: BorderRadius.zero,
                  iconEnabledColor: PixelColors.purple,
                  style: const TextStyle(fontSize: 13, color: PixelColors.text),
                  decoration: const InputDecoration(labelText: '日期分组'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('自动按日期分组')),
                    for (final group in TaskHorizon.values)
                      DropdownMenuItem(
                        value: group,
                        child: Text('手动：${horizonLabel(group)}'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _manualGroup = value),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeEditor(
    String label,
    String key,
    TextEditingController controller,
    String? period,
    ValueChanged<String?> onPeriod,
  ) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        TextField(
          key: ValueKey('detail-$key-input'),
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: label,
            hintText: 'YYYY-MM-DD 或 YYYY-MM-DD HH:mm',
            hintMaxLines: 2,
            helperMaxLines: 3,
            errorMaxLines: 3,
            suffixIcon: IconButton(
              key: ValueKey('clear-$key-time'),
              tooltip: '清空$label',
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                onPeriod(null);
              },
            ),
            errorText: key == 'start' ? _startError : null,
          ),
        ),
        const SizedBox(height: 10),
        KeyedSubtree(
          key: ValueKey('detail-$key-period'),
          child: DropdownButtonFormField<String>(
            key: ValueKey('period-$key-${period ?? 'none'}'),
            initialValue: period,
            isExpanded: true,
            dropdownColor: PixelColors.card,
            borderRadius: BorderRadius.zero,
            iconEnabledColor: PixelColors.purple,
            style: const TextStyle(fontSize: 13, color: PixelColors.text),
            decoration: InputDecoration(labelText: '$label时段'),
            items: [
              const DropdownMenuItem(value: null, child: Text('不指定时段')),
              for (final value in taskPeriods)
                DropdownMenuItem(value: value, child: Text(value)),
            ],
            onChanged: onPeriod,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: _detailTheme,
    child: Scaffold(
      backgroundColor: PixelColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [PixelColors.sky, PixelColors.background],
            stops: [0, .45],
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) {
              final task = widget.store.taskById(widget.taskId);
              final pending = widget.store.latestPending;
              final step = _present(task?.firstStep);
              final reason = _present(task?.firstStepReason);
              final descriptionText = task?.description
                  ?.split('\n建议理由：')
                  .first
                  .trim();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          key: const ValueKey('detail-back'),
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          icon: const Icon(Icons.arrow_back, size: 19),
                          label: const Text('任务'),
                        ),
                        if (task != null)
                          TextButton(
                            key: const ValueKey('detail-edit-top'),
                            onPressed: _edit,
                            child: Text(
                              _editing ? '完成' : '编辑',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        if (task == null)
                          const Center(
                            child: Text(
                              '这项任务已不存在',
                              style: TextStyle(color: PixelColors.muted),
                            ),
                          )
                        else
                          ListView(
                            key: const ValueKey('detail-scroll'),
                            controller: _scrollController,
                            padding: EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              pending == null ? 20 : 120,
                            ),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                    container: true,
                                    label:
                                        '${task.done ? '恢复任务' : '完成任务'}：${task.title}',
                                    button: true,
                                    checked: task.done,
                                    onTap: () => widget.store.toggle(task.id),
                                    child: InkWell(
                                      excludeFromSemantics: true,
                                      key: const ValueKey('detail-toggle'),
                                      onTap: () => widget.store.toggle(task.id),
                                      child: SizedBox(
                                        width: 37,
                                        height: 48,
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            width: 25,
                                            height: 25,
                                            decoration: BoxDecoration(
                                              color: task.done
                                                  ? PixelColors.secondary
                                                  : null,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: PixelColors.shadow,
                                                  offset: Offset(2, 2),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: task.done
                                                    ? PixelColors.primary
                                                    : PixelColors.border,
                                                width: 2,
                                              ),
                                            ),
                                            child: task.done
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 16,
                                                    color: PixelColors.primary,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _editing
                                        ? TextField(
                                            key: const ValueKey(
                                              'detail-title-input',
                                            ),
                                            controller: _titleController,
                                            focusNode: _titleFocus,
                                            minLines: 1,
                                            maxLines: 3,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: (_) => _edit(),
                                            style: const TextStyle(
                                              fontSize: 19,
                                              color: PixelColors.text,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: '任务标题',
                                              errorText: _titleError,
                                              filled: true,
                                              fillColor: PixelColors.card,
                                            ),
                                          )
                                        : Text(
                                            task.title,
                                            style: TextStyle(
                                              fontSize: 25,
                                              height: 1.45,
                                              shadows: const [
                                                Shadow(
                                                  color: PixelColors.shadow,
                                                  offset: Offset(2, 2),
                                                ),
                                              ],
                                              fontWeight: FontWeight.w600,
                                              color: task.done
                                                  ? PixelColors.muted
                                                  : PixelColors.text,
                                              decoration: task.done
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                              if (_present(descriptionText)
                                  case final String description) ...[
                                const SizedBox(height: 20),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.9,
                                    color: PixelColors.muted,
                                  ),
                                ),
                              ],
                              _metadata(task),
                              if (step != null || reason != null) ...[
                                const SizedBox(height: 24),
                                Text(
                                  step == null ? '建议说明' : '建议的第一步',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: PixelColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                NextStepCard(step: step, reason: reason),
                              ],
                              const SizedBox(height: 20),
                              DetailAction(
                                key: const ValueKey('detail-edit-bottom'),
                                label: _editing ? '保存修改' : '编辑任务',
                                icon: _editing
                                    ? Icons.check
                                    : Icons.edit_outlined,
                                onPressed: _edit,
                              ),
                              const SizedBox(height: 12),
                              DetailAction(
                                key: const ValueKey('detail-delete'),
                                label: '删除任务',
                                icon: Icons.delete_outline,
                                onPressed: _delete,
                                destructive: true,
                              ),
                            ],
                          ),
                        if (pending != null)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: PixelUndoNotice(
                              task: pending,
                              alreadyCollected: widget.store.hasContributed(
                                pending.id,
                              ),
                              onUndo: () => widget.store.toggle(pending.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
