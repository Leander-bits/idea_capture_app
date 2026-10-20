# Idea Capture — Pixel Adventure Design Specification

## Scope and sources

The pixel adventure edition replaces the old light-gray/white, rounded-card, blue-accent visual baseline. The Flutter App uses this baseline; subsequent user-approved usability changes below override the prototype layout. Preserve the Flutter route and all existing business functions/local services.

Explicit user requirements take precedence. `reference/screenshots_pixel/` controls static appearance/hierarchy/copy; `reference/figma_pixel/` and `reference/videos_pixel/` establish styles, interaction and motion. Preserve all of `reference/`, including `.figma`. Old `reference/figma/` and `reference/screenshots/` are absent from this checkout; their former specifications are superseded and must not be recreated as the visual baseline.

Inspected `src/app/App.tsx`, `src/index.css`, `src/styles/theme.css`, the empty `src/styles/fonts.css`, entry files, all 12 screenshots and both recordings. Artwork is inline SVG and animation is CSS/state-driven. No separate sprite sheets, GIF/Lottie assets, bundled fonts or sound-effect assets were found in the export.

Phone framing, fake status bar, Dynamic Island, home indicator and desktop four-phone gallery are presentation, not production widgets. The desktop-only 拾念 header does not confirm an app rename. Use actual system UI and SafeArea.

## Static reference inventory

Filenames below are relative to `reference/screenshots_pixel/`; retain original spelling.

| Files | Visible state |
| --- | --- |
| `今天界面1.png`, `今天界面2.png` | Today at 3/3 energy, unlocked badge, important-task empty state, other/completed tasks; different scroll positions |
| `完成任务时的奖励界面和可撤销提示界面.png` | Top reward, checked task and bottom six-second undo feedback together |
| `三个任务完成的奖励界面.png` | Gold-bordered reward dialog, dimmed/blurred background |
| `任务界面-今天.png`, `任务界面-近期.png`, `任务界面-以后.png` | Selected segments, pending counts, task list and add entry |
| `任务界面-展开完成.png` | Completed list expanded, checked controls and struck-through titles |
| `任务细节界面.png` | Detail metadata, first-step card, edit/delete; no bottom navigation |
| `记录界面-点击前.png`, `记录界面-点击生成代办前.png` | Both show review/ready, editable text and 生成待办; the first filename does not prove idle |
| `记录界面-点击后.png` | Recording, stop icon, 我在听。 and text area |

Idle Capture appears in `reference/videos_pixel/记录界面的像素动态特效.mp4` and source code. Counts, task copy, categories and fixed dates in references are examples, not production seeds or automatic field defaults.

## Visual language and verified tokens

Deep purple night palette, square surfaces/completion controls, visible borders, hard offset shadows, lime-green active/actions, purple pixel decorations, gold rewards and pink destructive actions. Pixel scenes depict castle/moon/mountains/adventurer/chest and a listening station. Task text uses readable Chinese system typography, not an unspecified pixel font.

Verified source values from `src/styles/theme.css`:

| Role / token | Value |
| --- | --- |
| Page / background | `#141325` |
| Main text / foreground | `#f1edff` |
| Card | `#222039` |
| Primary / primary foreground | `#c6f779` / `#18251c` |
| Selected surface / secondary | `#323e2b` |
| Muted surface / muted text | `#2b2842` / `#aaa4c4` |
| Hint surface / hint text | `#302544` / `#ddc9ff` |
| Border/input | `#45405f` |
| Game edge / hard shadow | `#706187` / `#090914` |
| Canvas / sky | `#0d0c18` / `#201b39` |
| Purple / pink / gold | `#b995f2` / `#f29ebe` / `#f5ce7d` |
| Highlight / distant / near mountains | `#9983bb` / `#3e305a` / `#635080` |
| Destructive | `#ff9cae` |
| Radius | `0` |

Read final CSS together with JSX: `.game-screen [class*="rounded"]` zeroes radius and `bg-white` becomes the dark card color. The desktop device-frame radius is not a card token. Icons have square caps/miter joins; pixel SVG uses crisp edges and pixelated rendering. The new sky gradient and limited glow are supported by source; the former blanket prohibition on gradients/illustrations is superseded.

