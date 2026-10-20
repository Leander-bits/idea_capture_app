# Idea Capture — Agent Instructions

## Product and scope

Build Idea Capture, a Flutter app that turns spoken thoughts into clear next actions. Core principle: Capture first. Organize automatically. Execute clearly.

Read `README.md` and `docs/DESIGN.md` before implementation. The current design baseline is the pixel adventure edition. Preserve all existing business functionality during visual changes; the original mock-only milestone is no longer the implementation baseline. README aspirations do not authorize removing implemented features.

Implement only the current explicitly authorized scope. Authentication, notifications, calendar integration and hardware remain future work unless explicitly requested.

## Repository and reference authority

- `app/`: production Flutter/Dart app.
- `backend/`: existing local FastAPI, SenseVoice/FSMN-VAD and Ollama services.
- `reference/figma_pixel/`: current Figma source, styles and inline SVG artwork, including hidden folders.
- `reference/screenshots_pixel/`: current approved static visuals.
- `reference/videos_pixel/`: current interaction/animation recordings.
- `reference/figma/` and `reference/screenshots/`: historical reference locations, absent from the current checkout; no longer the visual baseline.
- `docs/DESIGN.md`: current design specification and open questions.
- `README.md`: product purpose, features, design overview and hardware vision.

Paths are relative to the repository root. Never modify `reference/` without explicit authorization. Preserve every supplied export and hidden folder, especially `reference/figma_pixel/.figma`. Do not recreate absent historical references or convert production Flutter code to React.

Priority: explicit user requirements and accepted business rules first; pixel screenshots for static appearance/copy; pixel source for exact styles/interaction logic and recordings for observed motion/sequence; design document; clearly stated necessary assumptions. Document source/recording disagreements rather than silently inventing behavior.

Read `src/app/App.tsx`, `src/index.css` and `src/styles/theme.css` together. CSS overrides old rounded/white JSX classes. Extract verified tokens instead of guessing measurements from screenshots. Do not reproduce phone bezels, Dynamic Island, fake status bars, home indicators, the desktop multi-phone gallery or recorded pointer. Use system UI and SafeArea.

## Screens and interaction

- Today: 今天待办, one priority-sorted list, compact achievement-wall entry, completed tasks, six-second undo, restoration, 全部 and voice shortcut. The source journey/energy/chest is superseded.
- Capture: 灵感收集站; idle, recording and review, plus existing real transcription/generation/playback/loading/error/retry states even where references omit them.
- Tasks: 今天 / 近期 / 以后, counts, task list, completed expand/collapse and Capture entry points.
- Task Detail: separate route without bottom navigation; actual title/description/source, completion, metadata, independent start/deadline, first-step action/reason, edit and confirmed deletion.

Completion control and task body are independent tap targets. Preserve originating page/tab/segment, expansion state and scroll position on return/deletion. Both detail edit entries use the same flow. The demo's always-return-to-Tasks shortcut does not replace origin-aware navigation.

Game feedback must preserve completion/undo/restoration/confirmation semantics. Collectible achievements replace daily three-task progress, energy and chest rules. Use independent local activity → general type → fallback matching; no additional LLM call. Finalize after six seconds, once per task ID ever, persist award time and complete task snapshot; restoration/deletion never removes earned history. Do not backfill old completed tasks. Persist pending completion times so refresh cannot lose new awards or restart their undo window.

## Existing business invariants

- One shared task store with stable IDs. Persist all fields, completion and order after creation/edit/completion/restore/delete. Normal first startup is empty; example data stays in isolated mock mode.
- Real recording: microphone authorization, start/stop/re-record, playback, old-file cleanup, stopping/releasing on page leave and Chinese failure messages. Keep Web/Android/iOS support and trusted HTTPS same-origin Web preview.
- Local Chinese SenseVoiceSmall with FSMN-VAD: CPU-first, model loaded once, each segment at most 30 seconds without limiting total recording to 30 seconds. Automatic transcription, editable output, preserved audio on failure/retry, no duplicate requests or stale result overwrite.
- Configurable local Ollama model/address, default `qwen3.5:4b`, thinking disabled; JSON Schema/backend validation, device time/timezone, evidence and deduplication. Empty text cannot generate; no tasks returns an empty list. Preserve source text on failure.
- Single created task opens detail; multiple tasks require confirmation. Explicit cancellation uses existing unfinished task IDs; show deletions/additions, disambiguate matches and save only after confirmation. Cancellation changes no data; prevent duplicate creation.
- Categories exactly 工作、生活、健康、学习、其他. Migrate 运动→健康, 项目→工作, 旅游/社交→生活, unknown→其他. Rewards have their own taxonomy. Priority `high/medium/low` maps to 高/中/低优先级, default medium; migrate old 普通. Display high→medium→low, creation order within ties, with distinct colors and text. Edit priority/category using selectors.
- Reuse `suggestedStart` for start time, independent of deadline. Date-only is `YYYY-MM-DD`; explicit clock is offset-aware minute precision. Optional 上午/中午/下午/晚上 associate independently with start/deadline dates. Never invent clocks or copy request time into task time. Keep editing, clearing and storage compatibility.
- Automatic grouping uses device-local start date, deadline otherwise: past/today → 今天, tomorrow through +3 inclusive → 近期, +4 onward → 以后. Manual group wins; undated/finished tasks retain grouping. Refresh startup/foreground/midnight without LLM. Only expired deadlines are overdue; date-only after that day; periods imply no arbitrary clocks.
- Optional first-step action/reason are read-only and persisted. Each is one concise sentence: one concrete low-burden action; a reason about the task’s practical benefit/problem/necessity, rather than why the first step is easy. Avoid shame, invented consequences and treating leisure as obligation; address 你, not technical user labels. Do not invent facts, create extra tasks from suggestions or batch-call the model for old tasks. Display actual fields rather than demo description/time fallbacks.
- Do not reintroduce estimated-duration labels to Today; retain stored-field compatibility and all other existing features absent from pixel screenshots.

## Flutter implementation and verification

Keep production code in `app/`, reuse readable widgets and centralize verified pixel tokens in the theme. Keep existing simple architecture, services and shared state. Respect SafeArea, keyboard insets, scrolling, phone widths and enlarged text. Use Chinese platform font fallbacks; no bundled pixel font was found. Do not claim unavailable iOS fonts are installed.

UI stays in Simplified Chinese; identifiers/comments use English. Match supported pixel styling and motion, including reduced-motion behavior. Do not add unsupported game systems or dependencies.

Implement only the authorized scope. For App changes run `dart format`, `flutter analyze`, relevant existing tests and a runnable preview where available. Check overflow, keyboard/navigation, completion/undo and shared state, and compare pixel screenshots/motion. Add meaningful state/interaction tests, not tests mirroring styling.

For documentation-only work, verify reference paths, evidence and cross-document consistency; do not claim the App has changed. Report unresolved conflicts and unavailable runtime/device checks honestly.
