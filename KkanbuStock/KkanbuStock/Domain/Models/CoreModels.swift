import Foundation

enum Market: String, Codable, CaseIterable, Sendable {
    case krx
    case nasdaq
    case nyse

    var currencySymbol: String {
        self == .krx ? "원" : "$"
    }

    var usesPrefixSymbol: Bool {
        self != .krx
    }

    var displayName: String {
        switch self {
        case .krx: "한국"
        case .nasdaq: "NASDAQ"
        case .nyse: "NYSE"
        }
    }
}

struct User: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var nickname: String
    var avatarEmoji: String
    var createdAt: Date
    var shareQuantity: Bool
    var shareInvestedAmount: Bool

    init(
        id: UUID = UUID(),
        nickname: String,
        avatarEmoji: String = "😎",
        createdAt: Date = Date(),
        shareQuantity: Bool = false,
        shareInvestedAmount: Bool = false
    ) {
        self.id = id
        self.nickname = nickname
        self.avatarEmoji = avatarEmoji
        self.createdAt = createdAt
        self.shareQuantity = shareQuantity
        self.shareInvestedAmount = shareInvestedAmount
    }
}

struct Group: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var inviteCode: String
    var ownerId: UUID
    var createdAt: Date
    var moodEmoji: String

    init(
        id: UUID = UUID(),
        name: String,
        inviteCode: String,
        ownerId: UUID,
        createdAt: Date = Date(),
        moodEmoji: String = "🔥"
    ) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.ownerId = ownerId
        self.createdAt = createdAt
        self.moodEmoji = moodEmoji
    }
}

struct GroupMember: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var groupId: UUID
    var userId: UUID
    var joinedAt: Date

    init(id: UUID = UUID(), groupId: UUID, userId: UUID, joinedAt: Date = Date()) {
        self.id = id
        self.groupId = groupId
        self.userId = userId
        self.joinedAt = joinedAt
    }
}

struct Stock: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var ticker: String
    var name: String
    var market: Market
    var krCode: String?

    init(id: UUID = UUID(), ticker: String, name: String, market: Market, krCode: String? = nil) {
        self.id = id
        self.ticker = ticker
        self.name = name
        self.market = market
        self.krCode = krCode
    }
}

enum HoldingStatus: String, Codable, Sendable {
    case holding
    case sold
}

enum InputMethod: String, Codable, Sendable {
    case manual
    case screenshot
    case chart
}

enum VerificationState: String, Codable, Sendable {
    case unverified
    case screenshotVerified
    case suspected
    case mismatch
}

struct Holding: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var userId: UUID
    var stockId: UUID
    var averagePrice: Double
    var quantity: Double?
    var purchaseDate: Date?
    var sellPrice: Double?
    var sellDate: Date?
    var status: HoldingStatus
    var inputMethod: InputMethod
    var verificationState: VerificationState
    var suspicionCount: Int
    var firedEventKeys: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        stockId: UUID,
        averagePrice: Double,
        quantity: Double? = nil,
        purchaseDate: Date? = nil,
        sellPrice: Double? = nil,
        sellDate: Date? = nil,
        status: HoldingStatus = .holding,
        inputMethod: InputMethod = .manual,
        verificationState: VerificationState = .unverified,
        suspicionCount: Int = 0,
        firedEventKeys: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.stockId = stockId
        self.quantity = quantity
        self.averagePrice = averagePrice
        self.purchaseDate = purchaseDate
        self.sellPrice = sellPrice
        self.sellDate = sellDate
        self.status = status
        self.inputMethod = inputMethod
        self.verificationState = verificationState
        self.suspicionCount = suspicionCount
        self.firedEventKeys = firedEventKeys
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func returnRate(currentPrice: Double) -> Double {
        guard averagePrice > 0 else { return 0 }
        let compare = status == .sold ? (sellPrice ?? currentPrice) : currentPrice
        return (compare - averagePrice) / averagePrice
    }

    func unrealizedReturn(currentPrice: Double) -> Double {
        guard averagePrice > 0 else { return 0 }
        return (currentPrice - averagePrice) / averagePrice
    }

    func postSellMove(currentPrice: Double) -> Double? {
        guard status == .sold, let sellPrice, sellPrice > 0 else { return nil }
        return (currentPrice - sellPrice) / sellPrice
    }
}

