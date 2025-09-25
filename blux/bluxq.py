# -*- coding: utf-8 -*-

"""
BLUX Lite GOLD — bluxq (Model Access Daemon)
- Optional local API surface so models/tools can interact with BLUX in a SAFE, LOGGED, SANDBOXED way.
- Modes: HTTP (127.0.0.1) or Unix Domain Socket (UDS). Defaults to UDS.
- Endpoints:
  /note   POST {"model_id": "...", "text": "..."}              -> append history
  /memory GET  ?model_id=...                                   -> return last N history lines
  /route  POST {"model_id": "...", "task": "..."}              -> stub route request (logged)
Security:
- Each model_id is sandboxed to libf/projects/<model_id>/
- All calls logged to logs/bluxq.log
- No cross-project writes; no file system access beyond the sandbox & logs
"""
import os
import sys
import json
import time
import datetime
from urllib.parse import urlparse, parse_qs

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LOG_DIR = os.path.join(REPO_ROOT, "logs")
CONFIG_DIR = os.path.join(REPO_ROOT, ".config", "blux-lite")
os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(CONFIG_DIR, exist_ok=True)


def log(msg):
    stamp = datetime.datetime.utcnow().isoformat() + "Z"
    line = f"[{stamp}] {msg}\n"
    sys.stdout.write(line)
    sys.stdout.flush()
    with open(os.path.join(LOG_DIR, "bluxq.log"), "a") as f:
        f.write(line)


def project_dir(model_id):
    safe = (
        "".join(c for c in model_id if c.isalnum() or c in ("-", "_", ".")).strip()
        or "unknown"
    )
    p = os.path.join(REPO_ROOT, "libf", "projects", safe)
    os.makedirs(os.path.join(p, "history"), exist_ok=True)
    return p


def append_history(model_id, text):
    p = project_dir(model_id)
    path = os.path.join(p, "history", "history.jsonl")
    rec = {
        "ts": int(time.time()),
        "utc": datetime.datetime.utcnow().isoformat() + "Z",
        "model_id": model_id,
        "text": text,
    }
    with open(path, "a") as f:
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")


def tail_history(model_id, n=50):
    p = project_dir(model_id)
    path = os.path.join(p, "history", "history.jsonl")
    if not os.path.exists(path):
        return []
    with open(path, "r", errors="ignore") as f:
        lines = f.readlines()[-n:]
    out = []
    for ln in lines:
        try:
            out.append(json.loads(ln))
        except Exception:
            pass
    return out


def handle_note(body):
    model_id = body.get("model_id", "unknown")
    text = body.get("text", "").strip()
    if not text:
        return {"ok": False, "error": "empty text"}
    append_history(model_id, text)
    log(f"/note model={model_id} size={len(text)}")
    return {"ok": True}


def handle_memory(query):
    model_id = query.get("model_id", ["unknown"])[0]
    n = int(query.get("n", ["50"])[0])
    rows = tail_history(model_id, n=n)
    log(f"/memory model={model_id} n={n} -> {len(rows)} rows")
    return {"ok": True, "rows": rows}


def handle_route(body):
    # Stub: record the task and acknowledge; router can be wired later
    model_id = body.get("model_id", "unknown")
    task = body.get("task", "")
    log(f"/route model={model_id} task_size={len(task)}")
    append_history(model_id, f"[ROUTE-REQUEST] {task[:200]}")
    return {
        "ok": True,
        "routed": False,
        "msg": "Router not yet wired in bluxq skeleton",
    }


# --- HTTP server (built-in) ---
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def _set(self, code=200):
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()

    def do_GET(self):
        if self.path.startswith("/memory"):
            q = parse_qs(urlparse(self.path).query or "")
            out = handle_memory(q)
            self._set(200)
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return
        self._set(404)
        self.wfile.write(b'{"ok":false,"error":"not found"}')

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0") or 0)
        body = {}
        if length:
            try:
                body = json.loads(self.rfile.read(length).decode("utf-8"))
            except Exception:
                body = {}
        if self.path == "/note":
            out = handle_note(body)
            self._set(200)
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return
        if self.path == "/route":
            out = handle_route(body)
            self._set(200)
            self.wfile.write(json.dumps(out).encode("utf-8"))
            return
        self._set(404)
        self.wfile.write(b'{"ok":false,"error":"not found"}')


def run_http(host="127.0.0.1", port=8765):
    srv = HTTPServer((host, port), Handler)
    log(f"HTTP server on {host}:{port}")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


# --- UNIX domain socket server (line-delimited JSON) ---
import socketserver


class UDSHandler(socketserver.StreamRequestHandler):
    def handle(self):
        raw = self.rfile.readline().decode("utf-8").strip()
        try:
            req = json.loads(raw)
        except Exception:
            self.wfile.write(b'{"ok":false,"error":"invalid json"}\n')
            return
        op = req.get("op")
        if op == "note":
            out = handle_note(req)
            self.wfile.write((json.dumps(out) + "\n").encode("utf-8"))
            return
        if op == "memory":
            # mimic query signature
            q = {
                "model_id": [req.get("model_id", "unknown")],
                "n": [str(req.get("n", 50))],
            }
            out = handle_memory(q)
            self.wfile.write((json.dumps(out) + "\n").encode("utf-8"))
            return
        if op == "route":
            out = handle_route(req)
            self.wfile.write((json.dumps(out) + "\n").encode("utf-8"))
            return
        self.wfile.write(b'{"ok":false,"error":"unknown op"}\n')


def run_uds(path):
    if os.path.exists(path):
        os.unlink(path)
    srv = socketserver.UnixStreamServer(path, UDSHandler)
    os.chmod(path, 0o660)
    log(f"UDS server on {path}")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


def main():
    import argparse

    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--mode", choices=["uds", "http"], default=os.environ.get("BLUXQ_MODE", "uds")
    )
    ap.add_argument(
        "--socket", default=os.environ.get("BLUXQ_SOCKET", "/tmp/bluxq.sock")
    )
    ap.add_argument("--host", default=os.environ.get("BLUXQ_HOST", "127.0.0.1"))
    ap.add_argument(
        "--port", type=int, default=int(os.environ.get("BLUXQ_PORT", "8765"))
    )
    args = ap.parse_args()
    if args.mode == "http":
        run_http(args.host, args.port)
    else:
        run_uds(args.socket)


if __name__ == "__main__":
    main()
