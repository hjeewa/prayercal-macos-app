#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h}
version=$(<"$project_dir/VERSION")
dmg_path="$project_dir/outputs/PrayerCal.dmg"
staging_dir=$(mktemp -d)
code_sign_identity=${CODE_SIGN_IDENTITY:--}

cleanup() {
    rm -rf "$staging_dir"
}
trap cleanup EXIT

"$project_dir/package-app.sh"
cp -R "$project_dir/outputs/PrayerCal.app" "$staging_dir/PrayerCal.app"
ln -s /Applications "$staging_dir/Applications"

hdiutil create \
    -volname "PrayerCal $version" \
    -srcfolder "$staging_dir" \
    -ov \
    -format UDZO \
    "$dmg_path"

if [[ "$code_sign_identity" != "-" ]]; then
    codesign --force --timestamp --sign "$code_sign_identity" "$dmg_path"
fi

echo "$dmg_path"
