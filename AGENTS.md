# AGENTS.md — EggplantTinyPNG

## What this is

Native **macOS 15+** TinyPNG-style local image compressor (SwiftUI window app).

- Drag / open PNG · JPEG · WebP
- Auto-export beside originals (`name-tiny.ext`)
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

1. Compress immediately → write beside source as `name-tiny.ext` (collision → `-1`, `-2`, …).
2. Do **not** call TinyPNG / any online API.
3. PNG quality mapping matches `obsidian-cos-images/compress_png.go` (`min = max-35`, retry floor 0 on exit 99).
4. App Sandbox **OFF** so writes next to user-selected files work.

## Prefer

- Mirror Shot/Fred signing, team, bundle-ID pattern
- Small focused Swift diffs
- Commit only when the user asks

---

## Handoff (2026-08-15)

### Git

- Baseline: `3160af0` — initial compressor
- UI chrome + shipping mock committed on `main` after baseline

### Decisions locked in

| Topic | Decision |
|-------|----------|
| UI layout | Style **A** (large drop → compact strip + progress + queue) |
| Theme | Light **L1 Mist Cyan** `#eef8fc` (dark trial rejected) |
| Accent / drop | Soft **cyan** `#50c7fc` border/glyph only (no solid cyan slab) |
| Drop zone | White fill + cyan dashed border + dark copy; glyph template-tinted cyan |
| Window chrome | Unified mist title+body; no in-window toolbar |
| Scroller | Legacy always-on when overflowing; track `#e2f0f6` / knob `#82a8ba` |
| Controls | Drop zone opens files; row reveal + overwrite original; quiet “清除列表” |
| Naming | Always `name-tiny.ext` (collision → `-1`, `-2`, …) |
| Compress | Local `pngquant` (+ optional `oxipng`), mirror `obsidian-cos-images` |

### Design doc

- `docs/ui.html` — single shipping mock (matches current Swift UI). Open: `open docs/ui.html`

### Next agent tasks (likely)

1. AppIcon
2. Bundle `pngquant` in Resources
3. CI / DMG like Shot/Fred

### Sibling reference

- Compress flags: `~/code/golang-projects/obsidian-cos-images/compress_png.go`
- macOS app patterns: EggplantShot / EggplantFred (`click.yinsb.*`, team `M5J7K9HVYB`)
