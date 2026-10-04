import Foundation
import Combine

@MainActor
final class DemoSearchModel: ObservableObject {
    @Published var text = ""
    @Published private(set) var results: [SearchEvent] = []
    @Published private(set) var isSearching = false
    @Published private(set) var selected: SearchEvent?
    @Published private(set) var error: String?
    @Published private(set) var activity = "Synthetic events only. No network or account."
    private var version = 0
    private var raceTask: Task<Void, Never>?
    private let controller = EventSearchController(debounce: .milliseconds(180)) { query in
        // Deliberately non-cooperative: cancellation does not stop this fixture.
        // The controller must still refuse to publish its stale completion.
        let delay = query == "slow" ? 1.5 : 0.2
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { continuation.resume() }
        }
        if query == "error" { throw DemoError.syntheticFailure }
        if query == "slow" { return [SearchEvent(id: "slow", title: "Old slow request")] }
        if query == "fast" { return [SearchEvent(id: "fast", title: "Latest fast request")] }
        let fixtures = [SearchEvent(id: "posing", title: "Posing workshop"),
                        SearchEvent(id: "strength", title: "Strength meet"),
                        SearchEvent(id: "clinic", title: "Powerlifting clinic")]
        return fixtures.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    func search(_ query: String) {
        version += 1
        let ownedVersion = version
        text = query
        let pending = controller.search(query)
        publish()
        guard let pending else { activity = "Empty query clears results and selection."; return }
        activity = "Searching synthetic fixtures for \(controller.query)…"
        Task { [weak self] in
            await pending.value
            guard let self, self.version == ownedVersion else { return }
            self.publish()
            self.activity = self.error == nil ? "Latest request settled: \(self.results.count) result(s)." : "Synthetic error is visible; retry with another query."
        }
    }

    func select(_ id: String) {
        controller.select(id)
        publish()
    }

    func runRace() {
        raceTask?.cancel()
        search("slow")
        raceTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(450)) }
            catch { return }
            guard !Task.isCancelled, let self else { return }
            self.search("fast")
            self.activity = "Slow request is still in flight. The fast request owns the screen."
        }
    }

    func cancel() {
        raceTask?.cancel()
        version += 1
        controller.cancel()
        publish()
        activity = "Cancelled. A late completion cannot take ownership."
    }

    private func publish() {
        results = controller.results
        isSearching = controller.isSearching
        selected = controller.selectedEvent
        error = controller.errorMessage
    }
}

enum DemoError: Error { case syntheticFailure }

