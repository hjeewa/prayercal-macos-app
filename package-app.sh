#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h}
app_dir="$project_dir/outputs/PrayerCal.app"
version=$(<"$project_dir/VERSION")
build_number=${BUILD_NUMBER:-$(git -C "$project_dir" rev-list --count HEAD 2>/dev/null || echo 1)}

if [[ -d "$app_dir" ]]; then
    previous_build_dir=$(mktemp -d)
    mv "$app_dir" "$previous_build_dir/PrayerCal.app"
fi

swift build -c release --arch arm64 --arch x86_64 --package-path "$project_dir"
mkdir -p "$app_dir/Contents/MacOS"
mkdir -p "$app_dir/Contents/Frameworks"
mkdir -p "$app_dir/Contents/Resources"
cp "$project_dir/.build/apple/Products/Release/PrayerCal" "$app_dir/Contents/MacOS/PrayerCal"
ditto "$project_dir/.build/apple/Products/Release/Frameworks/Sparkle.framework" "$app_dir/Contents/Frameworks/Sparkle.framework"
cp "$project_dir/Config/PrayerCal.icns" "$app_dir/Contents/Resources/PrayerCal.icns"
cp "$project_dir/Sources/PrayerCal/Resources/PrayerCalIcon.svg" "$app_dir/Contents/Resources/PrayerCalIcon.svg"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$app_dir/Contents/MacOS/PrayerCal"
cp "$project_dir/Config/Info.plist" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "$app_dir/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$app_dir/Contents/Info.plist"
codesign --force --deep --sign - "$app_dir"

ditto -c -k --sequesterRsrc --keepParent "$app_dir" "$project_dir/outputs/PrayerCal.zip"
echo "$app_dir"
