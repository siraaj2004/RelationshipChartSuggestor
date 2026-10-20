import Foundation

struct ChartSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let reason: String
    let icon: String
}

enum ChartSuggester {

    static func suggest(for text: String, language: ChatLanguage) -> [ChartSuggestion] {
        let words = Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.letters.inverted)
                .filter { !$0.isEmpty }
        )

        let affection: Set<String> = ["love","miss","pyar","mohabbat","jaan","prema","dil","hug","kiss"]
        let conflict: Set<String>  = ["sorry","nahi","nahin","ledu","ledhu","kyun","enduku","angry","hate","fight"]
        let plans: Set<String>     = ["tomorrow","kal","repu","meet","milte","kalavadam","dinner","movie","trip"]

        var out: [ChartSuggestion] = [
            ChartSuggestion(title: "Message balance (bar chart)",
                            reason: "Shows who talks more in the conversation",
                            icon: "chart.bar")
        ]

        if !words.isDisjoint(with: affection) {
            out.append(ChartSuggestion(title: "Affection timeline (line chart)",
                                       reason: "Affectionate words were found in the chat",
                                       icon: "heart"))
        }
        if !words.isDisjoint(with: conflict) {
            out.append(ChartSuggestion(title: "Conflict vs support (stacked bar)",
                                       reason: "Tension or apology words were found",
                                       icon: "exclamationmark.bubble"))
        }
        if !words.isDisjoint(with: plans) {
            out.append(ChartSuggestion(title: "Plans & meetups (timeline)",
                                       reason: "Plans or meeting words were found",
                                       icon: "calendar"))
        }

        out.append(ChartSuggestion(title: "Relationship map (node graph)",
                                   reason: "Shows the people involved and how close they are",
                                   icon: "person.3"))
        return out
    }
}
