# Verify a Swift package’s minimum toolchain and CLI contract

Robin Winters · October 3, 2026

I’m an iOS / Full Stack Engineer at ShowFlex, a shipped [iPhone fitness product](https://apps.apple.com/us/app/showflex/id6757890910). This article examines a separate, public Swift teaching package prepared with coding-assistant support. Its fixtures are synthetic; the results below are not a test report for ShowFlex.

A package that passes on my current Mac has established something useful. It has not established that another person can build it on the oldest supported tools, on Linux, or with an unexpected command-line input. Those are different questions, and each needs a concrete check.

The [fitness event data pipeline](https://github.com/RobinWinters/fitness-event-data-pipeline) declares Swift tools version 6.0 and provides a library plus a `normalize-events` executable. The example turns synthetic event records into normalized events and decision receipts. Release [0.1.1](https://github.com/RobinWinters/fitness-event-data-pipeline/releases/tag/0.1.1) adds compatibility evidence without changing the library, executable source, tests or fixtures from 0.1.0.

## Record what actually ran

The manifest’s [Swift tools version](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html#about-the-swift-tools-version) specifies a minimum tools requirement. It is a declaration, rather than evidence that this package was executed with those tools.

The public [workflow run](https://github.com/RobinWinters/fitness-event-data-pipeline/actions/runs/37172573330) records three successful environments:

| Environment | Observed compiler | Checks |
| --- | --- | --- |
| Linux, official Swift container | Swift 6.0.3 | 12 unit tests and an exact fixture-output comparison |
| macOS 15 runner | Apple Swift 6.1.2 | 12 unit tests and four CLI contract cases |
| Ubuntu 24.04 runner | Swift 6.4 | 12 unit tests and four CLI contract cases |

These are the same 12 unit tests executed in three environments. They are not 36 distinct tests. Swift 6.0.3 supplies evidence for a specific compiler in the declared 6.0 line; it does not prove an execution on 6.0.0. The package’s iOS deployment declaration likewise does not establish an iPhone runtime result.

Each job prints `swift --version` before building. Runner labels alone are too imprecise for the compatibility record: the compiler observed on a hosted runner can change.

## Test the executable boundary separately

Library tests can pass while the executable’s exit status, output stream or input decoding is wrong. The host-runner jobs invoke [Scripts/check-fixture.py](https://github.com/RobinWinters/fitness-event-data-pipeline/blob/6533f5289666f047a3684d6f352468fff8f9bc28/Scripts/check-fixture.py), which checks four cases:

1. The complete synthetic fixture succeeds, writes no error, and produces the expected normalized events and receipts.
2. An empty array succeeds with empty events and receipts.
3. Malformed JSON exits with status 1, emits no success report, and writes the specified input-contract error to stderr.
4. An object in place of the expected array produces the same rejection behavior.

The fixture assertion compares the complete decoded JSON document. Checking only the event count would miss changes to identities, timestamps or conflict receipts. The rejection checks inspect stdout as well as stderr: an error message is insufficient if the process also emits an apparently successful report.

The Swift 6.0.3 job runs a narrower check: it executes the valid fixture and uses `diff` against the expected output file. It does **not** run the other three CLI cases. Keeping that distinction visible makes the evidence easier to trust.

## Reproduce the release checks

On a machine with Git, Swift and Python 3, check out the published tag:

```sh
git clone https://github.com/RobinWinters/fitness-event-data-pipeline.git
cd fitness-event-data-pipeline
git checkout 0.1.1
swift --version
swift build
swift test
python3 Scripts/check-fixture.py
```

The Python script uses the standard library. Its four-case check expects the debug executable produced by the preceding build. The versioned [compatibility record](https://github.com/RobinWinters/fitness-event-data-pipeline/blob/0.1.1/compatibility.json) distinguishes these host checks from the container’s narrower comparison.

## State the remaining gaps

The workflow uses read-only repository permissions, a pinned checkout action and a pinned minimum-toolchain container. It needs no private application credentials. Those choices make this small public example reproducible without connecting it to a production backend.

The checks establish the recorded package behavior in the recorded environments. They do not establish physical-device execution, private product behavior, performance under real event feeds, or automatic compatibility with every later compiler. A useful next compatibility check should answer one of those unresolved questions, rather than add another badge for the same run.

For native product work, the habit carries over: distinguish an API declaration, a successful build, a tested boundary and an observed user interaction. Each is valuable; each supports a different claim.

Robin Winters works on Swift, SwiftUI, MapKit and Firebase at ShowFlex. [Professional reference](https://robinwinters.github.io/review/ios.html) · [robin.ac](https://robin.ac/). This self-authored technical account was prepared with editorial and coding-assistant support.
