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

enum TakeLevel: Int, Codable, CaseIterable, Sendable, Hashable {
    case strongSell = -2
    case sell = -1
    case hold = 0
    case buy = 1
    case strongBuy = 2

    var title: String {
        switch self {
        case .strongSell: "강력 매도"
        case .sell: "매도"
        case .hold: "관망"
        case .buy: "추천"
        case .strongBuy: "강력 추천"
        }
    }

    var shortTitle: String {
        switch self {
        case .strongSell: "강매도"
        case .sell: "매도"
        case .hold: "관망"
        case .buy: "추천"
        case .strongBuy: "강추천"
        }
    }

    var kick: String {
        switch self {
        case .strongSell, .sell: "roast"
        case .strongBuy, .buy: "glory"
        case .hold: "plain"
        }
    }

    static func consensus(_ levels: [TakeLevel]) -> TakeLevel? {
        guard !levels.isEmpty else { return nil }
        let avg = Double(levels.map(\.rawValue).reduce(0, +)) / Double(levels.count)
        return TakeLevel(rawValue: Int(avg.rounded())) ?? .hold
    }
}

enum StockPulse {
    static let newsAge = "2시간 전 · 데모"
    private static let chipPhoto = "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=400&h=280&q=60"
    private static let phonePhoto = "https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?auto=format&fit=crop&w=400&h=280&q=60"
    private static let carPhoto = "https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=400&h=280&q=60"
    private static let cloudPhoto = "https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=400&h=280&q=60"
    private static let shopPhoto = "https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=400&h=280&q=60"
    private static let socialPhoto = "https://images.unsplash.com/photo-1611162616475-46b635cb6868?auto=format&fit=crop&w=400&h=280&q=60"

    struct NewsItem: Equatable, Identifiable {
        var id: String { title + source }
        var title: String
        var ago: String
        var source: String
        var query: String
        var image: String
        var kr: Bool

        var url: URL { StockPulse.newsURL(query: query, kr: kr) }
        var imageURL: URL? { URL(string: image) }
    }

    struct Snapshot: Equatable {
        var rating: String
        var kick: String
        var take: String
        var blurb: String
        var items: [NewsItem]
        var groupTake: TakeLevel? = nil
        var takeCount: Int = 0
        var myTake: TakeLevel? = nil
    }

    static func newsURL(query: String, kr: Bool) -> URL {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        if kr {
            return URL(string: "https://search.naver.com/search.naver?where=news&query=\(encoded)")!
        }
        return URL(string: "https://news.google.com/search?q=\(encoded)&hl=ko&gl=KR&ceid=KR:ko")!
    }

    private static func item(_ title: String, _ ago: String, _ source: String, _ query: String, _ image: String, kr: Bool = false) -> NewsItem {
        NewsItem(title: title, ago: ago, source: source, query: query, image: image, kr: kr)
    }

