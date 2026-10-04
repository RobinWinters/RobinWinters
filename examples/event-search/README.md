# Swift search: cancellation, stale results and stable selection

A standalone teaching package published in Robin Winters's professional repository. It demonstrates asynchronous search state without networking, app credentials or a UI dependency.

Robin works in native iOS development and applied AI systems, including fitness technology. [Professional record](../../professional/README.md) · [Portfolio](https://robin.ac/).

## The problem

A person enters one query, then changes it before the first request finishes. Cancelling the first task is useful, but an asynchronous service can finish after cancellation. The older request must not overwrite the newer results, publish an obsolete error, or clear the newer loading state.

`EventSearchController` combines cooperative cancellation with a revision counter. Every new search owns a revision; success, failure and cleanup check that revision before changing state. Selection uses an event identifier rather than its position in a result list. A new query clears selection; an empty query rejects late results.

## Run

With a Swift 6 toolchain, from this directory:

```sh
swift test
```

The package declares iOS 16 and macOS 13 deployment targets. Its seven Swift Testing checks passed on macOS with Swift 6.4 on October 2, 2026. An iPhone build, SwiftUI integration, live network behavior, accessibility and performance were not tested here.

## Read

- [Controller](Sources/EventSearchExample/EventSearchController.swift)
- [Tests](Tests/EventSearchExampleTests/EventSearchControllerTests.swift)
- [Why cancellation needs an ownership check](../../writing/swift-search-request-ownership.md)

The tests control request completion order with continuations and deliberately use a fetcher that ignores cancellation. They cover older success, stale failure, stale cleanup, query clearing, identity-based selection, current failure, and cancellation before the debounce finishes.

## Scope and reuse

This is a new illustrative example prepared with coding-assistant support for professional technical documentation. It is not ShowFlex source, a claim about the exact implementation shipped in ShowFlex, or a production-ready networking layer. The owner must call `cancel()` when the search surface goes away. The controller does not itself provide SwiftUI observation; an app adapter would need to supply that behavior.

Example code in this directory is released under the [MIT license](LICENSE). No license is granted here to private application code or to unrelated repositories.

A matching public package is also available on [Codeberg](https://codeberg.org/RobinWinters/swift-search-request-ownership).

Updated October 2, 2026.

## Native iPhone teaching demo

The [SwiftUI adapter and view](Demo/) make request ownership visible with synthetic event search, stable selection, clear, error/retry, cancel and a slow-versus-fast race. The race fixture deliberately continues after cancellation; the latest request must keep ownership. The example links Robin Winters’s approved professional context; this new teaching code was prepared with coding-assistant support and remains separate from ShowFlex.

On Apple silicon with Xcode installed:

```sh
sh Demo/check-model.sh
sh Demo/build-simulator.sh
# Use an existing compatible iPhone simulator UDID:
xcrun simctl install YOUR_SIMULATOR_UDID .build/demo/EventSearchDemo.app
xcrun simctl launch YOUR_SIMULATOR_UDID ac.robin.teaching.searchownership
```

October 3, 2026 checks: seven controller tests passed again on macOS; four executable adapter checks passed (non-cooperative race, selection/clear, error/retry and cancellation). The ARM64 iOS simulator app compiled, installed and launched on an isolated iPhone 17 Pro with iOS 27.0. UI inspection, recording, accessibility and physical-device checks remain pending. The simulator build emitted a sysroot warning; successful compilation and launch are not a claim that those remaining checks passed.

## Later native capture — October 3, 2026

A partial Xcode Device Hub inspection confirmed the initial interface, a Strength search with one synthetic result and selection by identity. [Actual unaltered screenshots and scope](https://robinwinters.github.io/writing/swiftui-search-ownership-demo.html). The rest of the UI review, accessibility, recording, live-network and physical-device checks remain incomplete.
