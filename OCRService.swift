import Vision
import UIKit
import ImageIO

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not read this image."
        case .noTextFound:  return "No chat text found in this image."
        }
    }
}

enum OCRService {

    /// Reads the chat text from screenshot data (any app: Instagram, WhatsApp, Telegram, ...).
    /// The image is downsampled while decoding, so it is safe to use inside the keyboard's small memory limit.
    static func extractChatText(from data: Data, maxPixel: Int = 2200) async throws -> String {
        let cg = try downsample(data, maxPixel: maxPixel)

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false   // correction breaks romanized words

                do {
                    try VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
                } catch {
                    continuation.resume(throwing: error)   // resumed exactly once
                    return
                }

                let observations = request.results ?? []
                let lines = observations
                    // Vision's origin is bottom-left: y = 1 is the top of the screen.
                    // Drop the app header (top) and the message bar (bottom).
                    .filter { $0.boundingBox.midY < 0.88 && $0.boundingBox.midY > 0.06 }
                    .sorted {
                        let a = $0.boundingBox, b = $1.boundingBox
                        return abs(a.midY - b.midY) > 0.005 ? a.midY > b.midY : a.minX < b.minX
                    }
                    .compactMap { $0.topCandidates(1).first?.string }
                    .filter { !isNoise($0) }

                if lines.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: lines.joined(separator: "\n"))
                }
            }
        }
    }

    /// Screenshot currently on the clipboard, as encoded data (nil if the clipboard has no image).
    static func clipboardImageData() -> Data? {
        let pb = UIPasteboard.general
        guard pb.hasImages else { return nil }
        for type in ["public.png", "public.jpeg", "public.heic"] {
            if let d = pb.data(forPasteboardType: type) { return d }
        }
        return pb.image?.pngData()
    }

    // MARK: - Helpers

    private static func downsample(_ data: Data, maxPixel: Int) throws -> CGImage {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,   // applies EXIF orientation
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { throw OCRError.invalidImage }
        return cg
    }

    /// Removes UI text that is not part of the conversation.
    private static func isNoise(_ line: String) -> Bool {
        let s = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s.count < 2 { return true }

        let junkExact: Set<String> = ["seen", "delivered", "typing...", "message...", "active now",
                                      "reel", "sociogram", "genogram", "ecomap", "org chart",
                                      "network graph", "chart keyboard"]
        if junkExact.contains(s) { return true }
        if s.hasPrefix("audio call") || s.hasPrefix("video call") || s.hasPrefix("missed") { return true }

        // "17:08", "3:36 PM"
        if s.range(of: #"^\d{1,2}:\d{2}\s?(am|pm)?$"#, options: .regularExpression) != nil { return true }

        // Date headers: "30 AUG AT 3:36PM", "SUN 10:44 PM", "Yesterday 9:10 AM"
        let day = "(mon|tue|wed|thu|fri|sat|sun|today|yesterday|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)"
        let header = "^(\\d{1,2}\\s)?\(day)[a-z]*\\.?\\s*(\\d{1,2})?\\s*(at)?\\s*\\d{1,2}:\\d{2}\\s?(am|pm)?$"
        if s.range(of: header, options: .regularExpression) != nil { return true }

        return false
    }
}
