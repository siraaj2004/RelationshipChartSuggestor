import Foundation

enum ChartType: String, CaseIterable, Identifiable {
    case sociogram = "Sociogram"
    case genogram = "Genogram"
    case ecomap = "Ecomap"
    case orgChart = "Org Chart"
    case networkGraph = "Network Graph"

    var id: String { rawValue }

    var purpose: String {
        switch self {
        case .sociogram:    return "Friends and group bonds"
        case .genogram:     return "Family tree and relations"
        case .ecomap:       return "Support systems around you"
        case .orgChart:     return "Work hierarchy and reporting"
        case .networkGraph: return "General connections"
        }
    }
}

struct ChartSuggestion: Identifiable {
    let chart: ChartType
    let reason: String
    /// Higher = stronger evidence in the chat text.
    let score: Int

    var id: ChartType { chart }   // stable, so SwiftUI/UIKit don't see "new" items every refresh
}
