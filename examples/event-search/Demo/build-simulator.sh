#!/bin/sh
set -eu
demo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
package_dir=$(dirname -- "$demo_dir")
bundle_dir="$package_dir/.build/demo/EventSearchDemo.app"
mkdir -p "$bundle_dir"
sdk_dir=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun swiftc -parse-as-library -target arm64-apple-ios16.0-simulator -sdk "$sdk_dir" \
  "$package_dir/Sources/EventSearchExample/EventSearchController.swift" \
  "$demo_dir/DemoSearchModel.swift" "$demo_dir/EventSearchDemo.swift" -o "$bundle_dir/EventSearchDemo"
cp "$demo_dir/Info.plist" "$bundle_dir/Info.plist"
codesign --force --sign - "$bundle_dir"
printf '%s\n' "$bundle_dir"
