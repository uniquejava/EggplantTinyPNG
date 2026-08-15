# App icon (Dock / Finder / About)

| Rule | Value |
|------|--------|
| Master | `EggplantTinyPNG/Assets.xcassets/AppIcon.appiconset/AppIcon-1024-master.png` |
| Shape | Continuous rounded rect, corner radius ≈ **22.37%** of edge |
| Corners | **Transparent** outside the rounded rect |
| Art | Stacked photos + compress cue on eggplant-purple field |

```bash
python3 scripts/generate_app_icons.py
killall EggplantTinyPNG 2>/dev/null
xcodebuild -project EggplantTinyPNG.xcodeproj -scheme EggplantTinyPNG \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/EggplantTinyPNG.app
```

Menu bar uses template `DropGlyph` — not this color App Icon.