    static func headlines(ticker: String) -> [NewsItem] {
        switch ticker.uppercased() {
        case "NVDA":
            [
                item("엔비디아, 실적 발표 앞두고 거래량 증가", "2시간 전", "한국경제", "엔비디아 실적 거래량", chipPhoto),
                item("데이터센터 가이던스 전망이 다시 나와", "어제", "매일경제", "엔비디아 데이터센터 가이던스", chipPhoto)
            ]
        case "AAPL":
            [
                item("애플 서비스 매출이 실적을 받쳐 준다는 분석", "3시간 전", "서울경제", "애플 서비스 매출", phonePhoto),
                item("신제품 사이클 눈높이 조정 중", "어제", "한국경제", "애플 신제품 사이클", phonePhoto)
            ]
        case "TSLA":
            [
                item("테슬라 인도량 숫자를 놓고 전망이 갈려", "1시간 전", "매일경제", "테슬라 인도량", carPhoto),
                item("마진 회복 속도가 다시 주목받는 이유", "어제", "한국경제", "테슬라 마진", carPhoto)
            ]
        case "AMD":
            [
                item("AMD, AI 칩 수주 이야기가 다시 나와", "4시간 전", "서울경제", "AMD AI 칩 수주", chipPhoto),
                item("서버 GPU 수요 눈높이 조정 중", "어제", "매일경제", "AMD 서버 GPU", chipPhoto)
            ]
        case "MSFT":
            [
                item("마이크로소프트 클라우드 실적 눈높이", "2시간 전", "한국경제", "마이크로소프트 클라우드 실적", cloudPhoto),
                item("AI 구독이 실적을 끌고 간다는 분석", "어제", "매일경제", "마이크로소프트 AI 구독", cloudPhoto)
            ]
        case "AMZN":
            [
                item("아마존 광고·AWS가 실적을 끌고 간다", "5시간 전", "서울경제", "아마존 AWS 광고", shopPhoto),
                item("물류 비용 이야기가 다시 나와", "어제", "한국경제", "아마존 물류 비용", shopPhoto)
            ]
        case "GOOGL":
            [
                item("구글 검색·클라우드 실적 이야기", "3시간 전", "한국경제", "구글 클라우드 실적", cloudPhoto),
                item("광고 단가 회복 속도가 관전 포인트", "어제", "매일경제", "구글 광고 단가", cloudPhoto)
            ]
        case "META":
            [
                item("메타 광고 회복 속도가 다시 나와", "2시간 전", "서울경제", "메타 광고 회복", socialPhoto),
                item("릴스 매출 눈높이 이야기", "어제", "한국경제", "메타 릴스 매출", socialPhoto)
            ]
        case "005930":
            [
                item("삼성전자, 반도체 업황 이야기가 다시 나와", "2시간 전", "한국경제", "삼성전자 반도체 업황", chipPhoto, kr: true),
                item("HBM·파운드리 수주 전망", "어제", "매일경제", "삼성전자 HBM 파운드리", chipPhoto, kr: true)
            ]
        case "000660":
            [
                item("SK하이닉스 HBM 수요 이야기가 나와", "1시간 전", "한국경제", "SK하이닉스 HBM", chipPhoto, kr: true),
                item("공급 계약 눈높이 조정 중", "어제", "서울경제", "SK하이닉스 공급 계약", chipPhoto, kr: true)
            ]
        case "035420":
            [
                item("네이버 광고·커머스 회복 속도", "3시간 전", "매일경제", "네이버 광고 커머스", shopPhoto, kr: true),
                item("웹툰·콘텐츠 매출 이야기", "어제", "한국경제", "네이버 웹툰 매출", socialPhoto, kr: true)
            ]
        case "035720":
            [
                item("카카오 플랫폼 실적 눈높이 조정", "2시간 전", "한국경제", "카카오 실적", socialPhoto, kr: true),
                item("톡비즈 회복 속도가 관전 포인트", "어제", "서울경제", "카카오 톡비즈", socialPhoto, kr: true)
            ]
        default:
            [
                item("그룹에서 이 종목 이야기 중", "데모", "뉴스", ticker, chipPhoto)
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
        sharedReturn: Double?,
        groupTake: TakeLevel? = nil,
        takeCount: Int = 0,
        myTake: TakeLevel? = nil
    ) -> Snapshot {
        let items = headlines(ticker: ticker)
        var snap: Snapshot
        if commentCount >= 3 {
            snap = Snapshot(
                rating: "들뜸",
                kick: "glory",
                take: "지금 말이 많은 종목",
                blurb: "댓글 \(commentCount)" + (pendingRecommendations > 0 ? " · 추천 \(pendingRecommendations)" : ""),
                items: items
            )
        } else if let sharedReturn, sharedReturn <= -0.15 {
            snap = Snapshot(
                rating: "물림",
                kick: "roast",
                take: "같이 물린 분위기",
                blurb: "깐부 수익률 \(percent(sharedReturn))" + (commentCount > 0 ? " · 댓글 \(commentCount)" : ""),
                items: items
            )
        } else if let sharedReturn, sharedReturn >= 0.15 {
            snap = Snapshot(
                rating: "웃는 중",
                kick: "glory",
                take: "같이 웃는 분위기",
                blurb: "깐부 수익률 \(percent(sharedReturn))" + (commentCount > 0 ? " · 댓글 \(commentCount)" : ""),
                items: items
            )
        } else if pendingRecommendations > 0 {
            snap = Snapshot(
                rating: "추천 중",
                kick: "plain",
                take: commentCount > 0 ? "추천이 왔고 댓글도 있음" : "추천이 와 있음",
                blurb: "추천 \(pendingRecommendations)" + (commentCount > 0 ? " · 댓글 \(commentCount)" : ""),
                items: items
            )
        } else if commentCount > 0 {
            snap = Snapshot(
                rating: "이야기 중",
                kick: "plain",
                take: "댓글이 오가는 중",
                blurb: "댓글 \(commentCount)",
                items: items
            )
        } else {
            snap = Snapshot(
                rating: "관망",
                kick: "plain",
                take: "아직 평가 없음",
                blurb: "그룹 평가 없음",
                items: items
            )
        }
        if let groupTake {
            snap.rating = groupTake.title
            snap.kick = groupTake.kick
            snap.take = takeCount > 0 ? "그룹 \(takeCount)명 평가" : groupTake.title
        }
        snap.groupTake = groupTake
        snap.takeCount = takeCount
        snap.myTake = myTake
        return snap
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
