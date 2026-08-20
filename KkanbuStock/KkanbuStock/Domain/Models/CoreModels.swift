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
