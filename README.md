# EggplantTinyPNG

Native **macOS 15+** TinyPNG-style image compressor — drag images in, compress locally, optional auto-export beside the original.

## Compress stack

Same approach as [obsidian-cos-images](https://github.com/uniquejava/obsidian-cos-images):

| Format | Engine |
|--------|--------|
| PNG | Local **`pngquant`** (`--strip --speed=3`) + optional **`oxipng`** |
| JPEG | Image I/O lossy quality (~80) |
| WebP | Image I/O when available |

```bash
brew install pngquant oxipng
```

## Features

- Style **A** UI: large drop zone → queue + overall progress
- **Auto export** (default on): write next to source as `name-tiny-yyyyMMdd-HHmmss.ext` (same-second collision adds `-1`, `-2`, …)
- Manual mode: compress in memory, then **全部导出**

## Build & run

```bash
killall EggplantTinyPNG 2>/dev/null
xcodebuild -project EggplantTinyPNG.xcodeproj -scheme EggplantTinyPNG \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/EggplantTinyPNG.app
```

Or: `open EggplantTinyPNG.xcodeproj`

## Layout

```
EggplantTinyPNG/
  EggplantTinyPNGApp.swift
  Models/CompressItem.swift
  Services/   # ToolFinder, PngquantCompressor, JPEG/WebP, ImageCompressor, OutputPathResolver
  ViewModels/CompressSession.swift
  UI/         # ContentView, DropZoneView, CompressItemRow
  docs/ui-styles.html
```

Bundle ID: `click.yinsb.EggplantTinyPNG`