Verified code geometry: content horizontal padding is 20 px for Today/Tasks/Detail, 24 px for Capture. Task cards use 1 px borders, 3 px offset shadows and a 3 px purple left edge. Completion controls are 22×22 px with 2 px borders inside 48×61 px tap targets. Task titles are 14 px/24 px line height, metadata 11 px. Main titles: Today 25 px, Tasks 31 px, Capture headline 27 px, Detail 25 px/1.45 line height. Bottom icons are 23 px; active tiles have green border, selected fill and 2 px shadow. These are source values, not screenshot estimates; preserve responsive constraints and accessible controls in Flutter.

Fonts use Apple system/PingFang, Hiragino Sans GB, Microsoft YaHei and sans-serif fallbacks. No font files are bundled; use available platform equivalents.

## Navigation and task behavior

Main destinations remain 今天 / 记录 / 任务, with sun/microphone/checklist icons. Selection is green in a square tile, inactive entries muted. Tasks has a separate 今天 / 近期 / 以后 switcher with sword/scroll/chest pixel icons and green selected styling. No fourth adventure tab is specified.

Today 全部 opens Tasks. Today microphone and Tasks ＋/添加待办 open Capture. Task body opens Detail; the independent square completion target completes/restores. Keep six-second undo, completed expand/collapse, recovery, counts, stable stored creation order and shared task state. Displayed pending lists sort by priority then creation order.

Detail is pushed without bottom navigation. Return/delete restores originating page, segment and scroll state. The demo always returns to Tasks: this does not supersede existing origin-aware behavior. Both Edit entries use the same flow. Code provides inline title editing and a confirmed delete dialog; retain title/description/time/group editing; priority and category are selection controls, advice is read-only.

## Today and collectible achievements

今天待办 uses one list, ordered high → medium → low, then creation order; do not repeat important tasks in a second section. Keep completed items, 全部 and Capture. Priority uses pink/gold/purple for high/medium/low plus explicit labels; other task lists and detail use the same mapping. No duration labels.

A compact 成就墙 entry replaces journey progress, energy, chest and daily-three-task rules. Fourteen crisp code-native pixel illustrations share the existing palette and square geometry: 写代码、做美食、旅游、游泳、健身、拍照、吃饭、化妆; general 生活、娱乐、运动、工作、社交; fallback 通用成就. Local matching checks activity first, general type second, fallback last. This mapping is independent of task categories and never calls a model.

Completion feedback and undo share one compact animated footer outside the scrolling viewport, with artwork, short copy and 撤销. No countdown helper copy; feedback must not cover task controls. Reduced motion retains visible feedback without animation. Any group qualifies; after six seconds finalize once per stable task ID ever. Before finalization undo/delete cancels the award. Persist pending completion timestamps across refresh. Earned achievements persist time, task ID and every-field snapshot; restore/recomplete cannot farm awards, and restore/delete cannot remove history. Never backfill old completed tasks. Wall shows all types, collection state/count, dates and linked task snapshots/details. No points, currency or daily reset.

## Capture

Header: 灵感收集站 with sparkle icon. The scene includes floating pink notes, antenna/signals, waveform bars, desk/files and grid. Recorder is a 110×110 px square purple control with border, hard shadow and decorative sparks.

| State | Confirmed copy/control |
| --- | --- |
| Idle (code + video) | 有什么想法？ / 不用组织语言，想到什么就说什么。 / microphone / 轻点开始录音 |
| Recording | 我在听。 / 说完后，轻点结束 / stop square / 正在记录; text area |
| Review | 想法，接住了。 / 确认一下，把它变成待办 / microphone / 再记一个想法; editable text and 生成待办 |

Remove AI自动整理和分类, 本机转写，可回放并修改文字 and 转写完成，可修改文字; retain all transcription, playback, editing and error/retry functions. The prototype's 预览中可使用文字记录 explains simulated input; do not copy it as replacement messaging for working recording/transcription.

Preserve microphone permission, playback, re-record cleanup, stop/release on leaving, automatic SenseVoice transcription, editing, status/errors/retry and stale-result guards. Preserve generation from edited text, empty-input blocking, multi-task confirmation, cancellation proposals and single-task detail navigation. Even one task with an AI-suggested schedule requires confirmation before saving; cancellation preserves the input and writes nothing. Fake demo task creation (fallback title/cloned fields and redirect to Tasks) is not production behavior. New pixel layouts for working loading/error/playback/confirmation states are not supplied.

