import Vision
import UIKit

enum OCRError: LocalizedError {
    case invalidImage
    var errorDescription: String? { "Could not read this image." }
}

enum OCRService {

    /// Reads all text in the image. Returns lines ordered top to bottom.
    static func extractText(from image: UIImage) async throws -> String {
        guard let cg = normalized(image).cgImage else { throw OCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
                // Vision's origin is bottom-left, so higher maxY = higher on screen
                let sorted = observations.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
                let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false   // correction breaks romanized words

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try VNImageRequestHandler(cgImage: cg, options: [:]).perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Redraws the image so its orientation is always "up" (fixes rotated screenshots/photos).
    private static func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
    }
}
