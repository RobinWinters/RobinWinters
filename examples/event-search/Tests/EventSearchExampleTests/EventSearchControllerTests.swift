import Testing
@testable import EventSearchExample

private enum DemoFailure: Error { case offline }

/// Deliberately ignores task cancellation until the test resolves its continuation.
private actor ControlledFetch {
    private var requests: [String: CheckedContinuation<[SearchEvent], any Error>] = [:]
    private var starts: [String: [CheckedContinuation<Void, Never>]] = [:]

    func fetch(_ query: String) async throws -> [SearchEvent] {
        try await withCheckedThrowingContinuation { continuation in
            requests[query] = continuation
            starts.removeValue(forKey: query)?.forEach { $0.resume() }
        }
    }

    func waitUntilStarted(_ query: String) async {
        if requests[query] != nil { return }
        await withCheckedContinuation { starts[query, default: []].append($0) }
    }

    func succeed(_ query: String, events: [SearchEvent]) {
        requests.removeValue(forKey: query)?.resume(returning: events)
    }

    func fail(_ query: String) {
        requests.removeValue(forKey: query)?.resume(throwing: DemoFailure.offline)
    }
}

@Suite @MainActor
struct EventSearchControllerTests {
    @Test func olderSuccessfulRequestCannotOverwriteNewerResults() async {
        let service = ControlledFetch()
        let model = EventSearchController(debounce: .zero) { try await service.fetch($0) }
        let older = model.search("old")
        await service.waitUntilStarted("old")
        let newer = model.search("new")
        await service.waitUntilStarted("new")
        await service.succeed("new", events: [.init(id: "n", title: "New event")])
        await newer?.value
        await service.succeed("old", events: [.init(id: "o", title: "Old event")])
        await older?.value
        #expect(model.query == "new")
        #expect(model.results.map(\.id) == ["n"])
        #expect(model.errorMessage == nil)
    }

    @Test func staleFailureCannotReplaceCurrentSuccess() async {
        let service = ControlledFetch()
        let model = EventSearchController(debounce: .zero) { try await service.fetch($0) }
        let older = model.search("old")
        await service.waitUntilStarted("old")
        let newer = model.search("new")
        await service.waitUntilStarted("new")
        await service.succeed("new", events: [.init(id: "n", title: "New event")])
        await newer?.value
        await service.fail("old")
        await older?.value
        #expect(model.results.map(\.id) == ["n"])
        #expect(model.errorMessage == nil)
        #expect(!model.isSearching)
    }

    @Test func staleCleanupCannotEndNewerLoadingState() async {
        let service = ControlledFetch()
        let model = EventSearchController(debounce: .zero) { try await service.fetch($0) }
        let older = model.search("old")
        await service.waitUntilStarted("old")
        let newer = model.search("new")
        await service.waitUntilStarted("new")
        await service.fail("old")
        await older?.value
        #expect(model.isSearching)
        model.cancel()
        await service.succeed("new", events: [.init(id: "n", title: "New event")])
        await newer?.value
        #expect(model.results.isEmpty)
        #expect(!model.isSearching)
    }

    @Test func clearingTheQueryRejectsLateResults() async {
        let service = ControlledFetch()
        let model = EventSearchController(debounce: .zero) { try await service.fetch($0) }
        let pending = model.search("events")
        await service.waitUntilStarted("events")
        #expect(model.search(" \n ") == nil)
        await service.succeed("events", events: [.init(id: "e", title: "Late event")])
        await pending?.value
        #expect(model.query.isEmpty)
        #expect(model.results.isEmpty)
        #expect(!model.isSearching)
    }

    @Test func selectionUsesIdentityAndResetsForANewQuery() async {
        let model = EventSearchController(debounce: .zero) { _ in
            [.init(id: "a", title: "Same title"), .init(id: "b", title: "Same title")]
        }
        await model.search("events")?.value
        model.select("b")
        #expect(model.selectedEvent?.id == "b")
        model.select("missing")
        #expect(model.selectedEvent == nil)
        model.select("a")
        await model.search("other")?.value
        #expect(model.selectedEventID == nil)
    }

    @Test func currentFailureIsVisible() async {
        let model = EventSearchController(debounce: .zero) { _ in throw DemoFailure.offline }
        await model.search("events")?.value
        #expect(model.results.isEmpty)
        #expect(model.errorMessage != nil)
        #expect(!model.isSearching)
    }

    @Test func cancellingBeforeDebouncePreventsFetch() async {
        let model = EventSearchController(debounce: .seconds(10)) { _ in
            Issue.record("Cancelled debounce must not start a fetch")
            return []
        }
        let task = model.search("events")
        model.cancel()
        await task?.value
        #expect(!model.isSearching)
        #expect(model.results.isEmpty)
    }
}