struct PricePoint: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var date: Date
    var price: Double

    init(id: UUID = UUID(), date: Date, price: Double) {
        self.id = id
        self.date = date
        self.price = price
    }
}

enum StockIdentity {
    struct Mark: Equatable {
        var glyph: String
        var backgroundHex: String
        var foregroundHex: String
    }

    private static let known: [String: Mark] = [
        "NVDA": .init(glyph: "N", backgroundHex: "76B900", foregroundHex: "111111"),
        "AAPL": .init(glyph: "A", backgroundHex: "1C1C1E", foregroundHex: "FFFFFF"),
        "TSLA": .init(glyph: "T", backgroundHex: "CC0000", foregroundHex: "FFFFFF"),
        "AMD": .init(glyph: "A", backgroundHex: "000000", foregroundHex: "FFFFFF"),
        "MSFT": .init(glyph: "M", backgroundHex: "F5F5F5", foregroundHex: "111111"),
        "AMZN": .init(glyph: "a", backgroundHex: "FF9900", foregroundHex: "111111"),
        "GOOGL": .init(glyph: "G", backgroundHex: "FFFFFF", foregroundHex: "4285F4"),
        "META": .init(glyph: "f", backgroundHex: "0668E1", foregroundHex: "FFFFFF"),
        "AVGO": .init(glyph: "B", backgroundHex: "CC092F", foregroundHex: "FFFFFF"),
        "NFLX": .init(glyph: "N", backgroundHex: "E50914", foregroundHex: "FFFFFF"),
        "INTC": .init(glyph: "i", backgroundHex: "0071C5", foregroundHex: "FFFFFF"),
        "COIN": .init(glyph: "C", backgroundHex: "0052FF", foregroundHex: "FFFFFF"),
        "PLTR": .init(glyph: "P", backgroundHex: "111111", foregroundHex: "FFFFFF"),
        "SMCI": .init(glyph: "S", backgroundHex: "7C3AED", foregroundHex: "FFFFFF"),
        "ARM": .init(glyph: "m", backgroundHex: "0091BD", foregroundHex: "FFFFFF"),
        "005930": .init(glyph: "삼", backgroundHex: "1428A0", foregroundHex: "FFFFFF"),
        "000660": .init(glyph: "하", backgroundHex: "EE1C25", foregroundHex: "FFFFFF"),
        "035420": .init(glyph: "N", backgroundHex: "03C75A", foregroundHex: "FFFFFF"),
        "035720": .init(glyph: "K", backgroundHex: "FEE500", foregroundHex: "191919"),
        "005380": .init(glyph: "현", backgroundHex: "002C5F", foregroundHex: "FFFFFF"),
        "000270": .init(glyph: "기", backgroundHex: "05141F", foregroundHex: "FFFFFF"),
        "068270": .init(glyph: "셀", backgroundHex: "1B4B8A", foregroundHex: "FFFFFF"),
        "207940": .init(glyph: "바", backgroundHex: "1428A0", foregroundHex: "FFFFFF"),
        "051910": .init(glyph: "화", backgroundHex: "A50034", foregroundHex: "FFFFFF"),
        "006400": .init(glyph: "S", backgroundHex: "1428A0", foregroundHex: "FFFFFF"),
        "373220": .init(glyph: "에", backgroundHex: "A50034", foregroundHex: "FFFFFF"),
        "012330": .init(glyph: "모", backgroundHex: "002C5F", foregroundHex: "FFFFFF"),
        "105560": .init(glyph: "KB", backgroundHex: "FFBC00", foregroundHex: "111111"),
        "055550": .init(glyph: "신", backgroundHex: "0046FF", foregroundHex: "FFFFFF"),
        "003670": .init(glyph: "포", backgroundHex: "0B3A82", foregroundHex: "FFFFFF")
    ]

