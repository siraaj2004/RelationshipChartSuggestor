import NaturalLanguage

enum TextLanguage { case english, romanTelugu, romanUrdu, unknown }

enum ChartType: String {
    case sociogram = "Sociogram"
    case genogram = "Genogram"
    case ecomap = "Ecomap"
    case orgChart = "Org Chart"
    case networkGraph = "Network Graph"
}

struct LanguageDetector {
    static let teluguWords: Set<String> = ["nenu","meeru","nuvvu","amma","nanna","anna","akka","tammudu",
        "chelli","bava","babai","attayya","mama","ledu","undi","ela","enti","cheppu","kani","ra","andi",
        "ekkada","evaru","bagunnava","bagunnanu","ayindi","vachindi","pani","office","friend"]
    static let urduWords: Set<String> = ["main","mein","aap","tum","hum","ammi","abbu","bhai","behan","baji",
        "chacha","mama","khala","phupho","nahi","hai","hain","kya","kaise","theek","acha","dost","shukriya",
        "kaam","ghar","walid","walida","beta","beti","yaar"]

    static func detect(_ text: String) -> TextLanguage {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
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
}

struct ChartSuggestor {
    static func suggest(for text: String) -> [ChartType] {
        let lower = text.lowercased()
        var results: [ChartType] = []

        // Topic signals (work in any language)
        let family = ["amma","nanna","ammi","abbu","mother","father","brother","sister","bhai",
                      "anna","akka","tammudu","chelli","family","walid","walida","beta","beti"]
        let work = ["boss","manager","team","office","company","colleague","hr","department"]
        let support = ["school","hospital","community","ngo","support","agency","neighbour"]
        let friends = ["friend","dost","yaar","group","class","classmate"]

        if family.contains(where: lower.contains)  { results.append(.genogram) }
        if work.contains(where: lower.contains)    { results.append(.orgChart) }
        if support.contains(where: lower.contains) { results.append(.ecomap) }
        if friends.contains(where: lower.contains) { results.append(.sociogram) }

        // Language-based default ordering when topic is unclear
        if results.isEmpty {
            switch LanguageDetector.detect(text) {
            case .romanTelugu, .romanUrdu: results = [.genogram, .sociogram]
            case .english:                 results = [.networkGraph, .orgChart]
            case .unknown:                 results = [.networkGraph]
            }
        }
        return results
    }
}