## Tasks and Detail

Tasks has a gold scroll beside 任务, square plus, three segments, count, bordered list, 添加待办 and completed section. Task rows include category pixel icon and category/time metadata. Source maps 工作 to sword, 健康 to heart, all others to scroll; the accepted five categories are 工作、生活、健康、学习、其他. Migrate 运动→健康, 项目→工作, 旅游/社交→生活, unknown→其他; achievement artwork remains independent.

Detail uses green Back/Edit, square completion and large title. Display actual optional description/source. Metadata is a square bordered card with purple icons/separators and right-aligned values. Screenshot shows 分类、优先级、开始时间; preserve independent editable deadline/start and date-period precision. Priority/category use selectors. Remove redundant clearing helper paragraphs, but provide explicit clear actions.

建议的第一步 is a bordered purple card with purple left accent, green arrow, action and separated muted reason. Display stored optional read-only content; remove repeated voice/ordering explanations above it. First step is one simple concrete low-burden action, reason one sentence about the actual task benefit/problem/necessity. No arbitrary duration or morning advice fallback. No external action is evidenced. Edit/Delete are full-width bordered surfaces with green/pink text. Code's delete dialog asks 删除这项任务？ and offers 取消 / 删除.

## Motion evidence and timings

Both MP4 timelines were visually sampled: `完成三个任务的奖励动态特效.mp4` is approximately 16.03 s; `记录界面的像素动态特效.mp4` approximately 3.63 s. Capture clip shows idle decoration, not live recording or measured audio levels. Timings below are historical reference behavior from CSS/state code, not current energy/chest requirements or clip duration estimates.

| Motion | Verified source behavior |
| --- | --- |
| Button press | 2 px diagonal shift, transform/background transition 0.12 s |
| Energy charge | 0.35 s, `steps(4)` |
| Adventurer advance | 0.75 s, `steps(12, end)`, four energy positions |
| Walk / idle | 0.15 s `steps(2)` repeated five times / 1.8 s `steps(2)` loop |
| Chest / treasure | 0.55 s `steps(5)` after 0.8 s / 0.65 s `steps(6)` after 1.1 s |
| Full reward | Dialog opens 1.8 s after energy reaches three; dismissal button |
| Small reward | Removed after 3.5 s; appearance 0.35 s `steps(5)`; icon 0.7 s `steps(4)` repeated three times |
| Particles | 1.2 s `steps(8)`, twice, staggered delays |
| Capture notes / spark | 3 s `steps(6)`, 4 px float / 3 s `steps(3)` |
| Capture antenna/signals/bars | Beat 1.6 s idle, 0.8 s listening, stepped opacity/scale with phase offsets |
| Scene stars | 3 s `steps(2)` loop |

Illustrative waveform bars are not a microphone amplitude meter. Reduced-motion CSS suppresses transitions/loops/particles while retaining visible accessible feedback. Energy/chest timings are historical and no longer implemented. Preserve equivalent accessible state feedback in Flutter. No separate sound/haptic assets/specification were found; videos were inspected visually, so audio-track/sound-cue behavior is unconfirmed.

## Business requirements preserved

- Stable-ID shared task state; local persistence of all fields/completion/order; normal startup empty, isolated examples.
- Local Chinese SenseVoiceSmall/FSMN-VAD, ≤30-second segments without a total-duration cap, automatic editable transcription/retry.
- Configurable Ollama, default `qwen3.5:4b`, thinking off, JSON Schema/server validation, evidence/deduplication, device time/timezone and single/multiple-task workflows.
- Existing-ID cancellation plus additions, ambiguous selection, confirmation before mutation, cancellation without changes and duplicate prevention.
- Categories 工作、生活、健康、学习、其他; migrate legacy 运动→健康, 项目→工作, 旅游/社交→生活, unknown→其他; high/medium/low, default medium, legacy 普通 migration. Explicit importance wins; reasonable inferred priorities are allowed without fabricated source evidence and are marked prioritySuggested/建议.
- Independent editable/clearable/persisted start/deadline: date-only `YYYY-MM-DD`, date plus optional 上午/中午/下午/晚上, or explicit offset-aware minute time. User-specified times preserve source precision; never invent deadlines or facts. For unspecified starts, propose future dates or optional periods, considering device time and existing arrangements. Do not generate clocks without a basis or space tasks at fixed 30-minute intervals. Obligations precede leisure wishes at equivalent importance; must does not by itself mean high priority. Wishes can span today/recent/later. Missing durations and end times prevent any claim of conflict-free availability. Persist startSuggested; label 建议 in confirmation, rows and detail. Editing/clearing the time removes the suggestion marker. Legacy tasks default to non-suggested.
- Device-local grouping: start first, deadline otherwise; past/today → 今天, tomorrow through +3 inclusive → 近期, +4 onward → 以后. Manual group wins, undated/completed groups unchanged; refresh startup/foreground/midnight without LLM. Only deadline expiry is overdue; date-only after day end, periods do not imply arbitrary clocks.
- Optional read-only/persisted first-step action/reason; no additional tasks or bulk generation for old tasks.
- Real recording/playback/permissions/cleanup; Web/Android/iOS and trusted same-origin LAN HTTPS. No new cloud deployment/provider.

