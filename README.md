# Idea Capture

> Capture first. Organize automatically. Execute clearly.

Idea Capture is a planned voice-to-action mobile app for people who have many ideas, remember tasks at random moments and find it difficult to keep organizing a todo list. The project folder is `idea_capture_app`. Its current design reference is the pixel adventure Figma edition; the feature and roadmap descriptions below express product goals rather than a complete implementation-status inventory. A visual update must preserve the existing Flutter app and its local recording, transcription, extraction and task-storage workflows.

## Why I want to build this

I often have ideas while walking, commuting, working or lying in bed. Recording them in a conventional task app means opening the app, writing a title, choosing a category, deciding a time and setting a priority. By the time I do that, the thought may be gone—or I may simply postpone recording it.

Saving a thought alone is also insufficient: vague ideas accumulate, and I still have to decide how to start. I want a tool that lets me speak naturally, keeps the idea, and turns it into a manageable next action with less effort from me.

## Problems the product addresses

- Thoughts and commitments are easily forgotten.
- Manual categorization and scheduling interrupt the moment of capture.
- Large undifferentiated task lists make prioritization difficult.
- Vague tasks create hesitation because the first step is unclear.
- Long-term ideas need somewhere to live without overwhelming today.

The product aims to help users capture, organize and begin. Whether it improves execution needs to be validated with actual use.

## Product experience

The user speaks without preparing a structured sentence, reviews the transcription, and confirms task creation. Later AI functionality will propose a title, description, category, time horizon, priority, suggested start and concrete first step. Task metadata and suggested times remain editable/clearable; first-step advice stays read-only, and uncertain times must not be presented as confirmed commitments.

One recording may contain multiple tasks, an idea to keep, or a thought that needs clarification. The eventual extraction flow should handle these cases rather than force every recording into exactly one todo.

## Main features

### Today — execution

今天待办 shows one list ordered by high/medium/low priority and creation order, recoverable completed tasks, category/time and voice capture. A compact 成就墙 entry replaces daily energy/chest progress. A completion earns a locally matched collectible after six-second undo, once per task ID; the wall keeps counts, dates and task snapshots even after deletion. Estimated-duration labels are not shown.

### Capture — input

The 灵感收集站 pixel scene accompanies three reference states: idle, listening and transcript review/ready to generate. Existing real recording, playback, transcription and generation status/error/retry workflows remain supported even where the pixel references omit their visuals. Copy encourages natural speech: 不用组织语言，想到什么就说什么。 Review/edit and record-again options make transcription errors correctable.

### Tasks — organization

今天 / 近期 / 以后 groups keep current work separate from future ideas. Users can inspect tasks, mark or restore completion, view completed items, and enter tasks manually.

### Task Detail — a clear starting point

The pixel detail design includes a square completion control, title, readable description, category, priority and start time. A purple bordered 建议的第一步 card makes the task easier to begin, followed by a short reason. Edit and delete controls let users correct the system's suggestions. Keep independent editable/clearable start and deadline, title/description/group editing and category/priority selectors. First-step action and reason are read-only, concise suggestions. Categories are 工作、生活、健康、学习、其他; reward types remain independent.

Reference task text is illustrative. Render actual optional fields rather than inserting example descriptions, durations or first-step reasons. Suggested start time, deadline and estimated duration remain separate concepts in the task model.

## Design thinking

The new baseline is a dark pixel adventure: deep purple backgrounds, square bordered surfaces, hard offset shadows, lime-green actions/selection, purple scenery, gold rewards and pink destructive controls. Chinese text stays readable with system font fallbacks; no pixel font is supplied. Flutter/Dart remains the production route, with Web, Android and iOS support retained.

Today answers “What deserves my attention now?” through 今天待办 and a compact achievement-wall entry. Capture reduces input effort through 灵感收集站. Tasks keeps a broader view. Task Detail connects an intention to its first action. Pixel feedback adds a visible sense of progress without changing task data or confirmation rules.

`reference/screenshots_pixel/` controls static visuals. `reference/figma_pixel/` provides exact styles, components and interaction code; `reference/videos_pixel/` demonstrates motion and sequence. These replace the old visual references, which are absent from the current checkout. Preserve all supplied exports, including hidden `.figma` folders. Device framing and the desktop gallery are not app UI.

The source supplies stepped feedback and Capture scenery animation, including reduced-motion behavior. Accepted usability changes replace energy/chests with 14 crisp pixel achievement illustrations, local matching and historical collections. Working error/edit/confirmation surfaces reuse pixel controls. See [docs/DESIGN.md](docs/DESIGN.md) for current rules and historical motion evidence. Local task extraction defaults to configurable `qwen3.5:4b`, thinking disabled; SenseVoice transcription remains unchanged.

## Hardware concept

The long-term concept is a small recorder approximately 3–4 cm across, attachable to a phone, bag, clothing or keychain. It has one physical button: press to record, press again to stop, then transfer audio to the phone when connected.

Possible components are a microphone, microcontroller, local flash storage, Bluetooth, battery and LED or vibration feedback. These are design ideas, not finalized specifications. Size, battery life, audio transfer and offline synchronization need prototyping.

The recorder handles capture and reliable transfer; the phone or a service handles speech recognition and AI organization. Local buffering should preserve recordings while disconnected, and transfer acknowledgement should prevent lost or duplicated captures. Provide clear recording feedback and user control over audio retention and deletion.

The hardware's value is fewer steps between a thought and recording it: a reachable button can remove the need to take out, unlock and navigate a phone. Develop hardware after the software workflow has demonstrated value.

## Future intelligence

Planned capabilities include speech-to-text, structured task extraction, duration estimates, context-aware recommendations, notifications and optional calendar integration. For example, 今晚想做可乐鸡翅 could produce a cooking task and suggested ingredient checks. The system should propose prerequisites without assuming it knows what is already at home.

Calendar availability and optional user context may help propose realistic execution windows. Location-based suggestions are exploratory and require permission and a clear benefit. Avoid continuous recording; capture begins deliberately. Cloud processing and retention choices must be transparent when implemented.

## Repository layout

```text
idea_capture_app/
├── app/                      # Production Flutter application
├── backend/                  # Existing local transcription/extraction services
├── reference/
│   ├── figma_pixel/          # Current Figma export, including .figma
│   ├── screenshots_pixel/    # Current static visual references
│   └── videos_pixel/         # Current motion/interaction recordings
├── docs/
│   └── DESIGN.md
├── AGENTS.md
└── README.md
```

Open `idea_capture_app` as the folder in VS Code. Read the pixel export as a reference; keep production code in `app/`. Preserve exported contents and hidden folders without renaming or deleting them. Existing run/configuration instructions remain in `app/README.md`, `backend/README.md` and `docs/IPHONE_SAFARI.md`.

`AGENTS.md` guides Codex; `docs/DESIGN.md` specifies the approved interface.
