"""Offline parser contracts: real shell/jq, a deterministic HTTP transport."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

PARSER = Path(__file__).resolve().parents[1] / "parser.sh"

CURL = r'''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
url = next(arg for arg in args if arg.startswith("https://"))
out = Path(args[args.index("-o") + 1])
with open(os.environ["REQUEST_LOG"], "a") as log:
    log.write(url + "\n")
if os.environ["SCENARIO"] == "failure":
    sys.exit(22)
if "/subsite?" in url:
    data = {"result": {"id": 42}}
elif "/timeline?" in url:
    if os.environ["SCENARIO"] == "empty":
        data = {"result": {"items": [], "cursor": ""}}
    elif "cursor=" not in url:
        data = {"result": {"items": [], "cursor": "page 2"}}
    else:
        def post(ids):
            return {"data": {"blocks": [{"type": "text", "data": {"text": "#иногдафрирен"}}] + [
                {"type": "image", "data": {"uuid": uuid}} for uuid in ids]}}
        data = {"result": {"items": [post(["first", "first"]), post(["second"])], "cursor": ""}}
else:
    out.write_bytes(b"fixture-image")
    sys.exit(0)
out.write_text(json.dumps(data))
'''

@unittest.skipUnless(shutil.which("jq"), "jq is required")
class ParserTests(unittest.TestCase):
    def run_parser(self, scenario, custom_target=False):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        checkout = root / "checkout"
        runtime = root / "runtime"
        bin_dir = root / "bin"
        for directory in (checkout, runtime, bin_dir):
            directory.mkdir()
        curl = bin_dir / "curl"
        curl.write_text(CURL)
        curl.chmod(0o755)
        env = {**os.environ, "PATH": f"{bin_dir}:{os.environ['PATH']}",
               "SCENARIO": scenario, "TMPDIR": str(runtime),
               "REQUEST_LOG": str(root / "requests.log")}
        env.pop("TARGET_DIR", None)
        if custom_target:
            env["TARGET_DIR"] = str(root / "custom-downloads")
        result = subprocess.run(["sh", str(PARSER)], cwd=checkout,
                                capture_output=True, text=True, env=env)
        prefix = "Images directory: "
        output = next(line[len(prefix):] for line in result.stdout.splitlines()
                      if line.startswith(prefix))
        downloads = Path(output)
        self.assertEqual(list(checkout.iterdir()), [])
        self.assertEqual(list(runtime.glob("dtf-frieren.*")), [])
        if not custom_target:
            self.assertEqual(downloads.parent, runtime)
        return root, downloads, result

    def test_first_matching_post_pagination_and_duplicate_images(self):
        root, downloads, result = self.run_parser("matching")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([p.name for p in downloads.iterdir()], ["first.jpg"])
        requests = (root / "requests.log").read_text().splitlines()
        self.assertTrue(any("cursor=page%202" in url for url in requests))
        self.assertEqual(sum("leonardo.osnova.io" in url for url in requests), 1)

    def test_empty_feed_downloads_nothing(self):
        _, downloads, result = self.run_parser("empty")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(list(downloads.iterdir()), [])

    def test_http_failure_propagates_and_cleans_up(self):
        _, _, result = self.run_parser("failure")
        self.assertNotEqual(result.returncode, 0)

    def test_custom_download_directory(self):
        root, downloads, result = self.run_parser("matching", custom_target=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(downloads, root / "custom-downloads")
        self.assertEqual([p.name for p in downloads.iterdir()], ["first.jpg"])

if __name__ == "__main__":
    unittest.main()
