import Foundation

struct ScreenshotAnalysisResult: Equatable, Sendable {
    var recognizedTicker: String?
    var recognizedName: String?
    var recognizedPrice: Double?
    var recognizedDate: Date?
    var recognizedReturn: Double?
    var matchedStock: Stock?
    var confidence: Double
    var rawText: String
    var priceConfidence: Double
    var needsUserConfirm: Bool { confidence < 0.90 }
    var tooLow: Bool { confidence < 0.40 }

    static let empty = ScreenshotAnalysisResult(
        confidence: 0,
        rawText: "",
        priceConfidence: 0
    )
}

protocol StockScreenshotAnalyzing {
    func analyze(text: String, catalog: [Stock], now: Date) -> ScreenshotAnalysisResult
}

struct StockTextParser: StockScreenshotAnalyzing {
    func analyze(text: String, catalog: [Stock], now: Date = Date()) -> ScreenshotAnalysisResult {
        let lines = text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        var ticker: String?
        var name: String?
        var stock: Stock?
        var confidence = 0.0

        let upperTokens = text.uppercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        for token in upperTokens {
            if let match = catalog.first(where: { $0.ticker.uppercased() == token || $0.krCode == token }) {
                ticker = match.ticker
                name = match.name
                stock = match
                confidence = 0.96
                break
            }
        }

        if stock == nil {
            for item in catalog where text.localizedCaseInsensitiveContains(item.name) {
                ticker = item.ticker
                name = item.name
                stock = item
                confidence = 0.84
                break
            }
        }

        let (price, priceConfidence) = extractPrice(from: text, market: stock?.market)
        let date = extractDate(from: text, now: now)
        let ret = extractReturn(from: text)

        if stock == nil { confidence = min(confidence, 0.31) }
        if price != nil, priceConfidence < 0.6 { confidence = min(confidence, 0.72) }

        return ScreenshotAnalysisResult(
            recognizedTicker: ticker,
            recognizedName: name,
            recognizedPrice: price,
            recognizedDate: date,
            recognizedReturn: ret,
            matchedStock: stock,
            confidence: confidence,
            rawText: lines.joined(separator: "\n"),
            priceConfidence: priceConfidence
        )
    }

    private func extractPrice(from text: String, market: Market?) -> (Double?, Double) {
        let labeled = [
            "평균매입가", "매입단가", "평단", "평단가", "매수가",
            "Average Price", "Avg Price", "Avg. Price", "Average Cost", "Avg Cost"
        ]
        let ns = text as NSString
        for label in labeled {
            if let range = text.range(of: label, options: .caseInsensitive) {
                let tail = String(text[range.upperBound...]).prefix(40)
                if let value = firstNumber(in: String(tail), marketHint: market) {
                    return (value, 0.93)
                }
                _ = ns
            }
        }
        if let dollar = firstMatch(in: text, pattern: #"\$\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]+)?|[0-9]+(?:\.[0-9]+)?)"#) {
            return (parseNumber(dollar), market == .krx ? 0.45 : 0.7)
        }
        if let won = firstMatch(in: text, pattern: #"([0-9]{1,3}(?:,[0-9]{3})+|[0-9]{4,})\s*원"#) {
            return (parseNumber(won), 0.7)
        }
        return (nil, 0)
    }

    private func extractReturn(from text: String) -> Double? {
        guard let raw = firstMatch(in: text, pattern: #"([+-]?\d+(?:\.\d+)?)\s*%"#) else { return nil }
        return (Double(raw) ?? 0) / 100
    }

    private func extractDate(from text: String, now: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let pairs: [(String, String)] = [
            ("yyyy.MM.dd", #"\d{4}\.\d{2}\.\d{2}"#),
            ("yyyy-MM-dd", #"\d{4}-\d{2}-\d{2}"#),
            ("yyyy/MM/dd", #"\d{4}/\d{2}/\d{2}"#),
            ("MM/dd/yyyy", #"\d{2}/\d{2}/\d{4}"#),
            ("yy.MM.dd", #"\d{2}\.\d{2}\.\d{2}"#)
        ]
        for (format, pattern) in pairs {
            formatter.dateFormat = format
            if let raw = firstMatch(in: text, pattern: pattern), let date = formatter.date(from: raw) {
                return date
            }
        }
        _ = now
        return nil
    }

    private func firstNumber(in text: String, marketHint: Market?) -> Double? {
        if let dollar = firstMatch(in: text, pattern: #"\$\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]+)?|[0-9]+(?:\.[0-9]+)?)"#) {
            return parseNumber(dollar)
        }
        if let won = firstMatch(in: text, pattern: #"([0-9]{1,3}(?:,[0-9]{3})+|[0-9]{4,})"#) {
            let value = parseNumber(won)
            if marketHint == .nasdaq || marketHint == .nyse, value > 10000 { return nil }
            return value
        }
        return nil
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        let idx = match.numberOfRanges > 1 && match.range(at: 1).location != NSNotFound ? 1 : 0
        guard let swiftRange = Range(match.range(at: idx), in: text) else { return nil }
        return String(text[swiftRange])
    }

    private func parseNumber(_ raw: String) -> Double {
        let cleaned = raw.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
        return Double(cleaned) ?? 0
    }
}

struct VerificationOutcome: Equatable, Sendable {
    var matched: Bool
    var ocrPrice: Double?
    var inputPrice: Double
    var stockMatched: Bool
    var confidence: Double
}

struct VerificationService {
    var relativeTolerance: Double = 0.015

    func verify(holding: Holding, analysis: ScreenshotAnalysisResult, stock: Stock) -> VerificationOutcome {
        let stockMatched = analysis.matchedStock?.id == stock.id ||
            analysis.recognizedTicker?.uppercased() == stock.ticker.uppercased() ||
            analysis.recognizedName?.localizedCaseInsensitiveContains(stock.name) == true
        guard let ocrPrice = analysis.recognizedPrice, analysis.priceConfidence >= 0.6, stockMatched else {
            return VerificationOutcome(
                matched: false,
                ocrPrice: analysis.recognizedPrice,
                inputPrice: holding.averagePrice,
                stockMatched: stockMatched,
                confidence: analysis.confidence
            )
        }
        let delta = abs(ocrPrice - holding.averagePrice) / max(holding.averagePrice, 0.01)
        return VerificationOutcome(
            matched: delta <= relativeTolerance,
            ocrPrice: ocrPrice,
            inputPrice: holding.averagePrice,
            stockMatched: stockMatched,
            confidence: min(analysis.confidence, analysis.priceConfidence)
        )
    }
}
