import Foundation

// MARK: - Languages

enum TextLang: String {
    case english = "English"
    case romanTelugu = "Roman Telugu"
    case romanUrdu = "Roman Urdu"
}

struct LanguageDetector {

    // Common English words (stopwords + everyday words)
    static let english: Set<String> = [
        "i","me","my","we","our","you","your","he","she","it","they","them","his","her","their",
        "is","am","are","was","were","be","been","do","does","did","have","has","had",
        "the","a","an","and","or","but","not","no","yes","of","to","in","on","at","for","with",
        "from","by","about","as","this","that","these","those","what","who","how","why","when",
        "where","which","will","can","could","would","should","if","so","very","too","also",
        "hello","hi","thanks","please","good","bad","work","home","live","lives","living",
        "mother","father","brother","sister","friend","friends","family","boss","manager",
        "team","colleague","wife","husband","son","daughter","uncle","aunt","grandmother",
        "grandfather","cousin","neighbor","teacher","school","office","company","main"
    ]

    // Roman Telugu (avoid words that are also common English: "em", "main", etc.)
    static let telugu: Set<String> = [
        "nenu","nuvvu","meeru","memu","manam","vaadu","aame","ela","enti","ekkada","evaru",
        "cheppu","undi","unnanu","unnav","unnaru","ledu","avunu","kadu","kaadu","amma","nanna",
        "anna","akka","thammudu","tammudu","chelli","chelli","snehitudu","snehitulu","bagunnava",
        "bagunnanu","chesthunnav","chesthunna","vachanu","vachindi","povali","raavali","inti",
        "illu","pani","office","baagundi","tatha","nanamma","ammamma","bava","mama","atta",
        "maradalu","koduku","kuturu","bhaarya","bharta","friend","pelli","andaru","kaani","mari"
    ]

    // Roman Urdu / Hindi-Urdu (avoid "main" which is also English)
    static let urdu: Set<String> = [
        "mein","mai","hum","tum","aap","tu","woh","wo","yeh","ye","kya","kaise","kahan","kaun",
        "hai","hain","hoon","ho","nahi","nahin","acha","accha","theek","thik","ammi","abbu",
        "ami","abu","bhai","bhaiya","behan","baji","dost","dosti","kaam","ghar","shukriya",
        "bohat","bahut","karna","karta","karti","tha","thi","the","aur","lekin","mera","meri",
        "tera","teri","humara","unka","unki","beta","beti","chacha","chachi","mama","khala",
        "dada","dadi","nana","nani","shauhar","biwi","walid","walida","rishta","rishtedar"
    ]

    static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }

    /// Returns the detected language and the raw score of each language.
    static func detect(_ text: String) -> (lang: TextLang, scores: [TextLang: Int]) {
        let words = tokens(text)
        let e = words.filter { english.contains($0) }.count
        let t = words.filter { telugu.contains($0) }.count
        let u = words.filter { urdu.contains($0) }.count
        let scores: [TextLang: Int] = [.english: e, .romanTelugu: t, .romanUrdu: u]

        // Nothing recognised at all -> default to English
        if e == 0 && t == 0 && u == 0 { return (.english, scores) }

        // Pick highest; ties favour the romanised language (English is the fallback)
        if t > e && t >= u { return (.romanTelugu, scores) }
        if u > e && u > t { return (.romanUrdu, scores) }
        if t == e && t > u && t > 0 { return (.romanTelugu, scores) }
        if u == e && u > t && u > 0 { return (.romanUrdu, scores) }
        return (.english, scores)
    }
}

// MARK: - Charts

enum ChartType: String, CaseIterable {
    case genogram = "Genogram"
    case sociogram = "Sociogram"
    case ecomap = "Ecomap"
    case orgChart = "Org Chart"
    case networkGraph = "Network Graph"

    var why: String {
        switch self {
        case .genogram:     return "Family relationships detected - a Genogram maps family members and generations."
        case .sociogram:    return "Friends / social ties detected - a Sociogram shows who is connected to whom."
        case .ecomap:       return "Support systems and community detected - an Ecomap shows external connections."
        case .orgChart:     return "Work hierarchy detected - an Org Chart shows who reports to whom."
        case .networkGraph: return "Mixed or many connections - a Network Graph is the most flexible choice."
        }
    }
}

struct ChartSuggestion {
    let language: TextLang
    let chart: ChartType
    let scores: [ChartType: Int]
}

struct ChartSuggestor {

    // Keywords per chart. English + Roman Telugu + Roman Urdu are all included,
    // so mixed-language text (e.g. "my amma and nanna") still works.
    static let keywords: [ChartType: Set<String>] = [
        .genogram: [
            // English
            "mother","father","brother","sister","son","daughter","wife","husband","uncle","aunt",
            "grandmother","grandfather","cousin","family","parents","married","divorced",
            // Roman Telugu
            "amma","nanna","anna","akka","thammudu","tammudu","chelli","tatha","nanamma","ammamma",
            "bava","atta","maradalu","koduku","kuturu","bhaarya","bharta","pelli",
            // Roman Urdu
            "ammi","abbu","ami","abu","bhai","bhaiya","behan","baji","chacha","chachi","khala",
            "dada","dadi","nana","nani","shauhar","biwi","walid","walida","beta","beti","rishtedar"
        ],
        .sociogram: [
            "friend","friends","classmate","group","crush","popular","lonely","social","circle",
            "snehitudu","snehitulu","friend","andaru",
            "dost","dosti","yaar","saathi"
        ],
        .ecomap: [
            "neighbor","neighbour","community","support","church","temple","mosque","school",
            "hospital","charity","resources","agency","teacher","doctor",
            "inti","illu","gudi","badi",
            "mohalla","masjid","padosi","madad"
        ],
        .orgChart: [
            "boss","manager","team","colleague","office","company","reports","report","ceo",
            "director","employee","department","hr","lead","intern",
            "pani","sir","madam",
            "kaam","daftar","afsar"
        ]
    ]

    static func suggest(for text: String) -> ChartSuggestion {
        let (lang, _) = LanguageDetector.detect(text)
        let words = Set(LanguageDetector.tokens(text))

        var scores: [ChartType: Int] = [:]
        for (chart, set) in keywords {
            scores[chart] = words.intersection(set).count
        }

        // Highest score wins. No hits -> Network Graph.
        let best = scores.max { $0.value < $1.value }
        let total = scores.values.reduce(0, +)
        let topScore = best?.value ?? 0

        // How many charts have at least one hit
        let charts = scores.filter { $0.value > 0 }.count

        let chosen: ChartType
        if total == 0 || topScore == 0 {
            chosen = .networkGraph
        } else if charts >= 3 {
            chosen = .networkGraph   // many kinds of connections mixed together
        } else {
            chosen = best!.key
        }
        return ChartSuggestion(language: lang, chart: chosen, scores: scores)
    }
}

// MARK: - Quick test (call from anywhere, e.g. onAppear)

func runChartSuggestorDemo() {
    let samples = [
        "My mother and father live with my brother",
        "amma nanna akka andaru ela unnaru",
        "mera bhai aur ammi ghar mein hain",
        "my boss and team manager at office",
        "nenu friends tho unnanu",
        "hello"
    ]
    for s in samples {
        let r = ChartSuggestor.suggest(for: s)
        print("\"\(s)\" -> \(r.language.rawValue) -> \(r.chart.rawValue)")
    }
}
