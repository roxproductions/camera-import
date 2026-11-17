#!/bin/bash
# Installs "Camera Import.app" into ~/Applications.
# Usage: curl -fsSL https://raw.githubusercontent.com/roxproductions/camera-import/main/install.sh | bash
#    or: ./install.sh   (from a cloned copy of the repo)
set -e
REPO="roxproductions/camera-import"
APP="$HOME/Applications/Camera Import.app"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

[ "$(uname)" = "Darwin" ] || { echo "Camera Import only runs on macOS."; exit 1; }

# Get the source files (local clone, or download from GitHub)
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -f "$HERE/src/import.sh" ]; then
  SRC="$HERE/src"
else
  SRC="$(mktemp -d)"
  for f in import.sh launcher.applescript; do
    curl -fsSL "https://raw.githubusercontent.com/$REPO/main/src/$f" -o "$SRC/$f"
  done
fi

# gphoto2 does the actual camera transfer
if ! command -v gphoto2 >/dev/null; then
  if command -v brew >/dev/null; then
    echo "Installing gphoto2 with Homebrew..."; brew install gphoto2
  else
    echo "Homebrew is required to install gphoto2. Install it from https://brew.sh and run this again."; exit 1
  fi
fi

# Build the app locally (no Gatekeeper warnings, since nothing is downloaded as an app)
mkdir -p "$HOME/Applications"
rm -rf "$APP"
osacompile -o "$APP" "$SRC/launcher.applescript"
cp "$SRC/import.sh" "$APP/Contents/Resources/import.sh"
chmod +x "$APP/Contents/Resources/import.sh"
codesign --force --deep -s - "$APP" 2>/dev/null || true

echo
echo "Installed: $APP"
echo "Open it from ~/Applications (or drag it to your Dock) with your camera plugged in and switched on."
