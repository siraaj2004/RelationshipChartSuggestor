import Foundation
import NaturalLanguage

enum TextLanguage: String {
    case english = "English"
    case romanTelugu = "Roman Telugu"
    case romanUrdu = "Roman Urdu"
    case unknown = "Unknown"
}

enum ChartType: String, CaseIterable {
    case sociogram = "Sociogram"
    case genogram = "Genogram"
    case ecomap = "Ecomap"
    case orgChart = "Org Chart"
    case networkGraph = "Network Graph"

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

struct LanguageDetector {
    static let teluguWords: Set<String> = [
        "nenu", "meeru", "nuvvu", "amma", "nanna", "anna", "akka", "tammudu",
        "chelli", "bava", "babai", "attayya", "mama", "ledu", "undi", "ela",
        "enti", "cheppu", "kani", "ra", "andi", "ekkada", "evaru", "bagunnava",
        "bagunnanu", "ayindi", "vachindi", "pani", "memu", "vaadu", "ame",
        "ninna", "repu", "ippudu", "chala", "baagundi", "thatha", "ammamma"
    ]
    static let urduWords: Set<String> = [
        "mein", "aap", "tum", "hum", "ammi", "abbu", "bhai", "behan",
        "baji", "chacha", "khala", "phupho", "nahi", "hai", "hain", "kya",
        "kaise", "theek", "acha", "dost", "shukriya", "kaam", "ghar", "walid",
        "walida", "beta", "beti", "yaar", "mera", "meri", "aapka", "kal",
        "aaj", "bohat", "nani", "dada", "dadi"
    ]

    static func detect(_ text: String) -> TextLanguage {
        let words = tokens(text)
        guard !words.isEmpty else { return .unknown }

        let te = words.filter { teluguWords.contains($0) }.count
        let ur = words.filter { urduWords.contains($0) }.count

        if te > ur && te >= 1 { return .romanTelugu }
        if ur > te && ur >= 1 { return .romanUrdu }

        let r = NLLanguageRecognizer()
        r.processString(text)
        if r.dominantLanguage == .english { return .english }
        return .unknown
    }

    static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }
}

struct ChartSuggestion: Identifiable {
    let id = UUID()
    let chart: ChartType
    let reason: String
}

struct ChartSuggestor {
    static let family: Set<String> = [
        "amma", "nanna", "ammi", "abbu", "mother", "father", "brother", "sister",
        "bhai", "behan", "anna", "akka", "tammudu", "chelli", "family", "walid",
        "walida", "beta", "beti", "thatha", "ammamma", "nani", "dada", "dadi",
        "uncle", "aunt", "cousin", "bava", "babai", "mama", "chacha", "khala"
    ]
    static let work: Set<String> = [
        "boss", "manager", "team", "office", "company", "colleague", "hr",
        "department", "employee", "ceo", "intern", "salary", "meeting"
    ]
    static let support: Set<String> = [
        "school", "hospital", "community", "ngo", "support", "agency",
        "neighbour", "neighbor", "college", "mosque", "temple", "church", "doctor"
    ]
    static let friends: Set<String> = [
        "friend", "friends", "dost", "yaar", "group", "class", "classmate", "gang"
    ]

    static func suggest(for text: String) -> [ChartSuggestion] {
        let words = Set(LanguageDetector.tokens(text))
        let language = LanguageDetector.detect(text)
        var out: [ChartSuggestion] = []

        func add(_ chart: ChartType, _ reason: String) {
            if !out.contains(where: { $0.chart == chart }) {
                out.append(ChartSuggestion(chart: chart, reason: reason))
            }
        }

        if !words.isDisjoint(with: family)  { add(.genogram,  "Family words found") }
        if !words.isDisjoint(with: work)    { add(.orgChart,  "Work words found") }
        if !words.isDisjoint(with: support) { add(.ecomap,    "Support / community words found") }
        if !words.isDisjoint(with: friends) { add(.sociogram, "Friend / group words found") }

        if out.isEmpty {
            switch language {
            case .romanTelugu, .romanUrdu:
                add(.genogram,  "\(language.rawValue) text: family chart is a good start")
                add(.sociogram, "\(language.rawValue) text: friends and groups")
            case .english:
                add(.networkGraph, "English text: general connections")
                add(.orgChart,     "English text: roles and hierarchy")
            case .unknown:
                add(.networkGraph, "Not enough text to tell")
            }
        }
        return out
    }
}