## Private-assistant extraction and confirmation

Ignore oral fillers/repetition; retain actual action intent and associated barriers in descriptions. 没动力、懒、太远、耗时 are barriers, not cancellations. Pure emotion creates no task and does not authorize invented coping actions. Only explicit cancellation proposes removal of matched unfinished IDs; replacement sentences must retain both deletion and positive addition. Confirmation is required before mutation.

Suggest one concrete low-burden action, preferably immediately startable, and one concise reason about completing the task’s benefit, problem solved or reasonable necessity. Do not just explain why the first step is easy. No shame, invented consequences, empty encouragement or leisure obligations; address 你, not technical user labels. Lazy/lack of motivation does not imply low priority or cancellation. Never encode 60%/40% as facts or UI. Explicit importance takes priority over inferred recommendations; never fabricate quotation evidence for a recommendation. Explicit dates/periods/clocks remain independent of deadlines. Ambiguous 周天/周末 hesitation must not be copied onto every task. Unknown habits, location and duration are not facts. Suggested future dates/periods are editable/clearable, distinct from user-specified times. Any inferred priority or start requires confirmation even for a single task. Preserve explicit high/medium/low unchanged; break equivalent-priority ties by obligation before wish. Brief recommendation reasons appear as 建议理由 in existing descriptions and confirmation, persist with descriptions, and are not source evidence. All proposed ordering/timing remains a suggestion; no guarantee of free intervals without durations/end times. Old data defaults both suggestion flags to false; all fields persist normally after confirmation.

The usability regression quote expresses four intents: 写代码、出去吃好吃的、化妆拍照、打扫房间. Preserve lack of motivation, distance/time and laziness as descriptions; 化妆拍照 may remain one combined task. A suggested arrangement is not a commitment or an inferred deadline.

## Pending decisions and conflicts

1. **Historical reference differences:** old energy/chest and seven-category expectations are superseded by the accepted collectible/five-category rules; original reference files remain intact.
2. **Missing working-state visuals:** full edit form, deadline/date-period editing, overdue display, permission/transcription/generation/retry/playback and cancellation/multi-task confirmations need pixel layouts while retaining existing functionality.
3. **Capture filename conflict:** 点击前 shows review; use code/video for idle rather than inventing another state.
4. **Demo content/navigation:** fixed date, cloned descriptions/duration advice, simulated creation and always returning to Tasks cannot override actual-field and origin-aware business behavior.
5. **Brand/media:** desktop-only 拾念 does not authorize renaming; no separate fonts/sprites/sounds were supplied, and sound/haptic behavior remains unconfirmed.

## Reuse, responsiveness and validation

Reusable elements: pixel theme, bordered surface/action, completion target, category icon, task row/group, nav tile, horizon switcher, completed section, undo, Capture/text controls, metadata/hint and themed existing confirmation dialogs. Achievements reuse pixel surfaces, stepped completion feedback and new code-native reward artwork under the collectible rules above.

Use responsive constraints/scrolling rather than screenshot coordinates. Preserve keyboard access, list position, text wrapping/enlargement, semantics, contrast and reduced motion. Decoration must not cover content, actions or undo feedback.

UI validation compares the pixel styling and relevant motion while accounting for the intentionally compact Today layout, and checks retained business flows. Report runtime/device checks separately.
