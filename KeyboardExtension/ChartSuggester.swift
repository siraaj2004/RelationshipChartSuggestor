import Foundation

/// Suggests which relationship chart fits the chat text.
/// Only charts with evidence in the text are returned; nothing is shown for empty/unclear text.
enum ChartSuggester {

    private struct Rule {
        let chart: ChartType
        let label: String
        let strong: Set<String>   // clear evidence, worth 2 points
        let weak: Set<String>     // ambiguous words (e.g. "bhai" can be family or a friend), 1 point
    }

    private static let rules: [Rule] = [
        Rule(chart: .genogram, label: "family words",
             strong: ["family","mother","father","mom","dad","amma","nanna","ammi","abbu","walid","walida",
                      "brother","sister","parents","grandfather","grandmother","uncle","aunt","cousin",
                      "thatha","ammamma","nani","dada","dadi","tammudu","chelli","babai","chacha","khala",
                      "husband","wife","son","daughter"],
             weak: ["bhai","behan","anna","akka","mama","bava","beta","beti","bro","sis"]),

        Rule(chart: .orgChart, label: "work words",
             strong: ["boss","manager","team","office","company","colleague","colleagues","hr","department",
                      "employee","ceo","intern","salary","meeting","project","client","deadline","sir","madam"],
             weak: ["work","job","kaam","pani"]),

        Rule(chart: .ecomap, label: "support / community words",
             strong: ["school","hospital","community","ngo","support","agency","neighbour","neighbor",
                      "mosque","temple","church","doctor","hostel","teacher","counsellor","counselor"],
             weak: ["college","help","madad"]),

        Rule(chart: .sociogram, label: "friend / group words",
             strong: ["friend","friends","dost","yaar","group","classmate","classmates","gang","batch","buddy"],
             weak: ["class","exam","exams","college","bhai","bro","anna","party","trip"])
    ]

    static func suggest(for text: String, language: ChatLanguage) -> [ChartSuggestion] {
        let words = Set(LanguageDetector.tokens(text) + LanguageDetector.tokens(text).compactMap { w -> String? in
            // simple plural handling: "friends" -> "friend", "brothers" -> "brother"
            w.count > 3 && w.hasSuffix("s") ? String(w.dropLast()) : nil
        })
        guard !words.isEmpty else { return [] }

        var scored: [(rule: Rule, score: Int, hits: [String])] = []
        for rule in rules {
            let strongHits = words.intersection(rule.strong)
            let weakHits = words.intersection(rule.weak).subtracting(strongHits)
            let score = strongHits.count * 2 + weakHits.count
            if score > 0 {
                let hits = (strongHits.sorted() + weakHits.sorted())
                    .filter { !($0.hasSuffix("s") && words.contains(String($0.dropLast()))) }   // show "exam", not "exam, exams"
                scored.append((rule, score, hits))
            }
        }

        if scored.isEmpty {
            // Not enough signal. Only say something if there is actual chat text to base it on.
            guard words.count >= 3 else { return [] }
            return [ChartSuggestion(chart: .networkGraph,
                                    reason: "No specific relationship words in this \(language.rawValue) chat, so a general network fits",
                                    score: 0)]
        }

        let top = scored.map { $0.score }.max() ?? 0
        return scored
            .filter { $0.score * 2 >= top }                       // drop clearly weaker matches
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { item in
                ChartSuggestion(chart: item.rule.chart,
                                reason: "Found \(item.rule.label): \(item.hits.prefix(3).joined(separator: ", "))",
                                score: item.score)
            }
    }
}
