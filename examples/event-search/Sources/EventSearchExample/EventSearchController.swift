import Foundation

public struct SearchEvent: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

/// Standalone teaching example. This is not ShowFlex application source.
@MainActor
public final class EventSearchController {
    public typealias Fetch = @Sendable (String) async throws -> [SearchEvent]

    public private(set) var query = ""
    public private(set) var results: [SearchEvent] = []
    public private(set) var selectedEventID: String?
    public private(set) var isSearching = false
    public private(set) var errorMessage: String?

    public var selectedEvent: SearchEvent? {
        results.first { $0.id == selectedEventID }
    }

    private let fetch: Fetch
    private let debounce: Duration
    private var revision: UInt64 = 0
    private var pending: Task<Void, Never>?

    public init(debounce: Duration = .milliseconds(300), fetch: @escaping Fetch) {
        self.debounce = debounce
        self.fetch = fetch
    }

    /// Returns a task for callers that need to await this particular request.
    @discardableResult
    public func search(_ text: String) -> Task<Void, Never>? {
        revision &+= 1
        let requestRevision = revision
        pending?.cancel()
        pending = nil
        query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        results = []
        selectedEventID = nil
        errorMessage = nil
        isSearching = !query.isEmpty
        guard !query.isEmpty else { return nil }

        let requestedQuery = query
        let fetch = self.fetch
        let debounce = self.debounce
        let task = Task { [weak self] in
            do {
                try await Task.sleep(for: debounce)
                try Task.checkCancellation()
                let found = try await fetch(requestedQuery)
                try Task.checkCancellation()
                guard let self, self.revision == requestRevision else { return }
                self.results = found
                self.isSearching = false
                self.pending = nil
            } catch is CancellationError {
                guard let self, self.revision == requestRevision else { return }
                self.isSearching = false
                self.pending = nil
            } catch {
                // A stale request can also fail. It must not publish that error.
                guard let self, self.revision == requestRevision else { return }
                self.errorMessage = String(describing: error)
                self.isSearching = false
                self.pending = nil
            }
        }
        pending = task
        return task
    }

    public func select(_ id: String?) {
        selectedEventID = id.flatMap { candidate in
            results.contains { $0.id == candidate } ? candidate : nil
        }
    }

    /// The owner should call this when the search surface goes away.
    public func cancel() {
        revision &+= 1
        pending?.cancel()
        pending = nil
        isSearching = false
    }
}
