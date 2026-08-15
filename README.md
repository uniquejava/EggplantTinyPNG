# EggplantTinyPNG

Native **macOS 15+** image compressor — drag photos in, shrink them on your Mac, keep the originals.

[简体中文](./README_zh.md)

Download from **[Releases](https://github.com/uniquejava/EggplantTinyPNG/releases)** (DMG, ad-hoc signed — not notarized).

![EggplantTinyPNG main window](./docs/screenshot.png)

## What it does

- **Drop or open** PNG, JPEG, or WebP
- **Compress locally** — nothing is uploaded
- **Auto-save** next to the original as `name-tiny.ext` (on by default; toggle with ⌘E)
- Or compress first, then tap **Export All** when you’re ready
- See progress for the whole batch; jump to a file in Finder when it’s done
- Themes and language (System / English / 简体中文) in Settings

Closing the window keeps the app in the Dock. Quit with ⌘Q.

## Get started

1. Install from the DMG (drag to Applications).
2. If macOS blocks it: `xattr -cr /Applications/EggplantTinyPNG.app`
3. For best PNG results, install helpers once: `brew install pngquant oxipng`
4. Drop images in and you’re done.

## Build from source

See [docs/commands.md](./docs/commands.md). Requires macOS 15+ and Xcode 16+.

## More

- [v0.1.0 release notes](./docs/releases/v0.1.0.md) (English / 中文)
- [AGENTS.md](./AGENTS.md) — notes for contributors
