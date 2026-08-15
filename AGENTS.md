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

---

## Handoff (2026-08-15) — continue in new chat

### Git

- Repo initialized; baseline commit: **`3160af0`** on `main`  
  `Initial baseline: local TinyPNG-style compressor for macOS 15+.`
- **Uncommitted** (do not lose):
  - `EggplantTinyPNG/UI/AppChrome.swift` — L1 Mist Cyan `#eef8fc` + transparent titlebar configurator
  - `EggplantTinyPNG/UI/{ContentView,DropZoneView,CompressItemRow}.swift` — soft white+dashed drop; white cards on mist chrome
  - `EggplantTinyPNG/Assets.xcassets/DropGlyph.imageset/` — stacked-photos glyph (no outer tile frame)
  - `docs/light-ui-styles.html` — light chrome picker (L1 applied in Swift)

### Decisions locked in

| Topic | Decision |
|-------|----------|
| UI layout | Style **A** (large drop → compact strip + progress + queue) |
| Theme | Stay **light** (dark cyan trial reverted — user disliked) |
| Accent / drop | Soft **cyan** `#50c7fc` as border/glyph only (user disliked solid cyan slab) |
| Drop zone | White fill + cyan dashed border + dark copy; glyph template-tinted cyan |
| Window chrome | **L1 Mist Cyan** `#eef8fc`; hidden title bar; no in-window toolbar |
| Controls | Drop zone is the open affordance; auto-export in **File menu** (⌘E); row reveal; quiet text “清除列表” |
| Naming | Always `name-tiny-yyyyMMdd-HHmmss.ext` |
| Compress | Local `pngquant` (+ optional `oxipng`), mirror `obsidian-cos-images` |

### Design docs (HTML)

| File | Purpose |
|------|---------|
| `docs/ui-styles.html` | Original layout A–F (A chosen) |
| `docs/dark-ui-styles.html` | Dark candidates (rejected for shipping; mid-gray + dashed drop) |
| `docs/light-ui-styles.html` | **Next pick**: L1–L6 light window tints |

**Light chrome options (user browsing, not chosen yet):**

- **L1 Mist Cyan** `#eef8fc` unified title+body (recommended in mock)
- **L2 Soft Sky** `#f2f6fb`
- **L3 Seafoam** `#eef8f4`
- **L4 Porcelain** title `#ebf0f6` / body `#f5f7fa`
- **L5 Ice Paper** `#e6f4fa` + white floating sheet
- **L6 Warm Sand** `#f7f3ec` (warm contrast control)

Open: `open docs/light-ui-styles.html` → user replies with `L1`…`L6` → implement unified title bar + tinted surface in Swift (transparent titlebar / same fill as content; soft white+dashed drop already in Swift).

### Next agent tasks (likely order)

1. Polish busy-state layout if user still dislikes queue density / spacing.
2. Commit post-baseline UI when user asks.
3. Later: AppIcon, bundle `pngquant` in Resources, CI/DMG like Shot/Fred.

### Sibling reference

- Compress flags: `~/code/golang-projects/obsidian-cos-images/compress_png.go`
- macOS app patterns: EggplantShot / EggplantFred (`click.yinsb.*`, team `M5J7K9HVYB`)
