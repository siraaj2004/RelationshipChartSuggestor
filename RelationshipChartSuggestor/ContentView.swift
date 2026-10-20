import SwiftUI

struct ChartIdea: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
}

enum ChartRelationship: String, CaseIterable, Identifiable {
    case friendship = "Friends"
    case family = "Family"
    case team = "Team"
    case network = "Network"

    var id: String { rawValue }

    var ideas: [ChartIdea] {
        switch self {
        case .friendship:
            return [
                ChartIdea(name: "Sociogram", detail: "Shows who is connected to whom and how strongly."),
                ChartIdea(name: "Venn Diagram", detail: "Shows shared interests between people.")
            ]
        case .family:
            return [
                ChartIdea(name: "Genogram", detail: "Family tree with relationship quality."),
                ChartIdea(name: "Ecomap", detail: "Family connections to outside groups.")
            ]
        case .team:
            return [
                ChartIdea(name: "Org Chart", detail: "Reporting lines and roles."),
                ChartIdea(name: "RACI Matrix", detail: "Who is responsible, accountable, consulted, informed.")
            ]
        case .network:
            return [
                ChartIdea(name: "Network Graph", detail: "Nodes and edges for large groups."),
                ChartIdea(name: "Chord Diagram", detail: "Strength of links between groups.")
            ]
        }
    }
}

struct ContentView: View {
    @State private var selected: ChartRelationship = .friendship

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Relationship", selection: $selected) {
                    ForEach(ChartRelationship.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List(selected.ideas) { idea in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(idea.name)
                            .font(.headline)
                        Text(idea.detail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Chart Suggestor")
        }
    }
}
