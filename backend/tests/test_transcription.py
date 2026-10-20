import io
import numpy as np
import soundfile as sf
from fastapi.testclient import TestClient

from main import create_app
from transcription import SenseVoiceTranscriber, bounded_segments, clean_text


class FakeModel:
    def __init__(self, vad=False):
        self.vad = vad
        self.calls = []

    def generate(self, **kwargs):
        self.calls.append(kwargs)
        if self.vad:
            return [{"value": [[0, 65000]]}]
        return [{"text": f"<|zh|><|HAPPY|><|Speech|>第{len(self.calls)}段，保留标点。"}]


def wav(duration=65, rate=8000, channels=2):
    stream = io.BytesIO()
    sf.write(stream, np.zeros((duration * rate, channels)), rate, format="WAV")
    return stream.getvalue()


def test_whole_recording_is_not_capped_at_thirty_seconds(tmp_path):
    path = tmp_path / "long.wav"
    path.write_bytes(wav())
    asr, vad = FakeModel(), FakeModel(vad=True)
    result = SenseVoiceTranscriber(asr, vad).transcribe(path)
    assert result["duration_seconds"] == 65
    assert result["text"] == "第1段，保留标点。第2段，保留标点。第3段，保留标点。"
    assert len(asr.calls) == 3
    assert all(len(call["input"]) <= 30 * 16000 for call in asr.calls)
    assert all(call["language"] == "zh" and call["use_itn"] for call in asr.calls)
    assert vad.calls[0]["max_single_segment_time"] == 30000


def test_segments_are_ordered_bounded_and_clamped():
    assert bounded_segments([[31000, 80000], [0, 31000]], 65000) == [
        (0, 15500), (15500, 31000), (31000, 48000), (48000, 65000)
    ]


def test_clean_tags_keeps_punctuation():
    assert clean_text("<|zh|><|NEUTRAL|>你好，世界！<|Applause|>") == "你好，世界！"


def test_silence_and_invalid_audio(tmp_path):
    path = tmp_path / "empty.wav"
    path.write_bytes(wav(1))
    class SilentModel:
        def generate(self, **kwargs):
            return [{"value": []}]
    asr = FakeModel()
    assert SenseVoiceTranscriber(asr, SilentModel()).transcribe(path)["text"] == ""
    assert asr.calls == []


def test_api_upload_and_cors_without_model_reloading():
    asr, vad = FakeModel(), FakeModel(vad=True)
    service = SenseVoiceTranscriber(asr, vad)
    with TestClient(create_app(service)) as client:
        assert client.get("/health").json()["device"] == "cpu"
        for _ in range(2):
            response = client.post("/transcribe", files={"file": ("recording.wav", wav(1))},
                headers={"Origin": "http://127.0.0.1:7361"})
            assert response.status_code == 200
            assert response.headers["access-control-allow-origin"] == "http://127.0.0.1:7361"
        assert len(vad.calls) == 2
        assert client.post("/transcribe", files={"file": ("bad.wav", b"bad")}).status_code == 422
        assert client.post("/transcribe", files={"file": ("empty.wav", b"")}).status_code == 422
