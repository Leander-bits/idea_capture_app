import logging
import os
import tempfile
import httpx
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from transcription import SenseVoiceTranscriber
from extraction import ExtractionRequest, OllamaTaskExtractor

logger = logging.getLogger(__name__)
MAX_UPLOAD_BYTES = 256 * 1024 * 1024


def create_app(transcriber=None, extractor=None):
    @asynccontextmanager
    async def lifespan(app):
        # One worker, one ASR model and one VAD model; never load per request.
        app.state.transcriber = transcriber or SenseVoiceTranscriber()
        app.state.extractor = extractor or OllamaTaskExtractor()
        try:
            yield
        finally:
            app.state.extractor.close()

    app = FastAPI(title="Idea Capture local transcription", lifespan=lifespan)
    origins = os.getenv("ASR_ALLOWED_ORIGINS", "")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[origin.strip() for origin in origins.split(",") if origin.strip()],
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
        allow_methods=["GET", "POST"],
        allow_headers=["Content-Type"],
    )

    @app.get("/health")
    def health():
        return {"ready": True, "model": "SenseVoiceSmall", "device": "cpu"}

    @app.post("/extract-tasks")
    def extract_tasks(request: ExtractionRequest):
        try:
            return app.state.extractor.extract(request)
        except httpx.TimeoutException as error:
            logger.exception("Task extraction timed out: text_chars=%d existing_tasks=%d", len(request.text), len(request.existing_tasks))
            raise HTTPException(504, "任务整理超时，文字和录音已保留，请重试。") from error
        except httpx.HTTPError as error:
            logger.exception("Ollama unavailable: %s", error)
            raise HTTPException(502, "无法连接本地模型或模型服务异常，文字和录音已保留，请检查 Ollama 后重试。") from error
        except (ValueError, TypeError, KeyError) as error:
            logger.exception("Task extraction validation failed: %s; text_chars=%d existing_tasks=%d", error, len(request.text), len(request.existing_tasks))
            detail = "模型返回不完整" if "truncated" in str(error) else "模型返回的任务未通过校验"
            raise HTTPException(502, f"{detail}，文字和录音已保留，未保存任何待办，请重试。") from error
        except Exception as error:
            logger.exception("Local task extraction failed")
            raise HTTPException(502, "任务整理失败，文字和录音已保留，未保存任何待办，请重试。") from error

    @app.post("/transcribe")
    def transcribe(file: UploadFile = File(...)):
        try:
            with tempfile.TemporaryDirectory(prefix="idea-capture-") as directory:
                path = Path(directory) / "recording.wav"
                size = 0
                with path.open("wb") as destination:
                    while chunk := file.file.read(1024 * 1024):
                        size += len(chunk)
                        if size > MAX_UPLOAD_BYTES:
                            raise HTTPException(413, "录音文件过大，请分次录制。")
                        destination.write(chunk)
                if not size:
                    raise HTTPException(422, "录音为空，请重新录制。")
                return app.state.transcriber.transcribe(path)
        except HTTPException:
            raise
        except ValueError as error:
            raise HTTPException(422, str(error)) from error
        except Exception as error:
            logger.exception("Local transcription failed")
            raise HTTPException(500, "转写失败，请重试。") from error
        finally:
            file.file.close()

    return app


app = create_app()
