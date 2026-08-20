import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Vision)
import Vision
#endif

protocol ImageTextRecognizing {
    func recognizeText(from imageData: Data) async throws -> String
}

#if canImport(Vision) && canImport(UIKit)
struct VisionTextRecognizer: ImageTextRecognizing {
    func recognizeText(from imageData: Data) async throws -> String {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ko-KR", "en-US"]
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
#endif

enum OCRError: LocalizedError {
    case invalidImage
    case lowConfidence

    var errorDescription: String? {
        switch self {
        case .invalidImage: "이미지를 읽을 수 없어요."
        case .lowConfidence: "글자가 잘 안 보여요. 다시 찍거나 다른 캡처를 써 주세요."
        }
    }
}

struct StockScreenshotAnalyzer {
    var parser: StockScreenshotAnalyzing
    var recognizer: ImageTextRecognizing?

    func analyze(imageData: Data?, fallbackText: String?, catalog: [Stock]) async throws -> ScreenshotAnalysisResult {
        let text: String
        if let fallbackText, !fallbackText.isEmpty {
            text = fallbackText
        } else if let imageData, let recognizer {
            text = try await recognizer.recognizeText(from: imageData)
        } else {
            throw OCRError.invalidImage
        }
        return parser.analyze(text: text, catalog: catalog, now: Date())
    }
}
