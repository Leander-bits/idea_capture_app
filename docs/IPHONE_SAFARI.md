# iPhone Safari LAN preview

Run from the repository root on Windows. The computer and iPhone must be on the
same Wi-Fi. This is a local development preview, not an Internet deployment.

## Computer setup (already configured on this computer)

Current Wi-Fi address: `192.168.100.191`. The gateway binds only this address.
Windows Firewall permits TCP 8443/8081 only on this Wi-Fi interface and from
`192.168.100.0/24`; the existing Public network profile is preserved.
SenseVoice/FastAPI and Ollama remain on `127.0.0.1:8000` and `127.0.0.1:11434`.

One-time setup, or after the computer's Wi-Fi address changes, in an administrator
PowerShell:

```powershell
.\tools\setup-lan-https.ps1 -LanAddress 192.168.100.191
```

This downloads the official portable mkcert 1.4.4 into `.local/https/`, issues a
certificate for the Wi-Fi IP, and exports the public root certificate. It does
not change PATH or install a Windows root certificate automatically. mkcert
generates an isolated development CA; the iPhone trusts that CA manually.
The private CA/server keys stay in the ignored `.local/` directory. Neither
certificate server nor gateway can serve those keys.

## Start

Keep the existing Ollama and backend running. If they are stopped, use separate
terminals from the repository root:

```powershell
& C:\Temp\idea_capture_ollama\ollama.exe serve
```

```powershell
cd backend
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --workers 1
```

Wait for backend startup/model loading to finish. In another terminal at the
repository root:

```powershell
.\tools\start-lan-https.ps1
```

The script builds the existing Flutter Web app with
`TRANSCRIPTION_BASE_URL=same-origin` and local CanvasKit assets, then serves it
over HTTPS. The gateway forwards only `/health`, `/transcribe`, `/extract-tasks`
to the loopback backend, with timeouts supporting long recordings. There is no
Ollama proxy, backend documentation exposure, router forwarding or public tunnel.
The script rejects non-loopback backend/Ollama listeners.

For a gateway restart using the same build:

```powershell
.\tools\start-lan-https.ps1 -SkipBuild
```

Ctrl+C stops HTTPS and the certificate-download listener. It leaves SenseVoice
and Ollama running. Use the same HTTPS origin for later visits; browser storage
is separate from the earlier HTTP/localhost preview.

## iPhone (once per local CA)

1. In Safari on the same Wi-Fi, open
   `http://192.168.100.191:8081/rootCA.cer` and allow the profile download.
   This HTTP listener serves only the public CA certificate, never the app/API.
2. Settings → General → VPN & Device Management (or Profile Downloaded): install
   the mkcert certificate profile. Then Settings → General → About → Certificate
   Trust Settings: enable full trust for this root certificate.
3. Open `https://192.168.100.191:8443/` in Safari. Allow the microphone when asked.
   Do not continue with a certificate warning; check the certificate trust switch
   and the computer IP instead. No separate backend URL or certificate is needed.

Only install this computer's public `rootCA.cer`, not a CA/server private key.
For another network, rerun setup with the new Wi-Fi IP. The CA is reused, so the
iPhone certificate profile normally does not need reinstalling.

## Recording compatibility and verification scope

The app explicitly uses `AudioEncoder.wav`, mono. Its pinned `record_web 2.1.3`
uses `MicRecorderDelegate`, Web Audio/AudioWorklet and its own RIFF/WAVE PCM16
encoder. It does not use Safari's native MediaRecorder MP4/AAC path for WAV.
The existing multipart upload is therefore an actual WAV file, and `soundfile`
decodes it before the existing mono conversion/16 kHz resampling. No FFmpeg or
AAC fallback dependency is required for this app's current recording path.
Safari microphone/AudioWorklet requires a trusted secure context. Do not switch
the encoder to AAC/Opus without adding and verifying the corresponding decoder.

Computer validation is limited to TLS certificate chain/IP matching, same-origin
API forwarding, worklet delivery and a real browser-created PCM16 WAV upload.
An extraction request with empty text verifies the API's 422 validation response
without invoking the LLM. Desktop Chrome uses the server public-key pin for this
test only; Python verifies TLS against the actual local CA, not `verify=False`.
No iPhone recording, iOS permission dialog, background behavior or playback has
been physically tested. No business-flow or full regression suite is run here.

Official references:
- [mkcert and mobile trust](https://github.com/FiloSottile/mkcert#mobile-devices)
- [Apple: trust a manually installed root certificate](https://support.apple.com/en-us/102390)
- [record Web WAV recorder dispatch](https://github.com/llfbandit/record/blob/master/record_web/lib/src/recorder/recorder.dart)
- [record Web AudioWorklet recorder](https://github.com/llfbandit/record/blob/master/record_web/lib/src/recorder/delegate/mic_recorder_delegate.dart)
