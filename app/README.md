# Idea Capture Flutter app

This milestone implements Today, Tasks, Task Detail, and microphone Capture. Normal startup uses an
empty task store on first launch and restores locally saved tasks on later launches.
Seven example tasks remain isolated in
`lib/data/mock_tasks.dart` for tests and the explicit `lib/main_mock.dart` preview.
Chinese file transcription uses the local FastAPI/FunASR backend in `../backend/`.
Task extraction defaults to local Ollama `qwen3.5:4b` with thinking disabled;
`OLLAMA_MODEL` can override it at backend startup. No cloud API is connected. Normal startup uses shared_preferences
with an ordered, versioned JSON snapshot of every task field and the ID counter.
Creation, editing, completion, restoration, and deletion enqueue saves in order.
Completion and its pending timestamp are saved immediately. Reopening preserves the remaining six-second undo window, then finalizes the collectible once per task ID. Earned time, complete task snapshot and deduplication persist; restoring/deleting tasks never removes earned history. Legacy completed tasks receive no automatic award. Missing storage starts empty; invalid
stored data fails restoration rather than silently replacing it with empty data.
The example entry point and widget tests use memory only and never access normal
task storage. Web previews retain data within the same browser profile and origin.

Completion updates state immediately. A checked task stays in its original row
for six seconds with undo feedback, then appears in the expandable completed
section. Restoring keeps the original task ordering. Multiple completions have
independent timers. The latest pending completion is shown in the undo notice.

Today and Tasks share one task store and bottom navigation. Today's All entry
opens Tasks with its previous segment, matching the Figma behavior. Each page
retains its expansion and scroll state; Tasks also retains each segment's scroll
position. Completed tasks are global across segments, matching the screenshots.
Task durations are never rendered. Today and Tasks use high→medium→low order with creation-order ties and distinct priority colors plus labels. Today exposes a 14-type achievement wall, with collection counts, award dates and immutable task history; activity matching is local and independent of the five task categories.

Task bodies push a detail route with no bottom navigation. Completion circles
remain separate controls. Detail displays only the selected task's known fields;
the repeated voice hint is omitted. Only the website example has
the approved description, first step, and reason. No generic suggestions are
generated for the other examples.

Both edit entries use the same inline editor for title, independent start/deadline
dates and periods, manual date grouping, category and priority selectors. First-step action/reason remain read-only. Confirming with Done or Save
updates the shared state; blank titles are rejected. Returning before saving
discards the draft. This small validation and save behavior is an implementation
choice extending the reference's title-only inline editing. Deletion uses the
reference confirmation wording. Back and deletion pop the route to its actual
source, preserving tab, segment, expansion, and scroll state. Source-list scroll
offsets can clamp naturally when deleting items shortens a list.

The Record tab, Today microphone, and both Tasks add entries open Capture. Its
idle, listening, and ready states use record for microphone permission and WAV
recording on Web, Android, and iOS. audioplayers handles replay. Record Again
stops replay, deletes the old temporary file or revokes its browser blob URL,
and starts a fresh recording. Failed permission/start/stop/playback operations
show short Chinese feedback. Audio is a temporary draft, not saved task data.
Stopping automatically submits the recording to local SenseVoiceSmall/FSMN-VAD.
The editable field receives the result unless the user has manually edited it.
Capture shows progress and offers retry after failure, retaining the audio.
Requests are cancelled and their results invalidated when a recording is replaced
or a task is generated. Multiple retries cannot submit the same request concurrently.
The provider is isolated behind `TranscriptionService`; model inference remains in
the local Python process. Set `TRANSCRIPTION_BASE_URL` through `--dart-define`;
the default is `http://127.0.0.1:8000`. See the backend README for setup.
Switching tabs stops recording/replay and releases the recorder/player while preserving
the stopped draft and typed text. Backgrounding also stops capture; permission
requests that finish after leaving cannot start recording on the hidden page.
Generating a task and disposing Capture clear its audio draft.

Generate extracts one or more tasks from the current edited text through the local
backend, including five allowed categories (工作、生活、健康、学习、其他), high/medium/low priority, optional
start/deadline and first-step advice. Date-only values never acquire invented clocks;
periods remain separate from explicit time. Single tasks open detail; multiple tasks
and explicit old-task cancellations require confirmation. Cancellation matches use
existing unfinished IDs; ambiguity requires selection, and dismissing saves nothing.
Successful generation consumes the input once. Failure retains text/audio for retry.
Empty input disables generation. No manual creation form is included.

Storage v7 reads v1–v6; independent date/period/clock precision, advice and manual
group overrides persist. Old midnight deadlines keep their former date-only meaning
because older storage had no precision flag. The store updates date groups locally
at startup, foreground resume and every minute, including midnight: past/today,
+1 to +3 inclusive, and +4 onwards. Start date wins over deadline; no date preserves
the existing group; manual groups and completed tasks do not change. Only elapsed
deadlines display 已逾期; date-only/period deadlines expire when that local day ends.
No model is called to regroup or enrich old tasks.

Capture follows the pixel screenshots and source values. Redundant AI/transcription-completed copy is removed while retaining all related functions. The mock
greeting follows the screenshots; empty startup has neutral empty-state copy.

Design values come from `../reference/figma_pixel/src/app/App.tsx` and its theme CSS;
approved screenshots control the visible layout. Native system insets replace
the reference phone framing. Code-native crisp pixel art renders reward types without new dependencies. Chinese fonts use platform fallbacks.

Run from this directory:

For a Windows/iPhone Safari preview on the same Wi-Fi, use the local HTTPS
gateway and certificate steps in [docs/IPHONE_SAFARI.md](../docs/IPHONE_SAFARI.md).
The gateway Web build uses `TRANSCRIPTION_BASE_URL=same-origin`; normal loopback
previews and native builds keep their existing backend URL configuration.

```powershell
flutter pub get
flutter run -d chrome
```

Preview the approved examples explicitly:

```powershell
flutter run -d chrome -t lib/main_mock.dart
```

The initial implementation environment uses a temporary SDK, without changing PATH:

```powershell
& C:\Temp\idea_capture_flutter_sdk\bin\flutter.bat run -d chrome
```

Checks:

```powershell
dart format lib test
flutter analyze
flutter test
```
