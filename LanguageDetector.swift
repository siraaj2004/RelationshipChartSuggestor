import Foundation
import NaturalLanguage

enum ChatLanguage: String {
    case english = "English"
    case romanUrdu = "Roman Urdu"
    case romanTelugu = "Roman Telugu"
    case unknown = "Unknown"
}

struct LanguageResult {
    let language: ChatLanguage
    let urduScore: Int
    let teluguScore: Int
    let englishScore: Int
}

enum LanguageDetector {

    // Words that are clearly Roman Urdu / Hindi-Urdu (Dakhni spellings included).
    // Words that are also common English words ("main", "to", "ho") are left out on purpose.
    static let urdu: Set<String> = [
        "mein","hai","hain","nahi","nahin","nai","naihai","kya","aap","tum","tumhe","mujhe",
        "kyun","kyu","kaise","acha","accha","theek","yaar","bhai","shukriya","jaan","pyar",
        "mohabbat","baat","bath","kal","aaj","kab","kabhi","bohat","bahut","sab","kuch","mera","meri",
        "tera","teri","karo","kar","karna","karthe","karthum","tha","thi","raha","rahi","lekin","magar",
        "aur","phir","abhi","chalo","dil","hun","hoon","tujhe","kahan","kaun","kavo","leko",
        "dekho","dekhonakko","nakko","abe","hojathe","habi","kako","khali","asal","ji","behan",
        "ammi","abbu","dost","ghar","kaam","walid","walida","beta","beti"
    ]

    static let telugu: Set<String> = [
        "nenu","nuvvu","meeru","enti","ela","ekkada","enduku","ledu","ledhu",
        "undi","unnadi","cheppu","cheppandi","bagundi","baagundi","bagunnava","bagunnanu",
        "akka","amma","nanna","raa","ayyindi","ayindi","vachha","vachindi","vastha","vellanu",
        "chala","kaani","kani","ante","ippudu","repu","ninna","nacchindi","prema","manchi",
        "sare","avunu","kadu","ayya","bava","nannu","naku","neeku","mee","ledra",
        "emi","unnava","tinnava","vacchava","chesav","chesaru","baga","andi","memu","vaadu",
        "evaru","pani","thatha","ammamma","tammudu","chelli","babai"
    ]

    static let english: Set<String> = [
        "the","is","are","you","i","we","what","how","why","not","and","to","of","in",
        "it","that","this","have","with","for","love","miss","okay","please","sorry",
        "my","me","your","was","will","can","do","did","good","hello","hi","thanks",
        "exams","exam","best","all","be","at","on","but","just","come","going","today"
    ]

    static func tokens(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }

    static func detect(_ text: String) -> LanguageResult {
        // Unique words only, so "haan haan haan" can't skew the score.
        let words = Set(tokens(text))

        let u = words.intersection(urdu).count
        let t = words.intersection(telugu).count
        let e = words.intersection(english).count

        func result(_ l: ChatLanguage) -> LanguageResult {
            LanguageResult(language: l, urduScore: u, teluguScore: t, englishScore: e)
        }

        guard words.count >= 2 else { return result(.unknown) }

        let indic = max(u, t)
        if indic > 0 {
            if u == t { return result(.unknown) }                 // can't tell Urdu from Telugu
            if e > indic * 2 { return result(.english) }          // mostly English, one stray word
            return result(u > t ? .romanUrdu : .romanTelugu)
        }
        if e > 0 { return result(.english) }

        // Nothing matched our lists: let Apple's recogniser decide, but only for English.
        let r = NLLanguageRecognizer()
        r.processString(text)
        if words.count >= 3, r.dominantLanguage == .english { return result(.english) }
        return result(.unknown)
    }
}
