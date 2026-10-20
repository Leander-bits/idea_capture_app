# Local Chinese transcription and task extraction

Python 3.11+; CPU only. Install matching CPU torch/torchaudio wheels first, then
`pip install -r requirements.txt`. On Windows the current verification environment
is `.venv`, created with the available Python and its existing torch installation.

Run from `backend/`:

```powershell
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --workers 1
```

Do not add `--reload` or multiple workers: each process would load another model.
First startup downloads `iic/SenseVoiceSmall` and FSMN-VAD through ModelScope.
Subsequent starts use the local model cache. No API key is needed. Audio inference
is local; uploaded temporary files are removed after each request. Models remain
loaded until the process stops. `/health` is available after loading completes.

`POST /transcribe` accepts multipart `file` (the app's WAV recording) and returns
`text`, `duration_seconds`, and ordered `segments` with millisecond boundaries.
Audio is mixed to mono and resampled to 16 kHz. FSMN-VAD finds speech regions,
each region is bounded to at most 30 seconds, and SenseVoice recognizes every
region in order with `language="zh"` and `use_itn=True`. Tags are removed without
discarding punctuation or inserting emotion/event emoji. Total duration is not
limited to 30 seconds. The upload size limit is 256 MiB. A lock serializes inference
because the shared FunASR model configuration is mutable.

Optional environment variables: `ASR_CPU_THREADS` (default 4), `SENSEVOICE_MODEL`
and `FSMN_VAD_MODEL` (local model directories), `ASR_ALLOWED_ORIGINS` (comma-separated
extra Web origins). Loopback Web preview origins are allowed by default.

Start Flutter with `--dart-define=TRANSCRIPTION_BASE_URL=http://127.0.0.1:8000`.
For iPhone Safari on the same Wi-Fi, prefer the HTTPS same-origin gateway in
[docs/IPHONE_SAFARI.md](../docs/IPHONE_SAFARI.md); keep this backend and Ollama on
loopback. Only the gateway listens on the computer's Wi-Fi address.
For another device, point this URL at the computer's reachable LAN address and
explicitly bind the backend to that address; this milestone does not deploy it.

Backend unit/API tests (no model download): install `pytest httpx`, then
`python -m pytest tests`.

Reference: https://github.com/QwenAudio/SenseVoice (FunASR usage, FSMN-VAD,
Chinese language hint, ITN). No OpenAI provider is connected.

## Local Ollama extraction

Start Ollama and download the model in another terminal:

```powershell
ollama serve
# In another terminal, while the service is running:
ollama pull qwen3.5:4b
```

The backend reads `OLLAMA_BASE_URL` (default `http://127.0.0.1:11434`) and
`OLLAMA_MODEL` (default `qwen3.5:4b`) at startup. To switch sizes, download
the desired Qwen3.5 size, change `OLLAMA_MODEL`, and restart the backend. There is
no cloud provider or API key. Model downloads need network access; inference
uses the local service. This machine's portable Ollama executable is
`C:\Temp\idea_capture_ollama\ollama.exe`.

Leave `OLLAMA_MODEL` unset to use the default 4B model. For example, to use 2B
in the current PowerShell terminal before starting the backend:

```powershell
$env:OLLAMA_MODEL = 'qwen3.5:2b'
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --workers 1
```

To return to the default in that terminal, stop the backend, run
`Remove-Item Env:OLLAMA_MODEL -ErrorAction SilentlyContinue`, then start it again.

`POST /extract-tasks` accepts `text`, an offset-aware `current_time`, and an IANA
device `timezone`. It returns `tasks` with title, description, category, horizon
(`today`, `recently`, `later`), `suggestedStart`, optional deadline, independent
`startPeriod`/`deadlinePeriod`, `firstStep`/`firstStepReason`, priority
(`high`, `medium`, `low`) and proposed cancellations using existing task IDs.
Classification is required and restricted to 工作、生活、健康、学习、其他.
The app sends its current UTC instant and actual device timezone; server time
is not used for date interpretation.

The provider sends a Pydantic JSON Schema to Ollama, sets `think=false` and
temperature 0, and validates the entire response before returning it. It uses
raw `/api/generate` with Qwen3.5's official non-thinking chat framing; this
avoids the empty output observed with the installed model's default chat
template. The 2B and 4B models share this framing. Other model families may
require a provider change. Task evidence must occur in the original text;
classification is inferred and unsupported priority becomes `medium` (中优先级).
Common explicit relative/calendar deadlines are resolved from the source
clause in the device timezone. Dates without a time remain dates; unresolvable
or missing dates remain null. A planned action tomorrow does not create a
deadline. The LLM does not control deadline arithmetic. Failed/malformed
responses save no tasks; the app retains audio/text for retry.

