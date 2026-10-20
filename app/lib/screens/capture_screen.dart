import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../audio/capture_audio.dart';
import '../models/task.dart';
import '../models/extraction_plan.dart';
import '../services/task_extraction_service.dart';
import '../widgets/task_confirmation.dart';
import '../state/task_store.dart';
import '../services/transcription_service.dart';
import '../state/transcription_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel/pixel_components.dart';
import '../widgets/pixel/pixel_capture_scene.dart';
import '../widgets/pixel/pixel_status.dart';
import '../widgets/capture_control.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    super.key,
    required this.store,
    required this.onGenerated,
    this.active = true,
    this.audioFactory,
    this.transcriptionFactory,
    this.extractionFactory,
  });

  final TaskStore store;
  final ValueChanged<Task> onGenerated;
  final bool active;
  final CaptureAudio Function()? audioFactory;
  final TranscriptionService Function()? transcriptionFactory;
  final TaskExtractionService Function()? extractionFactory;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  late final CaptureAudio _audio;
  late final TranscriptionState _transcription;
  late final TaskExtractionService _extraction;
  String? _generationMessage;
  bool _generationFailed = false;
  int _generationRevision = 0;
  int _textRevision = 0;
  int _transcriptionTextRevision = 0;
  String? _appliedTranscript;
  bool _manualText = false;
  CapturePhase get _phase => _audio.phase;
  bool _generating = false;
  bool _recordingOperation = false;
  bool _startingRecording = false;
  String? get _transcriptionMessage => switch (_transcription.status) {
    TranscriptionStatus.running => '正在转写…',
    TranscriptionStatus.complete =>
      (_transcription.text?.isEmpty ?? true) ? '未识别到语音，可重新录制或填写文字。' : null,
    TranscriptionStatus.failed => _transcription.error,
    TranscriptionStatus.idle => null,
  };
  final _text = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _audio = widget.audioFactory?.call() ?? CaptureAudio();
    _transcription = TranscriptionState(
      widget.transcriptionFactory?.call() ?? LocalTranscriptionService(),
    );
    _extraction =
        widget.extractionFactory?.call() ?? LocalTaskExtractionService();
    _transcription.addListener(_onTranscription);
    _audio.addListener(_refresh);
    _audio.setActive(widget.active);
    WidgetsBinding.instance.addObserver(this);
  }

  void _refresh() {
    if (!_generating) {
      _transcription.setRecording(_startingRecording ? null : _audio.recording);
    }
    if (mounted) setState(() {});
  }

  void _onTranscription() {
    if (!mounted) return;
    if (_transcription.status == TranscriptionStatus.running) {
      _transcriptionTextRevision = _textRevision;
      _appliedTranscript = null;
    } else if (_transcription.status == TranscriptionStatus.complete &&
        _appliedTranscript == null &&
        !_generating &&
        !_manualText &&
        _textRevision == _transcriptionTextRevision) {
      _appliedTranscript = _transcription.text;
      _text.text = _transcription.text ?? '';
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(CaptureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _audio.setActive(widget.active);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _audio.setActive(widget.active);
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _audio.setActive(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audio.removeListener(_refresh);
    _transcription.removeListener(_onTranscription);
    _transcription.dispose();
    _generationRevision++;
    _extraction.dispose();
    _audio.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _record() async {
    if (_audio.busy || _generating || _recordingOperation) return;
    _recordingOperation = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final starting = _phase != CapturePhase.listening;
    _startingRecording = starting;
    if (starting) _transcription.setRecording(null);
    await _audio.record();
    _recordingOperation = false;
    _startingRecording = false;
    if (!mounted) return;
    if (starting && _phase == CapturePhase.listening) {
      _text.clear();
      _manualText = false;
      _generationMessage = null;
      _generationFailed = false;
    }
    _refresh();
  }

  Future<void> _generate() async {
    if (_audio.busy ||
        _generating ||
        _phase != CapturePhase.ready ||
        _text.text.trim().isEmpty) {
      return;
    }
    final revision = ++_generationRevision;
    final textRevision = _textRevision;
    final input = _text.text.trim();
    final elapsed = Stopwatch()..start();
    Map<String, dynamic> timings = {};
    var reported = false;
    void reportReadyDuration() {
      if (reported) return;
      reported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint(
          'Extraction end-to-end: ${jsonEncode({...timings, 'button_to_result_ms': elapsed.elapsedMicroseconds / 1000})}',
        );
      });
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _generating = true;
      _generationMessage = null;
      _generationFailed = false;
    });
    try {
      final existingTasks = widget.store.tasks
          .where((task) => !task.done)
          .toList();
      final plan = await _extraction.extract(
        input,
        existingTasks: existingTasks,
      );
      timings = plan.timings;
      var drafts = plan.tasks;
      var deleteIds = <String>[];
      if (!mounted || revision != _generationRevision) {
        return;
      }
      if (_textRevision != textRevision) {
        _generationMessage = '文字已修改，请重新生成。';
        return;
      }
      if (plan.isEmpty) {
        _generationMessage = '未发现待办，可以修改文字后重试。';
        return;
      }
      final multiple = drafts.length > 1;
      final needsConfirmation =
          multiple ||
          plan.cancellations.isNotEmpty ||
          drafts.any((task) => task.startSuggested || task.prioritySuggested);
      if (needsConfirmation) {
        reportReadyDuration();
        final selected = await showModalBottomSheet<ConfirmedExtraction>(
          context: context,
          isScrollControlled: true,
          backgroundColor: PixelColors.card,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: PixelColors.purple, width: 2),
          ),
          builder: (context) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  (MediaQuery.sizeOf(context).height -
                          MediaQuery.viewInsetsOf(context).bottom -
                          MediaQuery.paddingOf(context).vertical -
                          16)
                      .clamp(0.0, MediaQuery.sizeOf(context).height * .8),
            ),
            child: TaskConfirmation(
              tasks: drafts,
              cancellations: plan.cancellations,
              candidates: existingTasks,
            ),
          ),
        );
        if (!mounted || revision != _generationRevision || selected == null) {
          return;
        }
        if (_textRevision != textRevision) {
          _generationMessage = '文字已修改，请重新生成。';
          return;
        }
        drafts = selected.tasks;
        deleteIds = selected.deleteIds;
      }
      final created = widget.store.applyExtraction(
        drafts,
        deleteIds: deleteIds,
        expectedTasks: existingTasks,
      );
      if (created.isEmpty && deleteIds.isEmpty) return;
      // Commit once, then consume the input before exposing the next action.
      _text.clear();
      _manualText = false;
      _transcription.setRecording(null);
      await _audio.clear();
      if (!mounted) return;
      if (_scroll.hasClients) _scroll.jumpTo(0);
      if (created.length == 1 && deleteIds.isEmpty) {
        widget.onGenerated(created.single);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleteIds.isEmpty
                  ? '已添加 ${created.length} 项待办'
                  : '已删除 ${deleteIds.length} 项，新增 ${created.length} 项待办',
            ),
          ),
        );
      }
      reportReadyDuration();
    } catch (error) {
      if (mounted && revision == _generationRevision) {
        _generationFailed = true;
        _generationMessage = error is TaskExtractionException
            ? error.message
            : '提取失败，文字和录音已保留，请重试。';
      }
    } finally {
      if (mounted && revision == _generationRevision) {
        setState(() => _generating = false);
        reportReadyDuration();
      }
    }
  }

  Widget _content() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        switch (_phase) {
          CapturePhase.idle => '有什么想法？',
          CapturePhase.listening => '我在听。',
          CapturePhase.ready => '想法，接住了。',
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      Text(
        switch (_phase) {
          CapturePhase.idle => '不用组织语言，想到什么就说什么。',
          CapturePhase.listening => '说完后，轻点结束',
          CapturePhase.ready => '确认一下，把它变成待办',
        },
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: PixelColors.muted),
      ),
      const SizedBox(height: 48),
      CaptureControl(
        listening: _phase == CapturePhase.listening,
        active: _phase != CapturePhase.idle,
        onPressed: _audio.busy || _generating ? null : _record,
      ),
      const SizedBox(height: 20),
      Text(switch (_phase) {
        CapturePhase.idle => '轻点开始录音',
        CapturePhase.listening => '正在记录',
        CapturePhase.ready => '再记一个想法',
      }, style: const TextStyle(fontSize: 12, color: PixelColors.muted)),
      if (_audio.error case final message?) ...[
        const SizedBox(height: 12),
        PixelStatusMessage(message, error: true),
      ],
      if (_phase == CapturePhase.ready && _audio.recording != null) ...[
        const SizedBox(height: 12),
        PixelButton(
          key: const ValueKey('capture-playback'),
          onPressed: _audio.busy ? null : _audio.playback,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _audio.playing ? Icons.stop : Icons.play_arrow,
                size: 20,
                color: PixelColors.primary,
              ),
              const SizedBox(width: 6),
              Text(_audio.playing ? '停止回放' : '回放录音'),
            ],
          ),
        ),
        if (_transcriptionMessage case final message?) ...[
          const SizedBox(height: 10),
          PixelStatusMessage(
            message,
            error: _transcription.status == TranscriptionStatus.failed,
            busy: _transcription.status == TranscriptionStatus.running,
          ),
        ],
        if (_transcription.status == TranscriptionStatus.failed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PixelButton(
              key: const ValueKey('capture-retry-transcription'),
              onPressed: _transcription.retry,
              child: const Text('重试转写'),
            ),
          ),
      ],
      if (_phase != CapturePhase.idle) ...[
        const SizedBox(height: 24),
        SizedBox(
          height: 96,
          child: TextField(
            key: const ValueKey('capture-text'),
            controller: _text,
            expands: true,
            minLines: null,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            onChanged: (_) => setState(() {
              _textRevision++;
              _manualText = true;
              _generationMessage = null;
              _generationFailed = false;
            }),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '把刚才的想法写在这里…',
              hintStyle: const TextStyle(color: PixelColors.muted),
              filled: true,
              fillColor: PixelColors.card,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: const BorderSide(color: PixelColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: const BorderSide(color: PixelColors.primary),
              ),
            ),
          ),
        ),
        if (_phase == CapturePhase.listening) ...[
          const SizedBox(height: 8),
          const Text(
            '停止录音后自动转为文字',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: PixelColors.muted),
          ),
        ],
        if (_phase == CapturePhase.ready) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PixelButton(
              key: const ValueKey('capture-generate'),
              color: PixelColors.secondary,
              onPressed: _text.text.trim().isEmpty || _audio.busy || _generating
                  ? null
                  : _generate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_generating) ...[
                    const PixelBusyDots(),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      _generating
                          ? '正在提取…'
                          : _generationFailed
                          ? '重试生成'
                          : '生成待办',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            _text.text.trim().isEmpty ||
                                _audio.busy ||
                                _generating
                            ? PixelColors.muted
                            : PixelColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_generationMessage case final message?) ...[
            const SizedBox(height: 8),
            PixelStatusMessage(message, error: _generationFailed),
          ],
        ],
      ],
    ],
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const PageStorageKey('capture-scroll'),
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 18,
                      color: PixelColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '灵感收集站',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PixelCaptureScene(listening: _phase == CapturePhase.listening),
                ConstrainedBox(
                  // Let recording/status controls grow instead of fixing their
                  // intrinsic height; the outer viewport handles scrolling.
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 248).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: _content()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
