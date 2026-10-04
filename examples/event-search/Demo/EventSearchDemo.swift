import SwiftUI

struct DemoSearchView: View {
    @StateObject private var model = DemoSearchModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Try the search") {
                    TextField("Try strength, posing, or error", text: Binding(
                        get: { model.text }, set: { model.search($0) }))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("search-query")
                    HStack {
                        Button("Strength") { model.search("strength") }
                        Spacer()
                        Button("Race demo") { model.runRace() }
                        Spacer()
                        Button("Clear") { model.search("") }
                    }.buttonStyle(.borderless)
                }
                Section("Current request") {
                    if model.isSearching { ProgressView("Searching…") }
                    Text(model.activity).font(.subheadline)
                    if let error = model.error { Text(error).foregroundStyle(.red) }
                }
                Section("Results") {
                    if model.results.isEmpty && !model.isSearching {
                        Text("No matching synthetic events").foregroundStyle(.secondary)
                    }
                    ForEach(model.results) { event in
                        Button { model.select(event.id) } label: {
                            HStack {
                                Text(event.title)
                                Spacer()
                                if model.selected?.id == event.id { Image(systemName: "checkmark") }
                            }
                        }.buttonStyle(.borderless)
                    }
                }
                if let selected = model.selected {
                    Section("Selection") { Text(selected.title) }
                }
                Section("About this example") {
                    Text("Robin Winters · native iOS engineering")
                    Text("Standalone teaching example prepared with coding-assistant support. Synthetic data; not ShowFlex source or a released product feature.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Link("Source and seven controller tests", destination: URL(string: "https://github.com/RobinWinters/RobinWinters/tree/Radpository/examples/event-search")!)
                    Link("Shipped ShowFlex iPhone product", destination: URL(string: "https://apps.apple.com/us/app/showflex/id6757890910")!)
                }
            }
            .navigationTitle("Search ownership")
            .toolbar { Button("Cancel") { model.cancel() } }
            .onDisappear { model.cancel() }
        }
    }
}

@main
struct EventSearchDemoApp: App {
    var body: some Scene { WindowGroup { DemoSearchView() } }
}
