#!/usr/bin/env python3
"""Write a flat APT Release file that advertises both package index forms."""

from datetime import datetime, timezone
from email.utils import format_datetime
from gzip import decompress
from hashlib import sha256
from pathlib import Path
import sys


if len(sys.argv) != 2:
    raise SystemExit("Usage: write-flat-apt-release.py DIST_DIR")

directory = Path(sys.argv[1])
compressed = (directory / "Packages.gz").read_bytes()
plain = decompress(compressed)
if not plain.strip():
    raise SystemExit("Packages.gz is empty")
(directory / "Packages").write_bytes(plain)

lines = [
    "Origin: Spectra010s",
    "Label: OpenCode Termux",
    "Suite: stable",
    "Codename: stable",
    "Architectures: aarch64",
    "Date: " + format_datetime(datetime.now(timezone.utc), usegmt=True),
    "SHA256:",
]
for name, data in (("Packages", plain), ("Packages.gz", compressed)):
    lines.append(f" {sha256(data).hexdigest()} {len(data)} {name}")
(directory / "Release").write_text("\n".join(lines) + "\n", encoding="utf-8")
