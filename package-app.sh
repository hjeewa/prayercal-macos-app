#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h}
app_dir="$project_dir/outputs/HijriBar.app"
version=$(<"$project_dir/VERSION")
build_number=${BUILD_NUMBER:-$(git -C "$project_dir" rev-list --count HEAD 2>/dev/null || echo 1)}

swift build -c release --arch arm64 --arch x86_64 --package-path "$project_dir"
mkdir -p "$app_dir/Contents/MacOS"
cp "$project_dir/.build/apple/Products/Release/HijriBar" "$app_dir/Contents/MacOS/HijriBar"
cp "$project_dir/Config/Info.plist" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$app_dir/Contents/Info.plist"
codesign --force --deep --sign - "$app_dir"

ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$project_dir/outputs/HijriBar.zip"
echo "$app_dir"
