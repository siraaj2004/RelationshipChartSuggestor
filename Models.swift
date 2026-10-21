import Foundation
import UIKit
import Vision
import NaturalLanguage

struct ReplySuggestion: Identifiable {
    let id = UUID()
    let text: String
    let tone: String          // e.g. "Warm", "Playful", "Polite"
}

struct ChatAnalysis {
    let extractedText: String
    let languageCode: String
    let languageName: String
    var suggestions: [ReplySuggestion]
}

enum ChatScanner {

    // 1) Read the text from a chat screenshot
    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { return "" }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error { continuation.resume(throwing: error); return }
                let lines = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if #available(iOS 16.0, *) { request.automaticallyDetectsLanguage = true }

            let handler = VNImageRequestHandler(cgImage: cgImage)
            do { try handler.perform([request]) }
            catch { continuation.resume(throwing: error) }
        }
    }

    // 2) Detect the language
    static func detectLanguage(_ text: String) -> (code: String, name: String) {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let lang = recognizer.dominantLanguage else { return ("und", "Unknown") }
        let name = Locale.current.localizedString(forLanguageCode: lang.rawValue) ?? lang.rawValue
        return (lang.rawValue, name)
    }

    // 3) Build the prompt for your reply generator (LLM / API)
    static func replyPrompt(chat: String, languageName: String) -> String {
        """
        Here is a chat conversation:
        \(chat)

        Suggest 3 short replies that build a good relationship with the other person.
        Reply in \(languageName), matching the writing style of the chat.
        Give one warm, one playful, one polite. Return one reply per line as "Tone: reply".
        """
    }

    // 4) Full flow
    static func analyze(_ image: UIImage) async throws -> ChatAnalysis {
        let text = try await recognizeText(in: image)
        let lang = detectLanguage(text)
        // Send replyPrompt(chat: text, languageName: lang.name) to your AI backend,
        // then parse each "Tone: reply" line into a ReplySuggestion.
        return ChatAnalysis(extractedText: text, languageCode: lang.code,
                            languageName: lang.name, suggestions: [])
    }
}
