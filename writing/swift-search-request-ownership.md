# Swift search: cancellation needs an ownership check

Robin Winters · October 2, 2026 · Educational example prepared with coding-assistant support

Search often looks simple until two requests finish in the wrong order. A user enters “San”, changes the query to “San Francisco”, and sees the shorter query's results arrive last. The newer request may have finished correctly; the older task still owns enough code to replace the result list.

Debouncing reduces the number of requests. Cancellation tells an obsolete task to stop. Neither operation alone states which request is allowed to change the current interface. That ownership rule is the useful part of the [standalone example](../examples/event-search/README.md).

## Cancellation is cooperative

Swift task cancellation signals a task rather than forcibly terminating arbitrary work. The task and functions it calls must observe that signal. A cancellation-aware sleep can throw before the fetch starts, while an injected fetcher might finish despite being cancelled. Apple's [Task.cancel documentation](https://developer.apple.com/documentation/swift/task/cancel()) describes this cooperative behavior.

The example checks cancellation after the debounce and after the fetch. It also assigns each search a revision. Starting another search or explicitly cancelling advances that revision. Before publishing results, an error, or cleanup, the task verifies that its revision still matches the controller's current revision.

```swift
let found = try await fetch(requestedQuery)
try Task.checkCancellation()
guard let self, self.revision == requestRevision else { return }
self.results = found
self.isSearching = false
self.pending = nil
```

The controller is isolated to `MainActor`, so these state changes happen together in that isolation domain. Fetching remains asynchronous. The revision check is especially useful across an `await`, where another search can have started before the old operation resumes.

## Errors and cleanup need the same rule

Protecting only successful results leaves two quieter bugs. An obsolete request can fail and replace a valid result with an irrelevant error. Or its cleanup can set `isSearching` to false while the newer search is still running. Clearing the stored pending task from stale cleanup can also lose the handle needed to cancel the current request.

For that reason, every completion path checks request ownership. Current errors are displayed; obsolete errors are ignored. Only the current request can clear its loading state or pending handle. Explicit cancellation updates the controller immediately rather than waiting for a service to acknowledge the signal.

## Selection belongs to an identity

Result order changes. Two events can have the same title. Keeping a selected array index or comparing titles can therefore select a different event after results change. This example stores `selectedEventID` and resolves it against the current list.

The policy is deliberately simple: starting a new query clears previous results and selection. Clearing the query produces an empty idle state and invalidates pending work. A product could keep previous results while refreshing, but it would need to explain that distinction in its state model and tests.

## Test the troublesome ordering directly

The seven tests use a controlled asynchronous fetcher. A test waits until a request starts, starts a second request, and chooses exactly when each one succeeds or fails. The fetcher intentionally ignores cancellation until the test resolves its continuation. This tests the failure mode that a polite mock service would conceal.

The checks cover late successful results, obsolete failures, stale cleanup, an empty query, selection by identifier, a current error, and cancellation during debounce. They passed with Swift 6.4 on macOS on October 2, 2026. No live server, iPhone runtime, SwiftUI adapter or performance benchmark was part of that validation.

The pattern applies anywhere an interface can supersede asynchronous work: search suggestions, filters, geocoding or remote detail loading. Each product still needs its own rules for retaining results, displaying errors, leaving a screen and restoring selection. The package makes one such set of rules explicit and testable.

[Code and tests](../examples/event-search/README.md) · [Robin's professional background](../professional/README.md) · [robin.ac](https://robin.ac/)
