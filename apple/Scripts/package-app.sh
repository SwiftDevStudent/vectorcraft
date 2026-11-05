#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [[ -f "$ROOT/local-build.env" ]]; then
    source "$ROOT/local-build.env"
fi
export DEVELOPER_DIR=/Applications/Xcode-27.3.0-Beta.app/Contents/Developer
XCODE_VERSION=$(/usr/bin/xcrun xcodebuild -version)
if [[ "$XCODE_VERSION" != $'Xcode 27.3\nBuild version 27C5020n' ]]; then
    printf 'Expected Xcode 27.3 build 27C5020n at %s; found %s\n' "$DEVELOPER_DIR" "$XCODE_VERSION" >&2
    exit 1
fi
CONFIGURATION=${1:-release}
BUILD_ROOT=${VECTORCRAFT_BUILD_ROOT:-"$ROOT/build/swiftpm"}
# Shared builds need no developer's keychain or private branding. Local inputs are ignored.
SIGNING_IDENTITY=${VECTORCRAFT_SIGNING_IDENTITY:--}
case "$CONFIGURATION" in debug|release) ;; *) echo 'Use debug or release.' >&2; exit 1 ;; esac
if [[ -n "${VECTORCRAFT_UI_FONTS_DIR:-}" ]]; then
    for FILE in SourceSans3-Regular.ttf SourceSans3-Semibold.ttf OFL-SourceSans3.txt; do
        test -f "$VECTORCRAFT_UI_FONTS_DIR/$FILE" || { echo "Missing workspace font input: $FILE" >&2; exit 1; }
    done
fi
if [[ -n "${VECTORCRAFT_LOCAL_ICON:-}" ]]; then
    test -f "$VECTORCRAFT_LOCAL_ICON"
    test -f "${VECTORCRAFT_LOCAL_ICON_NOTICE:?Provide provenance for the local icon.}"
fi
/usr/bin/nice -n 15 /usr/bin/xcrun swift build --package-path "$ROOT" --scratch-path "$BUILD_ROOT" -c "$CONFIGURATION" --jobs 1
BIN=$(/usr/bin/xcrun swift build --package-path "$ROOT" --scratch-path "$BUILD_ROOT" -c "$CONFIGURATION" --show-bin-path)
mkdir -p "$ROOT/build"
PACKAGE=$(/usr/bin/mktemp -d "$ROOT/build/package.XXXXXX")
APP="$PACKAGE/VectorCraft Swift.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
/bin/cp "$BIN/VectorCraftMac" "$APP/Contents/MacOS/VectorCraftMac"
/bin/cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
/bin/cp "$ROOT/LICENSE-MIT" "$ROOT/LICENSE-APACHE" "$ROOT/NOTICE" "$APP/Contents/Resources/"
if [[ -n "${VECTORCRAFT_LOCAL_ICON:-}" ]]; then
    /bin/cp "$VECTORCRAFT_LOCAL_ICON" "$APP/Contents/Resources/Vectorify.icns"
    /bin/cp "$VECTORCRAFT_LOCAL_ICON_NOTICE" "$APP/Contents/Resources/LOCAL-ICON-PROVENANCE.md"
else
    /usr/libexec/PlistBuddy -c 'Delete :CFBundleIconFile' "$APP/Contents/Info.plist"
fi
if [[ -n "${VECTORCRAFT_UI_FONTS_DIR:-}" ]]; then
    for FILE in SourceSans3-Regular.ttf SourceSans3-Semibold.ttf OFL-SourceSans3.txt; do
        /bin/cp "$VECTORCRAFT_UI_FONTS_DIR/$FILE" "$APP/Contents/Resources/"
    done
fi
RESOURCE="$BIN/VectorCraftCore_VectorCraftMac.bundle"
test -f "$RESOURCE/Contents/Resources/pen-tool.pdf"
test -f "$RESOURCE/Contents/Resources/LICENSE-lucide.txt"
/usr/bin/ditto "$RESOURCE" "$APP/Contents/Resources/VectorCraftCore_VectorCraftMac.bundle"
SIGN_ARGS=(--force --sign "$SIGNING_IDENTITY" --options runtime
    --entitlements "$ROOT/Resources/VectorCraft.entitlements")
if [[ "$SIGNING_IDENTITY" != '-' ]]; then SIGN_ARGS+=(--timestamp); fi
/usr/bin/codesign "${SIGN_ARGS[@]}" "$APP"
/usr/bin/codesign --verify --strict "$APP"
echo "$APP"
