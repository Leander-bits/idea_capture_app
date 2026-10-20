import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'models/task.dart';
import 'data/task_storage.dart';
import 'state/task_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await TaskStore.load(PreferencesTaskStorage());
  runIdeaCapture(taskStore: store);
}

void runIdeaCapture({
  List<Task> initialTasks = const [],
  TaskStore? taskStore,
}) {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF141325),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(IdeaCaptureApp(initialTasks: initialTasks, taskStore: taskStore));
}
