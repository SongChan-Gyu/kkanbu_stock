import Foundation

enum MoneyFormat {
    static func price(_ value: Double, market: Market) -> String {
        if market == .krx {
            return "\(integer.string(from: NSNumber(value: value)) ?? "0")원"
        }
        return "$\(usd.string(from: NSNumber(value: value)) ?? "0")"
    }

    static func percent(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(pct.string(from: NSNumber(value: value * 100)) ?? "0")%"
    }

    static func signedPercent(_ value: Double) -> String {
        percent(value)
    }

    static func compactDate(_ date: Date) -> String {
        dateStamp.string(from: date)
    }

    static func relative(_ date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "방금" }
        if seconds < 3600 { return "\(Int(seconds / 60))분 전" }
        if seconds < 86400 { return "\(Int(seconds / 3600))시간 전" }
        if seconds < 86400 * 7 { return "\(Int(seconds / 86400))일 전" }
        return compactDate(date)
    }

    private static let integer: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let usd: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let pct: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    private static let dateStamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy.MM.dd"
        return f
    }()
}

enum InviteCode {
    static func make() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}
