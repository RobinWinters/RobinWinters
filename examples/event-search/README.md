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

## Public continuous checks — October 3, 2026

The [native teaching-demo workflow](https://github.com/RobinWinters/RobinWinters/actions/workflows/event-search-demo.yml) now checks changes to this example. [Verified successful run](https://github.com/RobinWinters/RobinWinters/actions/runs/37178664069), source revision `73e563b44bd33f6c883d814df8d1013fa0dfb9bb`:

| Host | Observed Swift | Observed Xcode | Simulator SDK | Checks |
|---|---|---|---|---|
| macOS 15 ARM64 | 6.1.2 | 16.4 (16F6) | 18.5 | 7 controller tests; 4 adapter checks |
| macOS 26 ARM64 | 6.3.3 | 26.6 (17F113) | 26.5 | The same 7 controller tests; the same 4 adapter checks |

Both jobs compiled the ARM64 iOS simulator app, verified its IOSSIMULATOR platform and iOS 16 minimum target, and passed strict verification of its ad hoc signature. The build still emits a sysroot warning. These jobs do not launch the simulator UI, run on a physical device or test private ShowFlex code. The earlier partial local UI inspection is separate evidence. An initial workflow run failed because the architecture-check command had its arguments in the wrong order; the linked successful revision corrects that check.

## Reproduce native interface checks

Open `Demo/EventSearchDemo.xcodeproj` and use its shared `EventSearchDemo` scheme, or run with an existing compatible iPhone simulator:

```sh
xcodebuild test -project Demo/EventSearchDemo.xcodeproj \
  -scheme EventSearchDemo \
  -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  -parallel-testing-enabled NO \
  -derivedDataPath .build/ui-testing \
  -resultBundlePath .build/ui-tests.xcresult CODE_SIGNING_ALLOWED=NO
```

The UI test target exercises search/selection/clear, synthetic error/retry, fast-request ownership after a slow completion, and cancellation while work is pending. The cancellation test extends the synthetic slow fixture to 30 seconds using a bounded launch-environment setting and observes for 32.5 seconds after cancelling; ordinary interactive runs retain the 1.5-second fixture. Its screenshots are captured by XCTest from the running simulator. Test definitions and a successful test-target build are preparation; the recorded execution result must be checked separately. The workflow retains a small, capped evidence artifact for one day. Accessibility identifiers support test selection; they do not establish a VoiceOver or accessibility audit.

## Observed native interface execution — October 4, 2026

Four UI tests passed on an iPhone Air simulator running iOS 26.5 in [the public run](https://github.com/RobinWinters/RobinWinters/actions/runs/37217793499). The tests cover selection/clear, error/retry, slow/fast ownership and pending cancellation. [Exact observed scope and screenshot provenance](Demo/ui-verification-2026-10-04.json) · [Unmodified runtime captures](https://robinwinters.github.io/writing/swiftui-search-ownership-demo.html). Physical-device, accessibility, performance and private ShowFlex verification remain separate.

## Record the actual interface run

The workflow now builds the test bundle first, then uses Apple's `simctl recordVideo` to capture the real simulator framebuffer while those same four XCTest interactions run. The recorder waits for the first-frame acknowledgment and stops with SIGINT so the MP4 can be finalized. The one-day artifact includes the original recording, recorder log, source revision, tool/device environment, XCTest summary and screenshots, with a 32 MiB total cap. A recorder receipt alone does not prove a successful test suite or playable video; inspect the actual run, results and playback before relying on it. A first hosted recording attempt timed out after the ten-second first-frame wait and an unbounded recorder cleanup; no interface-test or finished-video result is claimed for that attempt. The revised script bounds boot readiness to three minutes, first-frame startup to ninety seconds and finalization to ten seconds. A migration warning with a successful boot-command exit is retained in the log rather than treated as an independently proven fatal error. The same four interface tests remain unchanged.

After the `build-for-testing` command used in the workflow, run `DEMO_SIMULATOR_UDID=YOUR_SIMULATOR_UDID bash Demo/record-interface-run.sh` from this package directory. This is synthetic teaching-demo footage. A ShowFlex product walkthrough, physical-device testing and accessibility/performance review remain separate work. [Apple's simulator recording guidance](https://developer.apple.com/videos/play/wwdc2020/10647/).

## Verified original recording — October 4, 2026

[The repaired recording run](https://github.com/RobinWinters/RobinWinters/actions/runs/37227053548), tested revision `de155d8e56a1d85696236bb4fb24ac00a9e2a942`, passed all three jobs, including the unchanged four native UI tests with zero failures and zero skips. The actual artifact was downloaded and its digest/CRC checked. The original MP4 decoded and played at 1260×2736 for 234.175 seconds; seek checks included the cancelled late-request interface. This was a sampled playback review, not a frame-by-frame audit.

[Watch the unedited recording and read the test summary](https://robinwinters.github.io/writing/swiftui-search-ownership-demo.html#recorded-interface) · [Source, device, results and media provenance](Demo/video-verification-2026-10-04.json). The representative poster is an unmodified XCTest screenshot from the same run. This synthetic teaching example remains separate from private ShowFlex code and physical-device, accessibility and performance testing.
