import SwiftUI

enum RelationshipType: String, CaseIterable, Identifiable {
    case friendship = "Friendship"
    case family = "Family"
    case team = "Team / Colleagues"
    case network = "Social Network"

    var id: String { rawValue }

    var suggestions: [ChartSuggestion] {
        switch self {
        case .friendship:
            return [
                ChartSuggestion(name: "Sociogram", detail: "Shows who is connected to whom and how strongly."),
                ChartSuggestion(name: "Venn Diagram", detail: "Shows shared interests between people.")
            ]
        case .family:
            return [
                ChartSuggestion(name: "Genogram", detail: "Family tree with relationship quality."),
                ChartSuggestion(name: "Ecomap", detail: "Family connections to outside groups.")
            ]
        case .team:
            return [
                ChartSuggestion(name: "Org Chart", detail: "Reporting lines and roles."),
                ChartSuggestion(name: "RACI Matrix", detail: "Who is responsible, accountable, consulted, informed.")
            ]
        case .network:
            return [
                ChartSuggestion(name: "Network Graph", detail: "Nodes and edges for large groups."),
                ChartSuggestion(name: "Chord Diagram", detail: "Strength of links between groups.")
            ]
        }
    }
}

struct ChartSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
}

struct ContentView: View {
    @State private var selected: RelationshipType = .friendship

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Relationship", selection: $selected) {
                    ForEach(RelationshipType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List(selected.suggestions) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name).font(.headline)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Chart Suggestor")
        }
    }
}

#Preview {
    ContentView()
}
