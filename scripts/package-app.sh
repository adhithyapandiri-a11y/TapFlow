#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
app_dir="$project_root/outputs/TapFlow.app"
contents_dir="$app_dir/Contents"
iconset_dir="$project_root/.build/AppIcon.iconset"

swift "$project_root/scripts/make-app-icon.swift" \
  "$project_root/Resources/AppIcon-source.png" "$iconset_dir"
iconutil -c icns "$iconset_dir" -o "$project_root/Resources/AppIcon.icns"

swift build -c release --product TapFlow --package-path "$project_root"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp -f "$project_root/.build/release/TapFlow" "$contents_dir/MacOS/TapFlow"
cp -f "$project_root/Resources/Info.plist" "$contents_dir/Info.plist"
cp -f "$project_root/Resources/AppIcon.icns" "$contents_dir/Resources/AppIcon.icns"
chmod +x "$contents_dir/MacOS/TapFlow"

printf 'Created %s\n' "$app_dir"
