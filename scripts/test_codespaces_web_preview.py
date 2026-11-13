#!/usr/bin/env python3
"""Standard-library regression checks for the optional Codespaces preview."""
from __future__ import annotations

from http.client import HTTPConnection
import json
from pathlib import Path
import sys
import tempfile
import threading
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import codespaces_web_preview as preview


class CodespacesWebPreviewTests(unittest.TestCase):
    def test_export_requires_all_nonempty_files(self):
        with tempfile.TemporaryDirectory() as name:
            folder = Path(name)
            self.assertFalse(preview.valid_export(folder))
            (folder / "index.html").write_text("", encoding="utf-8")
            for ext in ("js", "wasm", "pck"):
                (folder / ("game." + ext)).write_bytes(b"x")
            self.assertFalse(preview.valid_export(folder))
            (folder / "index.html").write_text("<html>ready</html>", encoding="utf-8")
            self.assertTrue(preview.valid_export(folder))
            (folder / "game.wasm").write_bytes(b"")
            self.assertFalse(preview.valid_export(folder))

    def test_http_port_responds_during_build_and_serves_valid_export(self):
        with tempfile.TemporaryDirectory() as name:
            folder = Path(name) / "web"
            cfg = {"port": 0, "directory": folder, "build_command": ["true"], "poll_seconds": 5}
            server = preview.Preview(cfg)
            worker = threading.Thread(target=server.serve_forever, daemon=True)
            worker.start()
            try:
                host = "127.0.0.1"
                port = server.server_address[1]

                def request(path):
                    conn = HTTPConnection(host, port, timeout=5)
                    conn.request("GET", path)
                    response = conn.getresponse()
                    result = response.status, response.read(), response.getheader("Cache-Control")
                    conn.close()
                    return result

                code, data, cache = request("/__preview/status")
                self.assertEqual(code, 200)
                self.assertEqual(json.loads(data)["state"], "starting")
                self.assertEqual(cache, "no-store")
                code, data, _ = request("/")
                self.assertEqual(code, 503)
                self.assertIn(b"Web preview is starting", data)
                folder.mkdir()
                (folder / "index.html").write_text("<html>game ready</html>", encoding="utf-8")
                for ext in ("js", "wasm", "pck"):
                    (folder / ("game." + ext)).write_bytes(b"ok")
                code, data, _ = request("/")
                self.assertEqual(code, 200)
                self.assertIn(b"game ready", data)
            finally:
                server.shutdown()
                server.server_close()
                worker.join(timeout=3)


if __name__ == "__main__":
    unittest.main()
