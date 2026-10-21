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

    // Keywords in English, Telugu (script and English letters) and Hindi
    fileprivate var keywords: [String] {
        switch self {
        case .sociogram:
            return ["friend", "bro", "buddy", "party", "group", "gang",
                     "స్నేహితుడు", "ఫ్రెండ్", "dost", "दोस्त", "mitrudu"]
        case .genogram:
            return ["mom", "dad", "mother", "father", "brother", "sister", "family",
                     "amma", "nanna", "anna", "akka", "తల్లి", "నాన్న", "అమ్మ", "అన్న", "అక్క",
                     "माँ", "पापा", "भाई", "बहन"]
        case .ecomap:
            return ["help", "support", "community", "neighbour", "school", "church", "temple",
                     "సహాయం", "మద్దతు", "madad", "मदद"]
        case .orgChart:
            return ["boss", "manager", "office", "meeting", "team", "client", "salary", "work",
                     "మేనేజర్", "ఆఫీస్", "बॉस", "ऑफिस"]
        case .networkGraph:
            return ["connect", "network", "contact", "introduce", "know"]
        }
    }
}

struct ChartSuggestion: Identifiable {
    let chart: ChartType
    let reason: String
    let score: Int
    var id: ChartType { chart }
}

enum ChartSuggester {
    static func suggest(from text: String) -> [ChartSuggestion] {
        let lower = text.lowercased()
        var results: [ChartSuggestion] = []

        for chart in ChartType.allCases {
            let hits = chart.keywords.filter { lower.contains($0.lowercased()) }
            if !hits.isEmpty {
                results.append(ChartSuggestion(
                    chart: chart,
                    reason: "Chat mentions: \(hits.prefix(3).joined(separator: ", "))",
                    score: hits.count))
            }
        }

        if results.isEmpty {
            results.append(ChartSuggestion(chart: .networkGraph,
                                           reason: "No clear relationship type found",
                                           score: 0))
        }
        return results.sorted { $0.score > $1.score }
    }
}
