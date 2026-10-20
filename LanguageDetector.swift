import Foundation

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

    static let urdu: Set<String> = [
        "main","mein","hai","hain","nahi","nahin","kya","aap","tum","tumhe","mujhe",
        "kyun","kaise","acha","accha","theek","yaar","bhai","shukriya","jaan","pyar",
        "mohabbat","baat","kal","aaj","kab","bohat","bahut","sab","kuch","mera","meri",
        "tera","teri","karo","kar","tha","thi","raha","rahi","lekin","magar","aur",
        "phir","abhi","chalo","dil","hun","hoon","ho","tu","tujhe","kahan","kaun"
    ]

    static let telugu: Set<String> = [
        "nenu","nuvvu","meeru","em","enti","ela","ekkada","enduku","ledu","ledhu",
        "undi","unnadi","cheppu","cheppandi","bagundi","baagundi","bagunnava","anna",
        "akka","amma","nanna","raa","ayyindi","vachha","vastha","vellanu","chala",
        "kaani","ante","ippudu","repu","ninna","nacchindi","prema","manchi","sare",
        "avunu","kadu","ayya","bava","mama","nannu","naku","neeku","mee","ra","ledra",
        "emi","ela","unnava","tinnava","vacchava","chesav","chesaru","baga"
    ]

    static let english: Set<String> = [
        "the","is","are","you","i","we","what","how","why","not","and","to","of","in",
        "it","that","this","have","with","for","love","miss","okay","please","sorry",
        "my","me","your","was","will","can","do","did","good","hello","hi","thanks"
    ]

    static func detect(_ text: String) -> LanguageResult {
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }

        let u = words.filter { urdu.contains($0) }.count
        let t = words.filter { telugu.contains($0) }.count
        let e = words.filter { english.contains($0) }.count

        guard words.count >= 3, max(u, t, e) > 0 else {
            return LanguageResult(language: .unknown, urduScore: u, teluguScore: t, englishScore: e)
        }

        let language: ChatLanguage
        if t >= u && t >= e { language = .romanTelugu }
        else if u >= t && u >= e { language = .romanUrdu }
        else { language = .english }

        return LanguageResult(language: language, urduScore: u, teluguScore: t, englishScore: e)
    }
}
