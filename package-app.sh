#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h}
app_dir="$project_dir/outputs/HijriBar.app"

swift build -c release --package-path "$project_dir"
mkdir -p "$app_dir/Contents/MacOS"
cp "$project_dir/.build/release/HijriBar" "$app_dir/Contents/MacOS/HijriBar"
cp "$project_dir/Config/Info.plist" "$app_dir/Contents/Info.plist"
codesign --force --deep --sign - "$app_dir"

ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$project_dir/outputs/HijriBar.zip"
echo "$app_dir"
