#!/usr/bin/env python3
"""Opt-in, detached Codespaces web-preview service.

A live HTTP endpoint starts immediately; validated builds replace the previous
successful export. The checked-out Git branch/commit is polled for changes.
"""
from __future__ import annotations

import fcntl
import html
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import threading
import time
from urllib.error import URLError
from urllib.request import urlopen

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "development/codespaces_web_preview.json"
RUNTIME = Path.home() / ".cache/codespaces-web-preview" / ROOT.name
EXTENSIONS = ("html", "js", "wasm", "pck")


def configuration() -> dict:
    cfg = json.loads(CONFIG.read_text(encoding="utf-8"))
    if not isinstance(cfg.get("enabled"), bool):
        raise ValueError("enabled must be a boolean")
    if not cfg["enabled"]:
        return cfg
    port = cfg.get("port")
    command = cfg.get("build_command")
    output = cfg.get("output_dir")
    if not isinstance(port, int) or isinstance(port, bool) or not 1 <= port <= 65535:
        raise ValueError("invalid preview port")
    if not isinstance(command, list) or not command or not all(isinstance(x, str) and x for x in command):
        raise ValueError("build_command must contain executable and arguments")
    if not isinstance(output, str) or not output:
        raise ValueError("output_dir must be a relative path")
    directory = (ROOT / output).resolve()
    if not directory.is_relative_to(ROOT) or directory == ROOT:
        raise ValueError("output_dir must stay inside the repository")
    poll = cfg.get("poll_seconds", 15)
    if not isinstance(poll, int) or poll < 5:
        raise ValueError("poll_seconds must be an integer >= 5")
    cfg["poll_seconds"] = poll
    cfg["directory"] = directory
    return cfg


def revision() -> str:
    branch = subprocess.check_output(
        ["git", "branch", "--show-current"], cwd=ROOT, text=True, timeout=15
    ).strip()
    commit = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, timeout=15
    ).strip()
    return branch + "@" + commit


def valid_export(directory: Path) -> bool:
    return (directory / "index.html").is_file() and (directory / "index.html").stat().st_size > 0 and all(
        any(p.is_file() and p.stat().st_size > 0 for p in directory.glob("*." + ext))
        for ext in EXTENSIONS
    )


class Preview(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, cfg: dict):
        self.cfg = cfg
        self.output = cfg["directory"]
        self.guard = threading.Lock()
        self.state = "starting"
        self.error = ""
        self.served_revision = ""
        self.requested_revision = ""
        old = self.output.with_name(self.output.name + "-previous")
        if old.exists() and not self.output.exists():
            old.rename(self.output)  # Recover an interrupted directory swap.
        if valid_export(self.output):
            self.state = "ready"
            marker = self.output / ".preview-revision"
            self.served_revision = marker.read_text(encoding="utf-8").strip() if marker.is_file() else ""
        super().__init__(("0.0.0.0", cfg["port"]), PreviewHandler)

    def snapshot(self) -> dict:
        with self.guard:
            return {
                "state": self.state,
                "error": self.error,
                "served_revision": self.served_revision,
                "requested_revision": self.requested_revision,
            }

    def rebuilds(self) -> None:
        staging = self.output.with_name(self.output.name + "-staging")
        previous = self.output.with_name(self.output.name + "-previous")
        while True:
            try:
                wanted = revision()
                if self.snapshot()["served_revision"] != wanted:
                    with self.guard:
                        self.requested_revision = wanted
                        self.state = "building"
                        self.error = ""
                    if staging.exists():
                        shutil.rmtree(staging)
                    staging.mkdir(parents=True)
                    command = [arg.replace("{staging_dir}", str(staging)) for arg in self.cfg["build_command"]]
                    print("Building", wanted, "with", command, flush=True)
                    completed = subprocess.run(command, cwd=ROOT, timeout=900)
                    if completed.returncode != 0:
                        raise RuntimeError("build command exited with status " + str(completed.returncode))
                    if not valid_export(staging):
                        raise RuntimeError("build completed without a full HTML/JS/WASM/PCK export")
                    (staging / ".preview-revision").write_text(wanted + "\n", encoding="utf-8")
                    if previous.exists():
                        shutil.rmtree(previous)
                    if self.output.exists():
                        self.output.rename(previous)
                    try:
                        staging.rename(self.output)
                    except BaseException:
                        if previous.exists() and not self.output.exists():
                            previous.rename(self.output)
                        raise
                    if previous.exists():
                        shutil.rmtree(previous)
                    with self.guard:
                        self.served_revision = wanted
                        self.state = "ready"
                    print("Preview ready", wanted, flush=True)
            except Exception as exc:
                with self.guard:
                    self.state = "error"
                    self.error = str(exc)
                print("Preview build failed:", exc, flush=True)
                time.sleep(45)
            else:
                time.sleep(self.cfg["poll_seconds"])


class PreviewHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(kwargs.pop("directory", ROOT)), **kwargs)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self) -> None:
        if self.path.split("?", 1)[0] == "/__preview/status":
            payload = json.dumps(self.server.snapshot()).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        if not valid_export(self.server.output):
            snapshot = self.server.snapshot()
            message = html.escape(snapshot["error"] or "Building the current game export")
            body = (
                "<!doctype html><html><head><meta name='viewport' content='width=device-width'>"
                "<meta http-equiv='refresh' content='8'></head><body>"
                "<h2>Web preview is starting</h2><p>" + message +
                "</p><p>The page will refresh automatically.</p></body></html>"
            ).encode("utf-8")
            self.send_response(503)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        self.directory = str(self.server.output)
        super().do_GET()


def show_status(port: int, quiet: bool = False) -> int:
    try:
        with urlopen(f"http://127.0.0.1:{port}/__preview/status", timeout=3) as response:
            print(response.read().decode("utf-8"))
        return 0
    except (URLError, OSError) as exc:
        if not quiet:
            print("Preview service not responding:", exc)
            print("Log:", RUNTIME / "service.log")
        return 1


def main() -> int:
    action = sys.argv[1] if len(sys.argv) > 1 else "start"
    cfg = configuration()
    if action == "status":
        return show_status(int(cfg.get("port", 8765)))
    if action not in ("start", "run"):
        print("Usage: python3 scripts/codespaces_web_preview.py [start|status]", file=sys.stderr)
        return 2
    if not cfg["enabled"]:
        print("Web preview disabled; configure development/codespaces_web_preview.json to opt in")
        return 0
    RUNTIME.mkdir(parents=True, exist_ok=True)
    if action == "start":
        if show_status(cfg["port"], quiet=True) == 0:
            print("Web preview already running")
            return 0
        with (RUNTIME / "service.log").open("a", encoding="utf-8") as log:
            subprocess.Popen(
                [sys.executable, str(Path(__file__).resolve()), "run"],
                cwd=ROOT, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT,
                start_new_session=True, close_fds=True,
            )
        print("Web preview started on port", cfg["port"])
        print("Build progress and errors:", RUNTIME / "service.log")
        return 0
    with (RUNTIME / "service.lock").open("a+") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("Preview process already running", flush=True)
            return 0
        server = Preview(cfg)
        print("Preview HTTP server listening on", cfg["port"], flush=True)
        threading.Thread(target=server.rebuilds, daemon=True).start()
        try:
            server.serve_forever(poll_interval=0.5)
        finally:
            server.server_close()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print("Preview service error:", exc, file=sys.stderr)
        sys.exit(1)
