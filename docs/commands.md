# Commands — EggplantTinyPNG

## Build & run (Debug)

```bash
killall EggplantTinyPNG 2>/dev/null
xcodebuild -project EggplantTinyPNG.xcodeproj -scheme EggplantTinyPNG \
  -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/EggplantTinyPNG.app
```

Always `-derivedDataPath build`. Kill the app first so you do not open a stale process.

## Release build (local)

```bash
xcodebuild -project EggplantTinyPNG.xcodeproj -scheme EggplantTinyPNG \
  -configuration Release -derivedDataPath build \
  -destination 'generic/platform=macOS' build \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM=""
open build/Build/Products/Release/EggplantTinyPNG.app
```

## DMG (local)

```bash
ARCHIVE=build/EggplantTinyPNG.xcarchive
STAGE=build/dmg-stage
DMG=build/EggplantTinyPNG-v0.2.0.dmg

xcodebuild archive \
  -project EggplantTinyPNG.xcodeproj -scheme EggplantTinyPNG \
  -configuration Release -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="-" DEVELOPMENT_TEAM="" SKIP_INSTALL=NO

rm -rf "$STAGE" && mkdir -p "$STAGE"
cp -R "$ARCHIVE/Products/Applications/EggplantTinyPNG.app" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname EggplantTinyPNG -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"
open -R "$DMG"
```

After install from an ad-hoc DMG: `xattr -cr /Applications/EggplantTinyPNG.app`.

## GitHub Release (CI/CD)

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `ci.yml` | Push / PR to `main` | Release build (ad-hoc signed) |
| `release.yml` | Tag `v*` (or manual dispatch) | Archive → DMG → GitHub Release |

Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in the Xcode project. For a release:

1. Add bilingual notes at `docs/releases/vX.Y.Z.md` (optional but preferred)
2. Commit and push `main`
3. Tag and push:

```bash
git tag v0.2.0
git push origin main
git push origin v0.2.0
```

Actions builds `EggplantTinyPNG-v0.2.0.dmg` and attaches it to [Releases](https://github.com/uniquejava/EggplantTinyPNG/releases).

Re-run without a new tag: Actions → **Release** → **Run workflow** → enter tag (e.g. `v0.2.0`).

## Clean

```bash
rm -rf build
killall EggplantTinyPNG 2>/dev/null || true
```
