#!/bin/bash
# Build WizControl.app from the SPM package (no Xcode required).
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="build/WizControl.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp ".build/release/WizControl" "$APP/Contents/MacOS/WizControl"
cp "Resources/Info.plist" "$APP/Contents/Info.plist"

codesign --force --sign - "$APP"

echo "Built $APP"
echo "Run it with:  open $APP"
echo "Or install:   cp -R $APP /Applications/"
