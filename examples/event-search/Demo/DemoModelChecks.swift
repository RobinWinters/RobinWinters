import Foundation

@main
struct DemoModelChecks {
    @MainActor
    static func until(_ description: String, _ predicate: () -> Bool) async {
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while !predicate(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(10))
        }
        precondition(predicate(), description)
    }

    @MainActor
    static func main() async {
        let model = DemoSearchModel()
        model.runRace()
        await until("Latest request did not settle") { model.results.first?.id == "fast" && !model.isSearching }
        try? await Task.sleep(for: .seconds(2))
        precondition(model.text == "fast" && model.results.map(\.id) == ["fast"])
        print("PASS race: late non-cooperative completion did not replace fast results")

        model.search("strength")
        await until("Strength fixture did not settle") { model.results.map(\.id) == ["strength"] }
        model.select("strength")
        precondition(model.selected?.id == "strength")
        model.search("")
        precondition(model.results.isEmpty && model.selected == nil && !model.isSearching)
        print("PASS selection and clear: identity selection resets for a new query")

        model.search("error")
        await until("Current error did not publish") { model.error != nil && !model.isSearching }
        model.search("posing")
        await until("Retry did not settle") { model.results.map(\.id) == ["posing"] }
        precondition(model.error == nil)
        print("PASS error and retry: current error clears on a successful new query")

        model.search("slow")
        try? await Task.sleep(for: .milliseconds(300))
        model.cancel()
        try? await Task.sleep(for: .seconds(2))
        precondition(model.results.isEmpty && !model.isSearching)
        print("PASS cancel: late work did not reclaim the search surface")
    }
}
