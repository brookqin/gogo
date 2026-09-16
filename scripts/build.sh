#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
iconset=".build/AppIcon.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" Assets/AppIcon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" Assets/AppIcon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o Resources/AppIcon.icns
python3 scripts/generate-project.py
xcodebuild -project gogo.xcodeproj -scheme gogo -configuration Debug -derivedDataPath .build/xcode "$@" build
