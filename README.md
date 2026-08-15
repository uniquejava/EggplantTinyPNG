# EggplantTinyPNG

Native **macOS 15+** TinyPNG-style image compressor — drag images in, compress **locally**, optional auto-export beside the original.

[简体中文](./README_zh.md)

Prebuilt DMGs (ad-hoc signed, not notarized) are on **[Releases](https://github.com/uniquejava/EggplantTinyPNG/releases)** — push a `v*` tag to build one.

No cloud API. PNG uses the same local `pngquant` (+ optional `oxipng`) approach as [obsidian-cos-images](https://github.com/uniquejava/obsidian-cos-images).

## Features

- **Drop zone** — drag or click to open PNG · JPEG · WebP
- **Queue + progress** — overall bar and per-file status; reveal in Finder when exported
- **Auto export** (default on, ⌘E) — write next to the source as `name-tiny-yyyyMMdd-HHmmss.ext` (same-second collisions get `-1`, `-2`, …)
- **Manual export** — keep bytes in memory, then **Export All**
- **Themes** — light / accent / dark presets in Settings
- **Language** — System / English / 简体中文 (Settings; relaunches to apply)
- **Dock app** — close the window keeps the app in the Dock; ⌘Q to quit; click the Dock icon to show the window again

## Compress stack

| Format | Engine |
|--------|--------|
| PNG | Local **`pngquant`** (`--strip --speed=3`) + optional **`oxipng`** |
| JPEG | Image I/O lossy quality (~80) |
| WebP | Image I/O when available |

Install the CLI tools (App Sandbox is off so Homebrew paths work):

```bash
brew install pngquant oxipng
```

## Build & run

Requires macOS 15+ and Xcode 16+.

```bash
killall EggplantTinyPNG 2>/dev/null
xcodebuild -project EggplantTinyPNG.xcodeproj -scheme EggplantTinyPNG \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/EggplantTinyPNG.app
```

Or: `open EggplantTinyPNG.xcodeproj`

Always use `-derivedDataPath build` and kill the running app first — otherwise you may launch a stale binary.

## Docs

| Doc | Contents |
|-----|----------|
| [docs/commands.md](./docs/commands.md) | Build, DMG, GitHub Release |
| [docs/ui.html](./docs/ui.html) | Shipping UI mock |
| [docs/app-icon.md](./docs/app-icon.md) | Dock / Finder App Icon |
| [docs/releases/v0.1.0.md](./docs/releases/v0.1.0.md) | v0.1.0 release notes (EN / 中文) |
| [AGENTS.md](./AGENTS.md) | Product rules for contributors / agents |

## Layout

```
EggplantTinyPNG/
  EggplantTinyPNGApp.swift   # Window + Settings scenes
  Models/                    # CompressItem
  Services/                  # ToolFinder, compressors, output paths
  ViewModels/CompressSession.swift
  UI/                        # ContentView, DropZone, chrome, Settings, About
  Assets.xcassets/           # AppIcon, DropGlyph, …
```

Bundle ID: `click.yinsb.EggplantTinyPNG`