    static func mark(ticker: String, name: String = "") -> Mark {
        let key = ticker.uppercased()
        if let known = known[key] { return known }
        let glyph: String
        if ticker.allSatisfy(\.isNumber), let first = name.first {
            glyph = String(first)
        } else {
            glyph = String(ticker.prefix(1)).uppercased()
        }
        let palettes = ["405DE6", "C13584", "F77737", "833AB4", "1FA2F1", "2BB673"]
        let sum = ticker.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Mark(glyph: glyph, backgroundHex: palettes[sum % palettes.count], foregroundHex: "FFFFFF")
    }

    private static let simpleIcons: [String: String] = [
        "NVDA": "nvidia/111111",
        "AAPL": "apple/ffffff",
        "TSLA": "tesla/ffffff",
        "AMD": "amd/ffffff",
        "MSFT": "microsoft",
        "AMZN": "amazon/111111",
        "GOOGL": "google",
        "META": "meta/ffffff",
        "NFLX": "netflix/ffffff",
        "INTC": "intel/ffffff",
        "COIN": "coinbase/ffffff",
        "005930": "samsung/ffffff",
        "035420": "naver/ffffff",
        "035720": "kakaotalk/191919"
    ]

    private static let logoDomains: [String: String] = [
        "AVGO": "broadcom.com",
        "PLTR": "palantir.com",
        "SMCI": "supermicro.com",
        "ARM": "arm.com",
        "000660": "skhynix.com",
        "005380": "hyundai.com",
        "000270": "kia.com",
        "068270": "celltrion.com",
        "207940": "samsungbiologics.com",
        "051910": "lgchem.com",
        "006400": "samsungsdi.com",
        "373220": "lgensol.com",
        "012330": "mobis.co.kr",
        "105560": "kbfg.com",
        "055550": "shinhan.com",
        "003670": "poscofuturem.com"
    ]

    static func logoURL(ticker: String) -> URL? {
        let key = ticker.uppercased()
        if let slug = simpleIcons[key] {
            return URL(string: "https://cdn.simpleicons.org/\(slug)")
        }
        if let domain = logoDomains[key] {
            return URL(string: "https://www.google.com/s2/favicons?sz=128&domain=\(domain)")
        }
        return nil
    }
}

enum StockPulse {
    static let newsAge = "2시간 전 · 데모"

    struct NewsItem: Equatable {
        var title: String
        var ago: String
    }

    struct Snapshot: Equatable {
        var rating: String
        var kick: String
        var take: String
        var blurb: String
        var items: [NewsItem]
    }

    static func headlines(ticker: String) -> [NewsItem] {
        switch ticker.uppercased() {
        case "NVDA":
            [
                .init(title: "실적 발표 앞두고 거래량 늘었어요", ago: "2시간 전"),
                .init(title: "데이터센터 가이던스 이야기가 나와요", ago: "어제")
            ]
        case "AAPL":
            [
                .init(title: "서비스 매출이 버텨 준다는 이야기", ago: "3시간 전"),
                .init(title: "신제품 사이클 눈높이 조정 중", ago: "어제")
            ]
        case "TSLA":
            [
                .init(title: "인도량 숫자 가지고 말이 많아요", ago: "1시간 전"),
                .init(title: "마진 이야기가 다시 나와요", ago: "어제")
            ]
        case "AMD":
            [
                .init(title: "AI 칩 수주 이야기가 돌아요", ago: "4시간 전"),
                .init(title: "서버 GPU 수요 눈높이 이야기", ago: "그제")
            ]
        case "MSFT":
            [
                .init(title: "클라우드 실적 눈높이 이야기", ago: "2시간 전"),
                .init(title: "AI 구독이 끌고 간다는 말", ago: "어제")
            ]
        case "AMZN":
            [
                .init(title: "광고·AWS가 끌고 간다는 말", ago: "5시간 전"),
                .init(title: "물류 비용 이야기가 나와요", ago: "어제")
            ]
        case "GOOGL":
            [
                .init(title: "검색·클라우드 실적 이야기", ago: "3시간 전"),
                .init(title: "광고 단가 회복 속도 이야기", ago: "어제")
            ]
        case "META":
            [
                .init(title: "광고 회복 속도 이야기가 나와요", ago: "2시간 전"),
                .init(title: "릴스 매출 눈높이 이야기", ago: "어제")
            ]
        case "005930":
            [
                .init(title: "반도체 업황 이야기가 다시 나와요", ago: "2시간 전"),
                .init(title: "HBM·파운드리 수주 이야기", ago: "어제")
            ]
        case "000660":
            [
                .init(title: "HBM 수요 이야기가 나와요", ago: "1시간 전"),
                .init(title: "공급 계약 눈높이 이야기", ago: "어제")
            ]
        case "035420":
            [
                .init(title: "광고·커머스 회복 속도 이야기", ago: "3시간 전"),
                .init(title: "웹툰·콘텐츠 매출 이야기", ago: "어제")
            ]
        case "035720":
            [
                .init(title: "플랫폼 실적 눈높이 조정 중", ago: "2시간 전"),
                .init(title: "톡비즈 회복 속도 이야기", ago: "어제")
            ]
        default:
            [
                .init(title: "그룹에서 이 종목 이야기 중", ago: "데모")
            ]
        }
    }

