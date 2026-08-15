# EggplantTinyPNG

原生 **macOS 15+** TinyPNG 风格图片压缩工具 — 拖入图片，**本地**压缩，可选自动导出到原图旁边。

[English](./README.md)

预编译 DMG（ad-hoc 签名、**未**公证）见 **[Releases](https://github.com/uniquejava/EggplantTinyPNG/releases)** — 推送 `v*` 标签即可自动构建。

不调用任何在线 API。PNG 压缩方式与 [obsidian-cos-images](https://github.com/uniquejava/obsidian-cos-images) 一致：本地 `pngquant`（可选再跑 `oxipng`）。

## 功能

- **投放区** — 拖拽或点击打开 PNG · JPEG · WebP
- **队列与进度** — 总体进度条 + 单文件状态；导出后可在 Finder 中显示
- **自动导出**（默认开启，⌘E）— 写到源文件旁：`name-tiny-yyyyMMdd-HHmmss.ext`（同一秒冲突则追加 `-1`、`-2`…）
- **手动导出** — 先压在内存里，再点 **全部导出**
- **主题** — 设置里可选浅色 / 强调色 / 深色预设
- **语言** — 跟随系统 / English / 简体中文（设置内切换，重启后生效）
- **Dock 应用** — 关窗口不退出，图标留在 Dock；⌘Q 才退出；再点 Dock 图标可重新打开窗口

## 压缩引擎

| 格式 | 引擎 |
|------|------|
| PNG | 本地 **`pngquant`**（`--strip --speed=3`）+ 可选 **`oxipng`** |
| JPEG | Image I/O 有损质量（约 80） |
| WebP | 可用时走 Image I/O |

安装命令行工具（未开启 App Sandbox，可直接用 Homebrew 路径）：

```bash
brew install pngquant oxipng
```

## 构建与运行

需要 macOS 15+ 与 Xcode 16+。

```bash
killall EggplantTinyPNG 2>/dev/null
xcodebuild -project EggplantTinyPNG.xcodeproj -scheme EggplantTinyPNG \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/EggplantTinyPNG.app
```

或：`open EggplantTinyPNG.xcodeproj`

请始终使用 `-derivedDataPath build`，并先结束正在运行的进程，否则可能打开到旧二进制。

## 文档

| 文档 | 内容 |
|------|------|
| [docs/commands.md](./docs/commands.md) | 构建、DMG、GitHub Release |
| [docs/ui.html](./docs/ui.html) | 上线 UI 示意 |
| [docs/app-icon.md](./docs/app-icon.md) | Dock / Finder 应用图标 |
| [docs/releases/v0.1.0.md](./docs/releases/v0.1.0.md) | v0.1.0 发行说明（中 / 英） |
| [AGENTS.md](./AGENTS.md) | 贡献者 / Agent 产品规则 |

## 目录结构

```
EggplantTinyPNG/
  EggplantTinyPNGApp.swift   # Window + Settings
  Models/                    # CompressItem
  Services/                  # ToolFinder、压缩器、输出路径
  ViewModels/CompressSession.swift
  UI/                        # ContentView、投放区、chrome、设置、关于
  Assets.xcassets/           # AppIcon、DropGlyph 等
```

Bundle ID：`click.yinsb.EggplantTinyPNG`
