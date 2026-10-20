import 'package:flutter/material.dart';

import 'models/task.dart';
import 'audio/capture_audio.dart';
import 'services/transcription_service.dart';
import 'services/task_extraction_service.dart';
import 'screens/today_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/capture_screen.dart';
import 'state/task_store.dart';
import 'theme/pixel_theme.dart';
import 'widgets/bottom_navigation.dart';

class IdeaCaptureApp extends StatefulWidget {
  const IdeaCaptureApp({
    super.key,
    this.initialTasks = const [],
    this.taskStore,
    this.captureAudioFactory,
    this.transcriptionFactory,
    this.extractionFactory,
  });

  final List<Task> initialTasks;
  final TaskStore? taskStore;
  final CaptureAudio Function()? captureAudioFactory;
  final TranscriptionService Function()? transcriptionFactory;
  final TaskExtractionService Function()? extractionFactory;

  @override
  State<IdeaCaptureApp> createState() => _IdeaCaptureAppState();
}

class _IdeaCaptureAppState extends State<IdeaCaptureApp>
    with WidgetsBindingObserver {
  late final _store = widget.taskStore ?? TaskStore(widget.initialTasks);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _store.startDateUpdates();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _store.refreshDates();
      _store.startDateUpdates();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '拾念',
    debugShowCheckedModeBanner: false,
    theme: PixelTheme.dark,
    home: _AppShell(
      store: _store,
      captureAudioFactory: widget.captureAudioFactory,
      transcriptionFactory: widget.transcriptionFactory,
      extractionFactory: widget.extractionFactory,
    ),
  );
}

class _AppShell extends StatefulWidget {
  const _AppShell({
    required this.store,
    this.captureAudioFactory,
    this.transcriptionFactory,
    this.extractionFactory,
  });

  final TaskStore store;
  final CaptureAudio Function()? captureAudioFactory;
  final TranscriptionService Function()? transcriptionFactory;
  final TaskExtractionService Function()? extractionFactory;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  AppDestination _selected = AppDestination.today;

  void _select(AppDestination destination) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selected = destination);
  }

  void _openTask(Task task) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/task/${task.id}'),
        builder: (_) => TaskDetailScreen(store: widget.store, taskId: task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PixelColors.background,
    bottomNavigationBar: AppBottomNavigation(
      selected: _selected,
      pixel: true,
      onSelected: _select,
    ),
    body: IndexedStack(
      index: _selected.index,
      children: [
        TickerMode(
          enabled: _selected == AppDestination.today,
          child: TodayScreen(
            active: _selected == AppDestination.today,
            store: widget.store,
            onShowTasks: () => _select(AppDestination.tasks),
            onOpenTask: _openTask,
            onShowCapture: () => _select(AppDestination.capture),
          ),
        ),
        TickerMode(
          enabled: _selected == AppDestination.capture,
          child: CaptureScreen(
            store: widget.store,
            onGenerated: _openTask,
            active: _selected == AppDestination.capture,
            audioFactory: widget.captureAudioFactory,
            transcriptionFactory: widget.transcriptionFactory,
            extractionFactory: widget.extractionFactory,
          ),
        ),
        TasksScreen(
          store: widget.store,
          onOpenTask: _openTask,
          onShowCapture: () => _select(AppDestination.capture),
        ),
      ],
    ),
  );
}
