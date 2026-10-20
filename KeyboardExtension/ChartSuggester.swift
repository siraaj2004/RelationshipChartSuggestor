import Foundation

enum ChatLanguage: String, CaseIterable {
    case english = "English"
    case romanUrdu = "Roman Urdu"
    case romanTelugu = "Roman Telugu"
}

struct ChartSuggestion: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let text: String
}

// MARK: - Language detection

enum LanguageDetector {
    private static let urduWords: Set<String> = [
        "kya","kia","hai","hain","nahi","nahin","acha","accha","theek","thik","yaar","bhai",
        "kaise","kaisi","kaisa","tum","aap","mujhe","mujhy","mera","meri","tera","teri",
        "kahan","kab","kyun","kyu","bohat","bahut","buhat","shukriya","jaan","janu","chalo",
        "abhi","phir","lekin","magar","hun","hoon","tha","thi","raha","rahi","karo","batao",
        "btao","sach","khana","khaya","pyar","mohabbat","dil","inshallah","mashallah",
        "assalamualaikum","salam","yaad","maaf","udaas","pareshan","subah","raat","sojao"
    ]
    private static let teluguWords: Set<String> = [
        "nenu","nuvvu","meeru","emi","em","ela","ekkada","enduku","eppudu","ledu","undi",
        "unnava","unnaru","unnavu","chala","bagundi","bagunnava","bagunnara","cheppu",
        "cheppandi","cheyyi","chesava","chestunnav","tinnava","thinnava","vachava","vastava",
        "ayyindi","kada","antav","naku","naaku","neeku","nee","naa","manam","pilla","babu",
        "amma","nanna","sare","avunu","ayithe","kani","inka","ippudu","repu","ninna","anna",
        "akka","prema","ishtam","nachindi","nidra","podam","randi","telusu","teliyadu",
        "emaindi","gurthu","gurtu","kshaminchu","dhanyavadalu","subhodayam","subharatri"
    ]
    private static let englishWords: Set<String> = [
        "the","is","are","you","i","my","me","what","how","where","when","why","have","do",
        "does","did","will","would","can","good","love","miss","thanks","thank","please",
        "sorry","hello","hi","hey","today","tonight","night","morning","with","and","to",
        "of","it","this","that","was","not","just","so","your","we","day","like","want"
    ]

    static func tokens(_ text: String) -> [String] {
        let collapsed = text.lowercased()
            .replacingOccurrences(of: "(.)\\1{2,}", with: "$1", options: .regularExpression)
        return collapsed.components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
    }

    static func detect(_ text: String) -> ChatLanguage {
        var urdu = 0, telugu = 0, english = 0
        for s in text.unicodeScalars {
            switch s.value {
            case 0x0600...0x06FF: urdu += 3      // Urdu/Arabic script
            case 0x0C00...0x0C7F: telugu += 3    // Telugu script
            default: break
            }
        }
        for w in tokens(text) {
            if urduWords.contains(w) { urdu += 2 }
            if teluguWords.contains(w) { telugu += 2 }
            if englishWords.contains(w) { english += 1 }
        }
        if urdu == 0 && telugu == 0 { return .english }
        if telugu > urdu && telugu > english { return .romanTelugu }
        if urdu > telugu && urdu > english { return .romanUrdu }
        return .english
    }
}

// MARK: - Intent detection

enum ChatIntent: CaseIterable {
    case missYou, goodNight, goodMorning, sorry, sad, thanks, food, plans, compliment, howAreYou, greeting, general

    var phrases: [String] {
        switch self {
        case .missYou: return ["miss","missing","yaad","gurthu","gurtu"]
        case .goodNight: return ["good night","gn","shab bakhair","shabbakhair","subharatri","shubha ratri","sojao","so jao","nidra","padukondi"]
        case .goodMorning: return ["good morning","gm","subah","subha","subhodayam","shubhodayam"]
        case .sorry: return ["sorry","sry","maaf","maafi","kshaminchu","kshaminchandi"]
        case .sad: return ["sad","upset","udaas","pareshan","bore","bored","depressed","badha","badhaga","bejar"]
        case .thanks: return ["thanks","thank","thx","shukriya","shukria","dhanyavadalu"]
        case .food: return ["khana","khaya","lunch","dinner","eat","ate","tinnava","thinnava","bhojanam","breakfast"]
        case .plans: return ["meet","milte","milna","plan","free","fursat","kalusukundam","kalavali","weekend"]
        case .compliment: return ["beautiful","cute","handsome","pyari","khoobsurat","andam","andamga"]
        case .howAreYou: return ["how are","kaise","kaisi","kaisa","haal","unnava","unnavu","bagunnava","bagunnara","wyd","chestunnav","kar rahe","kar rahi"]
        case .greeting: return ["hi","hello","hey","salam","assalam","assalamualaikum","namaste","namaskaram"]
        case .general: return []
        }
    }

