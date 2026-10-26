"""Small HTTP gateway: periodic status plus request logs, no sensor data required."""
import os
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MESSAGE = b"Smart Hub Online\n"

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(MESSAGE)))
        self.end_headers()
        self.wfile.write(MESSAGE)


def heartbeat():
    while True:
        print("Smart Hub Online", flush=True)
        time.sleep(5)


if __name__ == "__main__":
    server = ThreadingHTTPServer(("0.0.0.0", int(os.environ.get("HTTP_PORT", "80"))), Handler)
    threading.Thread(target=heartbeat, daemon=True).start()
    server.serve_forever()
