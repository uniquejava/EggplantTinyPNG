# AGENTS.md — EggplantTinyPNG

## What this is

Native **macOS 15+** TinyPNG-style local image compressor (SwiftUI window app).

- Drag / open PNG · JPEG · WebP
- Auto-export beside originals (`name-tiny-yyyyMMdd-HHmmss.ext`)
- Light UI (style A); per-row Finder reveal
- PNG via local **pngquant** (+ optional **oxipng**), same flags as obsidian-cos-images

## Stack

| Layer | Tech |
|-------|------|
| UI | SwiftUI `WindowGroup` (style A: drop zone + queue + progress) |
| PNG | `pngquant` CLI (`ToolFinder` → Homebrew / PATH / app Resources) |
| PNG 2nd pass | `oxipng` optional |
| JPEG / WebP | Image I/O |

Bundle ID: `click.yinsb.EggplantTinyPNG`  
Team: `DEVELOPMENT_TEAM = M5J7K9HVYB`  
Xcode: `EggplantTinyPNG.xcodeproj` (scheme `EggplantTinyPNG`)

## Build / run (agents — always)

```bash
killall EggplantTinyPNG 2>/dev/null
xcodebuild -project EggplantTinyPNG.xcodeproj -scheme EggplantTinyPNG \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/EggplantTinyPNG.app
```

Always use `-derivedDataPath build`. `build/` is gitignored.

## Product rules

1. **Auto export on**: compress immediately → write beside source as `name-tiny-yyyyMMdd-HHmmss.ext` (always timestamped; same-second collision → `-1`, `-2`, …).
2. **Auto export off**: keep bytes in memory → user taps **全部导出** (same naming).
3. Do **not** call TinyPNG / any online API.
4. PNG quality mapping matches `obsidian-cos-images/compress_png.go` (`min = max-35`, retry floor 0 on exit 99).
5. App Sandbox **OFF** so writes next to user-selected files work.

## Prefer

- Mirror Shot/Fred signing, team, bundle-ID pattern
- Small focused Swift diffs
- Commit only when the user asks