    static func detect(_ text: String) -> ChatIntent {
        let recent = String(text.suffix(160))
        let padded = " " + LanguageDetector.tokens(recent).joined(separator: " ") + " "
        for intent in ChatIntent.allCases where intent != .general {
            for p in intent.phrases where padded.contains(" \(p) ") { return intent }
        }
        return .general
    }
}

// MARK: - Suggestions

enum ChartSuggester {
    static func suggest(for text: String, language: ChatLanguage) -> [ChartSuggestion] {
        let intent = ChatIntent.detect(text)
        var out = replies(intent, language).map { ChartSuggestion(label: "Reply", text: $0) }
        let starters = conversationStarters[language] ?? []
        if !starters.isEmpty {
            out.append(ChartSuggestion(label: "Starter", text: starters[text.count % starters.count]))
        }
        return Array(out.prefix(4))
    }

    static func analyze(_ text: String) -> (ChatLanguage, [ChartSuggestion]) {
        let lang = LanguageDetector.detect(text)
        return (lang, suggest(for: text, language: lang))
    }

    private static let conversationStarters: [ChatLanguage: [String]] = [
        .english: ["What's one thing that made you smile this week?",
                   "If we could go anywhere together, where would you pick?",
                   "What's your favourite way to spend a lazy day?"],
        .romanUrdu: ["Is hafte kis cheez ne tumhein sabse zyada khush kiya?",
                     "Agar hum kahin bhi ja sakte, tum kahan jana chahogi/chahoge?",
                     "Tumhara pasandida tareeqa kya hai aram ka din guzarne ka?"],
        .romanTelugu: ["Ee week lo ninnu ekkuva navvinchina vishayam emiti?",
                       "Manam kalisi ekkadaina vellagalithe, nuvvu ekkadiki veltav?",
                       "Nee favourite lazy day plan emiti?"]
    ]

