struct ChatAnalysis {
    let extractedText: String
    let languageCode: String
    let languageName: String
    var chartSuggestions: [ChartSuggestion]
    var suggestions: [ReplySuggestion]
}

static func analyze(_ image: UIImage) async throws -> ChatAnalysis {
    let text = try await recognizeText(in: image)
    let lang = detectLanguage(text)
    let charts = ChartSuggester.suggest(from: text)
    return ChatAnalysis(extractedText: text, languageCode: lang.code,
                        languageName: lang.name, chartSuggestions: charts,
                        suggestions: [])
}
