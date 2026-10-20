"""CPU-only local transcription; models live for the lifetime of the server."""

import math
import os
import re
from threading import Lock

import numpy as np
import soundfile as sf
from scipy.signal import resample_poly

SAMPLE_RATE = 16000
MAX_SEGMENT_MS = 30000
RICH_TAG = re.compile(r"<\|[^|]*\|>")


def bounded_segments(intervals, duration_ms):
    """Preserve VAD order while enforcing a per-segment, not total, bound."""
    segments = []
    previous_end = 0
    for start, end in sorted(intervals):
        start = max(previous_end, 0, int(start))
        end = min(int(end), duration_ms)
        if start < end:
            count = math.ceil((end - start) / MAX_SEGMENT_MS)
            # VAD may exceed its threshold by one frame. Balanced splitting
            # avoids sending a meaningless 10 ms remainder to the ASR model.
            boundaries = [start + (end - start) * index // count for index in range(count + 1)]
            segments.extend(zip(boundaries, boundaries[1:]))
        previous_end = max(previous_end, end)
    return segments


def clean_text(text):
    # Strip tags before any rich postprocessor can convert them to emoji.
    return RICH_TAG.sub("", text).strip()


class SenseVoiceTranscriber:
    def __init__(self, asr=None, vad=None):
        if asr is None or vad is None:
            from funasr import AutoModel

            options = dict(
                device="cpu",
                ncpu=int(os.getenv("ASR_CPU_THREADS", "4")),
                disable_update=True,
                disable_pbar=True,
                trust_remote_code=False,
            )
            asr = AutoModel(
                model=os.getenv("SENSEVOICE_MODEL", "iic/SenseVoiceSmall"),
                **options,
            )
            vad = AutoModel(
                model=os.getenv("FSMN_VAD_MODEL", "fsmn-vad"),
                max_single_segment_time=MAX_SEGMENT_MS,
                **options,
            )
        self.asr = asr
        self.vad = vad
        self.lock = Lock()

    def transcribe(self, path):
        try:
            audio, rate = sf.read(path, dtype="float32", always_2d=True)
        except (sf.LibsndfileError, ValueError) as error:
            raise ValueError("无法读取录音，请重新录制。") from error
        if not len(audio) or rate <= 0 or not np.isfinite(audio).all():
            raise ValueError("录音为空或已损坏，请重新录制。")
        audio = audio.mean(axis=1)
        if rate != SAMPLE_RATE:
            divisor = math.gcd(rate, SAMPLE_RATE)
            audio = resample_poly(audio, SAMPLE_RATE // divisor, rate // divisor)
        audio = np.asarray(audio, dtype=np.float32)
        duration_ms = math.ceil(len(audio) * 1000 / SAMPLE_RATE)
        segments = []
        with self.lock:
            detected = self.vad.generate(
                input=audio, cache={}, fs=SAMPLE_RATE,
                max_single_segment_time=MAX_SEGMENT_MS,
            )
            intervals = [interval for result in detected for interval in result.get("value", [])]
            for start, end in bounded_segments(intervals, duration_ms):
                waveform = audio[start * SAMPLE_RATE // 1000:end * SAMPLE_RATE // 1000]
                if not len(waveform):
                    continue
                result = self.asr.generate(
                    input=waveform, cache={}, fs=SAMPLE_RATE,
                    language="zh", use_itn=True, batch_size=1,
                )
                text = "".join(clean_text(item.get("text", "")) for item in result)
                segments.append({"start_ms": start, "end_ms": end, "text": text})
        return {
            "text": "".join(segment["text"] for segment in segments),
            "duration_seconds": round(len(audio) / SAMPLE_RATE, 3),
            "segments": segments,
        }