    private static func replies(_ intent: ChatIntent, _ lang: ChatLanguage) -> [String] {
        switch (intent, lang) {
        case (.greeting, .english): return ["Hey! So good to hear from you 😊", "Hi! How's your day going?", "Hello you! I was just thinking of you"]
        case (.greeting, .romanUrdu): return ["Assalamualaikum! Tumhein dekh ke acha laga 😊", "Hey! Aaj ka din kaisa ja raha hai?", "Hello! Main abhi tumhare baare mein soch raha tha"]
        case (.greeting, .romanTelugu): return ["Hey! Ninnu chusi chala happy ga undi 😊", "Hi! Ee roju ela undi?", "Hello! Ippude ninne gurtu chesukunnanu"]

        case (.howAreYou, .english): return ["I'm great now that we're talking 😄 How about you?", "Doing good! Tell me about your day", "Better after seeing your message! You?"]
        case (.howAreYou, .romanUrdu): return ["Main theek hun, tumse baat karke aur acha lag raha hai 😄 Tum batao?", "Sab acha hai! Apne din ke baare mein batao", "Tumhara message dekh ke mood acha ho gaya! Tum kaise ho?"]
        case (.howAreYou, .romanTelugu): return ["Nenu bagunnanu, nuvvu matladite inka bagundi 😄 Nuvvu ela unnav?", "Bagunna! Nee day gurinchi cheppu", "Nee message chusaka happy ga undi! Nuvvu bagunnava?"]

        case (.missYou, .english): return ["I miss you too, more than I can say 💛", "Aww, you're always on my mind", "Can't wait to see you soon"]
        case (.missYou, .romanUrdu): return ["Mujhe bhi tumhari bohat yaad aati hai 💛", "Tum hamesha mere khayalon mein rehte ho", "Jaldi milte hain, intezar nahi hota"]
        case (.missYou, .romanTelugu): return ["Naku kuda ninnu chala miss avutunnanu 💛", "Nuvvu eppudu naa aalochanallone untav", "Tvaralo kaluddam, wait cheyyalekapotunna"]

        case (.goodNight, .english): return ["Good night! Sweet dreams 🌙", "Sleep well, talk tomorrow 💤", "Night night, thanks for today ❤️"]
        case (.goodNight, .romanUrdu): return ["Shab bakhair! Meethe khwab 🌙", "Araam se sona, kal baat karte hain 💤", "Good night, aaj ke din ka shukriya ❤️"]
        case (.goodNight, .romanTelugu): return ["Good night! Manchi kalalu raavali 🌙", "Hayiga padukో, repu matladukundam 💤", "Subharatri, ee roju ki thanks ❤️"]

        case (.goodMorning, .english): return ["Good morning! Hope today is wonderful ☀️", "Morning! Did you sleep well?", "Rise and shine, make today great!"]
        case (.goodMorning, .romanUrdu): return ["Subah bakhair! Aaj ka din shandar ho ☀️", "Good morning! Neend poori hui?", "Uth jao, aaj kuch acha hone wala hai!"]
        case (.goodMorning, .romanTelugu): return ["Good morning! Ee roju super ga undali ☀️", "Subhodayam! Nidra bagapattinda?", "Lechi, ee roju manchiga gadupu!"]

        case (.sorry, .english): return ["It's okay, I understand. Thanks for telling me 🤍", "No worries, let's talk it through", "I appreciate you saying that"]
        case (.sorry, .romanUrdu): return ["Koi baat nahi, main samajhta hun 🤍", "Fikar mat karo, aaram se baat karte hain", "Tumne kaha, ye mere liye bohat maayne rakhta hai"]
        case (.sorry, .romanTelugu): return ["Parledu, nenu artham chesukunnanu 🤍", "Chinta padaku, aaram ga matladukundam", "Nuvvu cheppadam naku chala important"]

        case (.sad, .english): return ["I'm here for you. Want to talk about it?", "Sorry you're feeling this way, I'm listening 🤍", "You're not alone, I've got you"]
        case (.sad, .romanUrdu): return ["Main tumhare saath hun. Baat karna chahoge?", "Mujhe afsos hai, main sun raha hun 🤍", "Tum akele nahi ho, main hun na"]
        case (.sad, .romanTelugu): return ["Nenu nee tho unnanu. Matladalani undha?", "Baadha ga undi, nenu vintunnanu 🤍", "Nuvvu ontari kaadu, nenu unnanu"]

        case (.thanks, .english): return ["Anytime! You mean a lot to me", "Always happy to help 😊", "Of course, that's what I'm here for"]
        case (.thanks, .romanUrdu): return ["Koi baat nahi, tum mere liye khaas ho", "Hamesha khushi se 😊", "Tumhare liye kuch bhi"]
        case (.thanks, .romanTelugu): return ["Parledu, nuvvu naku chala special", "Eppudaina happy ga 😊", "Nee kosam em aina chestanu"]

        case (.food, .english): return ["Yes, I ate! What did you have?", "Not yet, want to grab something together?", "Don't skip meals, take care of yourself 🍽️"]
        case (.food, .romanUrdu): return ["Haan khaya! Tumne kya khaya?", "Abhi nahi, saath khaein?", "Khana mat chhodna, apna khayal rakho 🍽️"]
        case (.food, .romanTelugu): return ["Avunu tinnanu! Nuvvu emi tinnav?", "Inka ledu, kalisi tindama?", "Bhojanam skip cheyyaku, jagratta 🍽️"]

        case (.plans, .english): return ["I'd love that! When are you free?", "Sounds like a plan, you pick the place", "Yes! Let's make it happen this weekend"]
        case (.plans, .romanUrdu): return ["Mujhe bohat pasand aayega! Tum kab free ho?", "Plan pakka, jagah tum chuno", "Haan! Is weekend pakka karte hain"]
        case (.plans, .romanTelugu): return ["Naku chala nachutundi! Nuvvu eppudu free?", "Plan fix, place nuvvu choose chey", "Avunu! Ee weekend fix chedam"]

        case (.compliment, .english): return ["That's so sweet, you made me blush 😊", "You always know what to say", "Right back at you, you're amazing"]
        case (.compliment, .romanUrdu): return ["Bohat pyara kaha, main sharma gaya 😊", "Tum hamesha acha bolte ho", "Tum bhi kamaal ho"]
        case (.compliment, .romanTelugu): return ["Chala sweet ga cheppav, nenu blush ayya 😊", "Nuvvu eppudu manchiga matladatav", "Nuvvu kuda amazing"]

        case (.general, .english): return ["Tell me more, I'm curious 😊", "That's interesting! What happened next?", "I love hearing about your day"]
        case (.general, .romanUrdu): return ["Aur batao, mujhe janna hai 😊", "Interesting! Phir kya hua?", "Mujhe tumhari baatein sun'na pasand hai"]
        case (.general, .romanTelugu): return ["Inka cheppu, telusukovalani undi 😊", "Interesting! Tarvata emi aindi?", "Nee matalu vinadam naku istam"]
        }
    }
}
