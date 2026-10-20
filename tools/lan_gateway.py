"""LAN-only HTTPS static preview and a fixed same-origin API proxy."""
import argparse
import ipaddress
import json
from contextlib import asynccontextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

import httpx
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import Response
from fastapi.staticfiles import StaticFiles

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / '.local' / 'https'
BACKEND = 'http://127.0.0.1:8000'


def create_gateway(config):
    network = ipaddress.ip_network(config['subnet'])

    @asynccontextmanager
    async def lifespan(app):
        async with httpx.AsyncClient(timeout=httpx.Timeout(900, connect=5), trust_env=False) as client:
            app.state.proxy = client
            yield

    app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None, lifespan=lifespan)

    @app.middleware('http')
    async def local_only(request: Request, call_next):
        address = ipaddress.ip_address(request.client.host)
        if address not in network and not address.is_loopback:
            return Response('LAN access only', status_code=403)
        response = await call_next(request)
        # Keep refreshes on the current bundle, including the audio worklet.
        response.headers['Cache-Control'] = 'no-store'
        response.headers['X-Content-Type-Options'] = 'nosniff'
        return response

    async def proxy(request: Request):
        # No arbitrary upstream path, URL or Ollama routes can be forwarded.
        path = request.url.path
        if path not in ('/health', '/transcribe', '/extract-tasks'):
            return Response(status_code=404)
        headers = {'Content-Type': request.headers['content-type']} if 'content-type' in request.headers else {}
        try:
            upstream = await request.app.state.proxy.request(
                request.method, BACKEND + path,
                headers=headers,
                content=request.stream() if request.method == 'POST' else None,
            )
        except httpx.HTTPError:
            return Response('{"detail":"本地后端未就绪，请检查电脑端服务。"}', status_code=502, media_type='application/json')
        return Response(upstream.content, status_code=upstream.status_code,
                        media_type=upstream.headers.get('content-type', 'application/json'))

    app.add_api_route('/health', proxy, methods=['GET'])
    app.add_api_route('/transcribe', proxy, methods=['POST'])
    app.add_api_route('/extract-tasks', proxy, methods=['POST'])
    app.mount('/', StaticFiles(directory=ROOT / 'app' / 'build' / 'web', html=True), name='web')
    return app


def certificate_server(config):
    certificate = (STATE / 'rootCA.cer').read_bytes()
    network = ipaddress.ip_network(config['subnet'])

    class CertificateHandler(BaseHTTPRequestHandler):
        def do_GET(self):
            if ipaddress.ip_address(self.client_address[0]) not in network or self.path != '/rootCA.cer':
                self.send_error(404)
                return
            self.send_response(200)
            self.send_header('Content-Type', 'application/x-x509-ca-cert')
            self.send_header('Content-Disposition', 'attachment; filename="rootCA.cer"')
            self.send_header('Content-Length', str(len(certificate)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(certificate)

    server = ThreadingHTTPServer((config['address'], config['certificate_port']), CertificateHandler)
    Thread(target=server.serve_forever, daemon=True).start()
    return server


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', type=Path, default=STATE / 'config.json')
    args = parser.parse_args()
    config = json.loads(args.config.read_text(encoding='utf-8-sig'))
    address = ipaddress.ip_address(config['address'])
    if not address.is_private or address.is_loopback or address.is_unspecified:
        raise ValueError('Bind to the computer Wi-Fi IPv4 address')
    bootstrap = certificate_server(config)
    print(f"iPhone certificate: http://{address}:{config['certificate_port']}/rootCA.cer", flush=True)
    print(f"iPhone app: https://{address}:{config['https_port']}/", flush=True)
    try:
        uvicorn.run(create_gateway(config), host=str(address), port=config['https_port'],
                    ssl_certfile=str(STATE / 'server.pem'), ssl_keyfile=str(STATE / 'server-key.pem'),
                    proxy_headers=False)
    finally:
        bootstrap.shutdown()
        bootstrap.server_close()