The multi-task sheet lets users deselect tasks or cancel without saving. A
confirmed batch is saved once, in extraction order, through the existing store.
Explicit cancellations use the same sheet with proposed deletions and additions;
ambiguous candidates require user selection. Only unfinished tasks are supplied.
The store checks candidates have not changed, then applies deletions/additions
in one persisted snapshot. Dismissing the sheet changes neither list nor storage.

`suggestedStart` reuses the existing planned-time field. ISO date strings preserve
date-only precision; `YYYY-MM-DDTHH:mm±HH:mm` timestamps preserve minute precision,
including explicit midnight. Missing dates/clocks are not invented. Detail editing
accepts a date or date plus hour/minute and allows clearing without changing the
deadline. 上午/中午/下午/晚上 are separate optional date-associated periods; they
never imply arbitrary clock times. 今晚 means today's date plus 晚上. Valid model
timestamps with seconds/microseconds normalize to minutes before strict validation;
the backend then derives dates/clocks from original evidence, never the request clock.
Replacement actions can inherit the original cancelled action's period in the same
sentence. Suggestions are one concrete low-burden action and one concise reason about the task’s practical benefit/problem/necessity, not a justification of the preparatory step. Address 你; avoid shame, invented consequences or leisure obligations. They are read-only advice, not extra
tasks; old tasks are never sent to the model to fill missing suggestions.

App storage version 7 reads versions 1–6, maps 普通/中 to `medium`, and migrates
legacy categories (运动→健康, 项目→工作, 旅游/社交→生活, unknown→其他); the existing storage key and task IDs are retained. Legacy
unanchored mock time strings remain unchanged rather than inventing dates.
Older snapshots lost deadline precision at midnight; their midnight deadlines retain
the previous date-only interpretation. New explicit midnight deadlines retain clock
precision. Task IDs, ordering and the existing storage key are unchanged.

The device groups unfinished tasks locally at startup, on resume and each minute
(including midnight). Start date takes precedence over deadline date: past/today
is Today, +1 through +3 is Recently, +4 onwards is Later. No date preserves the
group; a manual group override and completed tasks remain unchanged. Date-only
deadlines, even with periods, expire after the local day ends. Only deadlines can
mark tasks overdue. No LLM is called during these updates.

Each response includes timings: `model_call_ms` (Ollama HTTP call),
`model_load_ms` (Ollama-reported loading duration), `backend_elapsed_ms`,
`prompt_eval_ms` / `generation_ms` (input processing / output decoding),
`prompt_tokens` / `output_tokens`, and `postprocess_ms` (JSON validation and
business checks). Ollama duration fields are converted from nanoseconds to
milliseconds; they are diagnostics, not additive estimates of UI/confirmation
time. Existing client end-to-end logs remain unchanged.

`load_state` is determined from `/api/ps` immediately before inference. A
different resident context window is cold for this request because it requires
runner reloading; `model_load_ms` is the measured loading time. The client
separately logs `client_elapsed_ms` (device context, HTTP and parsing, excluding
recording/transcription and user confirmation). Cold/warm indicates whether the
model was resident before the call, not the size or a claimed speed advantage.
Capture logs `button_to_result_ms` after the first result UI frame (detail or
confirmation sheet). This excludes time spent deciding whether to confirm.

### Measured 4B generation profile

The fixed four-intent oral regression, empty existing-task context and device
time `2026-10-11T12:00:00+02:00` (`Europe/Berlin`) were measured with Ollama
0.40.0, `qwen3.5:4b` Q4_K_M (digest `d8b0f5e9760c`) and an RTX 4060 Laptop
GPU (8 GiB), fully GPU-resident. Thinking is disabled and each extraction makes
one generation call, with no automatic retries. The actual input is 2,644 tokens
within the unchanged 32K window; four tasks produce 864 output tokens.

Initial loading took 7.19 s, input processing 2.35 s and generation 22.52 s.
Warm direct-provider runs took 22.70–23.49 s, dominated by output decoding at
about 38 tokens/s. A one-task short input took 6.08 s (212 output tokens).
HTTP end-to-end was 23.54 s before diagnostics and 23.78 s on the final warm
repeat; short input was 6.13 s versus 6.05 s. The first uncached-prompt repeat
took 25.10 s despite the model already being resident. These are measurements
on this machine, not speed guarantees; end-to-end excludes recording,
transcription and time spent confirming.

Compact JSON trials ran faster but lost suggested start dates; they were
rejected. An 8K-window experiment did not reliably improve decoding and was
also rejected. Production retains the original prompt, schema, window and
sampling settings; no safe performance gain is claimed. Task and advice fields
were exactly equal across the final before/after HTTP requests. Only diagnostic
timings and context-aware warm-runner classification changed.

Official references: https://docs.ollama.com/api/generate and
https://huggingface.co/Qwen/Qwen3.5-2B/blob/main/chat_template.jinja.
