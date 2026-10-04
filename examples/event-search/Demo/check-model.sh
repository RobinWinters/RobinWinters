#!/bin/sh
set -eu
demo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
package_dir=$(dirname -- "$demo_dir")
mkdir -p "$package_dir/.build/demo"
xcrun swiftc -parse-as-library \
  "$package_dir/Sources/EventSearchExample/EventSearchController.swift" \
  "$demo_dir/DemoSearchModel.swift" "$demo_dir/DemoModelChecks.swift" \
  -o "$package_dir/.build/demo/demo-model-checks"
"$package_dir/.build/demo/demo-model-checks"
