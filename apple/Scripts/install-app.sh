#!/usr/bin/env bash
set -euo pipefail

# Install a fully built bundle. Keep every previous installation recoverable.
APP=${1:?Pass the packaged VectorCraft Swift.app path.}
DESTINATION='/Applications/VectorCraft Swift.app'
test -x "$APP/Contents/MacOS/VectorCraftMac"
/usr/bin/codesign --verify --strict "$APP"
if /usr/bin/pgrep -x VectorCraftMac >/dev/null; then
    echo 'Quit VectorCraft Swift before replacing the installed app.' >&2
    exit 1
fi
STAGING="/Applications/.VectorCraft-Swift-$(/usr/bin/uuidgen).app"
/usr/bin/ditto "$APP" "$STAGING"
if [[ -e "$DESTINATION" ]]; then
    test -d "$HOME/.Trash" || { echo 'Trash is unavailable; installation stopped.' >&2; exit 1; }
    /bin/mv -n "$DESTINATION" "$HOME/.Trash/VectorCraft-Swift-$(/usr/bin/uuidgen).app"
    test ! -e "$DESTINATION" || { echo 'Could not preserve the old app; installation stopped.' >&2; exit 1; }
fi
/bin/mv -n "$STAGING" "$DESTINATION"
if ! /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -u "$APP"; then
    # A never-launched package may be unknown to Launch Services (-10814).
    # The canonical app still needs registration after the completed replacement.
    printf 'Could not unregister the build bundle; registering the installed app.\n' >&2
fi
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$DESTINATION"
echo "$DESTINATION"
