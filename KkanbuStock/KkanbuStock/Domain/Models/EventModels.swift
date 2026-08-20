import Foundation

struct EventThresholds: Codable, Hashable, Sendable {
    var goldenReturn: Double
    var destinySharedCount: Int
    var godsMoveReturn: Double
    var worstPartnerReturn: Double
    var graveyardReturn: Double
    var moonTogetherReturn: Double
    var foresightDrop: Double
    var soldTooEarlyRise: Double
    var postSellWindowDays: Int
    var recordMove: Double

    static let `default` = EventThresholds(
        goldenReturn: 0.30,
        destinySharedCount: 3,
        godsMoveReturn: 0.50,
        worstPartnerReturn: -0.30,
        graveyardReturn: -0.50,
        moonTogetherReturn: 0.20,
        foresightDrop: 0.10,
        soldTooEarlyRise: 0.10,
        postSellWindowDays: 7,
        recordMove: 0.08
    )
}

enum EventType: String, Codable, CaseIterable, Sendable {
    case newKkangbu = "NEW_KKANGBU"
    case goldenKkangbu = "GOLDEN_KKANGBU"
    case worstPartner = "WORST_PARTNER"
    case soloEscape = "SOLO_ESCAPE"
    case kkangbuBreakup = "KKANGBU_BREAKUP"
    case foresight = "FORESIGHT"
    case soldTooEarly = "SOLD_TOO_EARLY"
    case diamondHands = "DIAMOND_HANDS"
    case buriedTogether = "BURIED_TOGETHER"
    case moonTogether = "MOON_TOGETHER"
    case recommendStock = "RECOMMEND_STOCK"
    case recommendAccepted = "RECOMMEND_ACCEPTED"
    case recommendRejected = "RECOMMEND_REJECTED"
    case proposalCreated = "PROPOSAL_CREATED"
    case coBuyRequest = "CO_BUY_REQUEST"
    case coBuyAccepted = "CO_BUY_ACCEPTED"
    case coBuyCompleted = "CO_BUY_COMPLETED"
    case persistentNagging = "PERSISTENT_NAGGING"
    case kkangbuRecruited = "KKANGBU_RECRUITED"
    case recordHigh = "RECORD_HIGH"
    case recordLow = "RECORD_LOW"
    case groupRankChanged = "GROUP_RANK_CHANGED"
    case screenshotVerified = "SCREENSHOT_VERIFIED"
    case verificationRequested = "VERIFICATION_REQUESTED"
    case verificationSuccess = "VERIFICATION_SUCCESS"
    case verificationMismatch = "VERIFICATION_MISMATCH"
    case holdingPriceUpdated = "HOLDING_PRICE_UPDATED"
    case trustScoreChanged = "TRUST_SCORE_CHANGED"
    case memberJoined = "MEMBER_JOINED"
    case holdingAdded = "HOLDING_ADDED"
    case holdingSold = "HOLDING_SOLD"
    case destinyPartners = "DESTINY_PARTNERS"
    case godsMovePartners = "GODS_MOVE_PARTNERS"
    case graveyardPartners = "GRAVEYARD_PARTNERS"

    var emoji: String {
        switch self {
        case .newKkangbu, .kkangbuRecruited: "🤝"
        case .goldenKkangbu: "🔥"
        case .worstPartner: "💀"
        case .soloEscape: "🏃"
        case .kkangbuBreakup: "💔"
        case .foresight: "🧠"
        case .soldTooEarly: "🤡"
        case .diamondHands: "💎"
        case .buriedTogether: "🪦"
        case .moonTogether: "🚀"
        case .recommendStock: "📣"
        case .recommendAccepted: "🎉"
        case .recommendRejected: "📭"
        case .proposalCreated: "🤔"
        case .coBuyRequest, .coBuyAccepted: "🤝"
        case .coBuyCompleted: "🎉"
        case .persistentNagging: "😂"
        case .recordHigh: "🏆"
        case .recordLow: "📉"
        case .groupRankChanged: "👑"
        case .screenshotVerified: "📸"
        case .verificationRequested: "🕵️"
        case .verificationSuccess: "😎"
        case .verificationMismatch: "🚨"
        case .holdingPriceUpdated: "😂"
        case .trustScoreChanged: "🟢"
        case .memberJoined: "👋"
        case .holdingAdded: "✨"
        case .holdingSold: "🏃"
        case .destinyPartners: "💎"
        case .godsMovePartners: "🚀"
        case .graveyardPartners: "🪦"
        }
    }
}

struct FeedEvent: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var groupId: UUID
    var type: EventType
    var actorId: UUID?
    var targetUserId: UUID?
    var stockId: UUID?
    var holdingId: UUID?
    var title: String
    var message: String
    var metadata: [String: String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        groupId: UUID,
        type: EventType,
        actorId: UUID? = nil,
        targetUserId: UUID? = nil,
        stockId: UUID? = nil,
        holdingId: UUID? = nil,
        title: String,
        message: String,
        metadata: [String: String] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.type = type
        self.actorId = actorId
        self.targetUserId = targetUserId
        self.stockId = stockId
        self.holdingId = holdingId
        self.title = title
        self.message = message
        self.metadata = metadata
        self.createdAt = createdAt
    }
}

struct PushPayload: Equatable, Sendable {
    var title: String
    var body: String
    var eventType: EventType
    var groupId: UUID
}

protocol NotificationPort: AnyObject {
    func deliver(_ payload: PushPayload)
}

/// Future push notifications plug in here. MVP records in-app activity only.
final class InAppNotificationPort: NotificationPort {
    var inbox: [PushPayload] = []

    func deliver(_ payload: PushPayload) {
        inbox.insert(payload, at: 0)
    }
}

struct KkangbuGrade: Identifiable, Hashable, Sendable {
    var id: String
    var emoji: String
    var title: String
    var priority: Int
}

struct KkangbuBond: Identifiable, Hashable, Sendable {
    var id: String
    var groupId: UUID
    var stockId: UUID
    var userA: UUID
    var userB: UUID
    var startedAt: Date
    var sharedReturn: Double
    var grade: KkangbuGrade
    var holdingA: UUID
    var holdingB: UUID

    var members: [UUID] { [userA, userB] }

    func partner(of userId: UUID) -> UUID? {
        if userA == userId { return userB }
        if userB == userId { return userA }
        return nil
    }
}

struct PairSummary: Identifiable, Hashable, Sendable {
    var id: String
    var groupId: UUID
    var userA: UUID
    var userB: UUID
    var bonds: [KkangbuBond]
    var grade: KkangbuGrade
    var averageReturn: Double
    var startedAt: Date

    var sharedCount: Int { bonds.count }
}

struct RankingRow: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var emoji: String
    var userId: UUID?
    var subtitle: String
    var valueText: String
}

struct RankingBoard: Hashable, Sendable {
    var weeklyReturns: [RankingRow]
    var titles: [RankingRow]
}
