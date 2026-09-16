#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
tag="${1:?Usage: package-release.sh vMAJOR.MINOR.PATCH}"
version=$(python3 -B -c 'import sys; sys.path.insert(0, "scripts"); from release_notes import parse_tag; print(parse_tag(sys.argv[1])[0])' "$tag")
if ! command -v create-dmg >/dev/null 2>&1; then
  echo "Install create-dmg first: brew install create-dmg" >&2
  exit 1
fi

output="$PWD/.build/release"
mkdir -p "$output"
staging=$(mktemp -d "$output/staging.XXXXXX")
trap 'rm -rf "$staging"' EXIT

for arch in arm64 x86_64; do
  derived_data="$PWD/.build/xcode-$arch"
  CONFIGURATION=Release DERIVED_DATA_PATH="$derived_data" \
    ./scripts/build.sh CODE_SIGNING_ALLOWED=NO ARCHS="$arch" ONLY_ACTIVE_ARCH=NO

  source_folder="$staging/$arch"
  mkdir -p "$source_folder"
  app="$source_folder/gogo.app"
  ditto "$derived_data/Build/Products/Release/gogo.app" "$app"
  extension="$app/Contents/PlugIns/GogoFinder.appex"

  # Set both bundle versions before signing. Build output remains unsigned so it
  # cannot accidentally register a second signed development extension locally.
  python3 - "$app" "$version" <<'PY'
import plistlib
import sys
from pathlib import Path
app, version = Path(sys.argv[1]), sys.argv[2]
for bundle in (app, app/'Contents/PlugIns/GogoFinder.appex'):
    path = bundle/'Contents/Info.plist'
    info = plistlib.loads(path.read_bytes())
    info['CFBundleShortVersionString'] = version
    info['CFBundleVersion'] = version
    path.write_bytes(plistlib.dumps(info, sort_keys=False))
PY
  for binary in "$app/Contents/MacOS/gogo" "$extension/Contents/MacOS/GogoFinder"; do
    architectures=$(lipo -archs "$binary")
    if [[ "$architectures" != "$arch" ]]; then
      echo "Expected $arch in $binary, found: $architectures" >&2
      exit 1
    fi
  done
  codesign --force --sign - --entitlements Config/Finder.entitlements "$extension"
  codesign --force --sign - --entitlements Config/Gogo.entitlements "$app"
  codesign --verify --deep --strict "$app"

  create-dmg \
    --volname "gogo $tag ($arch)" \
    --volicon Resources/AppIcon.icns \
    --window-pos 200 120 \
    --window-size 560 340 \
    --icon-size 100 \
    --text-size 12 \
    --icon "gogo.app" 150 160 \
    --hide-extension "gogo.app" \
    --app-drop-link 410 160 \
    --no-internet-enable \
    --overwrite \
    "$output/gogo-${tag}-${arch}.dmg" "$source_folder"
done
(
  cd "$output"
  shasum -a 256 "gogo-${tag}-arm64.dmg" "gogo-${tag}-x86_64.dmg" > SHA256SUMS.txt
)