    static func headline(ticker: String) -> String {
        headlines(ticker: ticker).first?.title ?? "그룹에서 이 종목 이야기 중"
    }

    static func newsLine(ticker: String) -> String {
        let item = headlines(ticker: ticker)[0]
        return "\(item.title) · \(item.ago) · 데모"
    }

    static func snapshot(
        ticker: String,
        commentCount: Int,
        pendingRecommendations: Int,
        sharedReturn: Double?
    ) -> Snapshot {
        let items = headlines(ticker: ticker)
        if commentCount >= 3 {
            return Snapshot(
                rating: "들뜸",
                kick: "glory",
                take: "지금 말이 많은 종목",
                blurb: "댓글 \(commentCount)" + (pendingRecommendations > 0 ? " · 추천 \(pendingRecommendations)" : ""),
                items: items
            )
        }
        if let sharedReturn, sharedReturn <= -0.15 {
            return Snapshot(
                rating: "물림",
                kick: "roast",
                take: "같이 물린 분위기",
                blurb: "깐부 수익률 \(percent(sharedReturn))" + (commentCount > 0 ? " · 댓글 \(commentCount)" : ""),
                items: items
            )
        }
        if let sharedReturn, sharedReturn >= 0.15 {
            return Snapshot(
                rating: "웃는 중",
                kick: "glory",
                take: "같이 웃는 분위기",
                blurb: "깐부 수익률 \(percent(sharedReturn))" + (commentCount > 0 ? " · 댓글 \(commentCount)" : ""),
                items: items
            )
        }
        if pendingRecommendations > 0 {
            return Snapshot(
                rating: "추천 중",
                kick: "plain",
                take: commentCount > 0 ? "추천이 왔고 댓글도 있음" : "추천이 와 있음",
                blurb: "추천 \(pendingRecommendations)" + (commentCount > 0 ? " · 댓글 \(commentCount)" : ""),
                items: items
            )
        }
        if commentCount > 0 {
            return Snapshot(
                rating: "이야기 중",
                kick: "plain",
                take: "댓글이 오가는 중",
                blurb: "댓글 \(commentCount)",
                items: items
            )
        }
        return Snapshot(
            rating: "조용",
            kick: "plain",
            take: "아직 말 없음",
            blurb: "그룹 평가 없음",
            items: items
        )
    }

    static func vibe(commentCount: Int, pendingRecommendations: Int, sharedReturn: Double?) -> String {
        snapshot(
            ticker: "NVDA",
            commentCount: commentCount,
            pendingRecommendations: pendingRecommendations,
            sharedReturn: sharedReturn
        ).take
    }

    private static func percent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", value * 100))%"
    }
}
