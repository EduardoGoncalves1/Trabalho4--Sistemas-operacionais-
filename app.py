import os, sys, signal, logging
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.getenv("PORT", "8080"))
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO").upper(),
                    format="%(asctime)s %(levelname)s %(message)s", stream=sys.stdout)
log = logging.getLogger("app")

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/crash":  # falha controlada para a demonstração
            log.error("FALHA SIMULADA: encerrando com codigo 1")
            logging.shutdown()
            os._exit(1)
        log.debug("rota acessada: %s", self.path)
        body = b"ok\n" if self.path == "/health" else \
            f"Ola! uid={os.getuid()} pid={os.getpid()}\n".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *a):
        log.info("requisicao de %s: %s", self.address_string(), fmt % a)

def stop(*_):
    log.info("SIGTERM recebido, parada normal (codigo 0)")
    sys.exit(0)

signal.signal(signal.SIGTERM, stop)
log.info("Servico iniciado na porta %d | uid=%d | LOG_LEVEL=%s",
         PORT, os.getuid(), logging.getLevelName(log.getEffectiveLevel()))
ThreadingHTTPServer(("0.0.0.0", PORT), H).serve_forever()
