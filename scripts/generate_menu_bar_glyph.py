#!/usr/bin/env python3
"""Rasterize Lucide `image` SVG into MenuBarGlyph.imageset (18 / 36 template PNGs)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "EggplantTinyPNG/Assets.xcassets/MenuBarGlyph.imageset"
SVG = ROOT / "scripts/icons/lucide-image.svg"
RSVG_CANDIDATES = (
    Path("/opt/homebrew/bin/rsvg-convert"),
    Path("/usr/local/bin/rsvg-convert"),
    Path("/Users/cyper/bin/rsvg-convert"),
)
RSVG = next((p for p in RSVG_CANDIDATES if p.exists()), None)

CONTENTS = """{
  "images" : [
    {
      "filename" : "MenuBarGlyph.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "MenuBarGlyph@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
"""


def rasterize(px: int, dest: Path) -> None:
    assert RSVG is not None
    subprocess.run(
        [str(RSVG), "-w", str(px), "-h", str(px), "-f", "png", "-o", str(dest), str(SVG)],
        check=True,
    )
    if dest.stat().st_size == 0:
        sys.exit(f"rsvg-convert wrote empty file: {dest}")


def main() -> None:
    if not SVG.exists():
        sys.exit(f"missing {SVG}")
    if RSVG is None:
        sys.exit("rsvg-convert not found")
    OUT.mkdir(parents=True, exist_ok=True)
    rasterize(16, OUT / "MenuBarGlyph.png")
    rasterize(32, OUT / "MenuBarGlyph@2x.png")
    (OUT / "Contents.json").write_text(CONTENTS)
    print("ok", OUT, "via", RSVG)


if __name__ == "__main__":
    main()
