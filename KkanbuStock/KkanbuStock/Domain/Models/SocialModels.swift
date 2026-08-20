import Foundation

enum RecommendationStatus: String, Codable, Sendable {
    case pending
    case accepted
    case later
    case rejected
}

struct StockRecommendation: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var groupId: UUID
    var senderId: UUID
    var receiverId: UUID
    var stockId: UUID
    var holdingId: UUID
    var message: String
    var status: RecommendationStatus
    var createdAt: Date
    var resolvedAt: Date?

    init(
        id: UUID = UUID(),
        groupId: UUID,
        senderId: UUID,
        receiverId: UUID,
        stockId: UUID,
        holdingId: UUID,
        message: String,
        status: RecommendationStatus = .pending,
        createdAt: Date = Date(),
        resolvedAt: Date? = nil
    ) {
        self.id = id
        self.groupId = groupId
        self.senderId = senderId
        self.receiverId = receiverId
        self.stockId = stockId
        self.holdingId = holdingId
        self.message = message
        self.status = status
        self.createdAt = createdAt
        self.resolvedAt = resolvedAt
    }
}

enum ProposalStatus: String, Codable, Sendable {
    case open
    case completed
    case closed
}

struct StockProposal: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var groupId: UUID
    var proposerId: UUID
    var stockId: UUID
    var message: String
    var status: ProposalStatus
    var createdAt: Date

    init(
        id: UUID = UUID(),
        groupId: UUID,
        proposerId: UUID,
        stockId: UUID,
        message: String,
        status: ProposalStatus = .open,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.proposerId = proposerId
        self.stockId = stockId
        self.message = message
        self.status = status
        self.createdAt = createdAt
    }
}

enum CoBuyStatus: String, Codable, Sendable {
    case promised
    case completed
    case declined
}

struct CoBuyRequest: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var proposalId: UUID
    var groupId: UUID
    var userId: UUID
    var stockId: UUID
    var status: CoBuyStatus
    var nagCount: Int
    var lastNagAt: Date?
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        proposalId: UUID,
        groupId: UUID,
        userId: UUID,
        stockId: UUID,
        status: CoBuyStatus = .promised,
        nagCount: Int = 0,
        lastNagAt: Date? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.proposalId = proposalId
        self.groupId = groupId
        self.userId = userId
        self.stockId = stockId
        self.status = status
        self.nagCount = nagCount
        self.lastNagAt = lastNagAt
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

struct FriendRelationship: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var groupId: UUID
    var userId: UUID
    var friendUserId: UUID
    var gradeRaw: String
    var score: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        groupId: UUID,
        userId: UUID,
        friendUserId: UUID,
        gradeRaw: String,
        score: Double,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.userId = userId
        self.friendUserId = friendUserId
        self.gradeRaw = gradeRaw
        self.score = score
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct GurapingSuspicion: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var groupId: UUID
    var holdingId: UUID
    var actorId: UUID
    var targetUserId: UUID
    var createdAt: Date

    init(
        id: UUID = UUID(),
        groupId: UUID,
        holdingId: UUID,
        actorId: UUID,
        targetUserId: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.groupId = groupId
        self.holdingId = holdingId
        self.actorId = actorId
        self.targetUserId = targetUserId
        self.createdAt = createdAt
    }
}

struct Badge: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var userId: UUID
    var groupId: UUID?
    var type: String
    var title: String
    var emoji: String
    var earnedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        groupId: UUID? = nil,
        type: String,
        title: String,
        emoji: String,
        earnedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.groupId = groupId
        self.type = type
        self.title = title
        self.emoji = emoji
        self.earnedAt = earnedAt
    }
}

struct TrustStats: Codable, Hashable, Sendable {
    var verifiedCount: Int
    var suspectedCount: Int
    var successCount: Int
    var mismatchCount: Int
    var updatedCount: Int

    var score: Int {
        let raw = 70
            + verifiedCount * 3
            + successCount * 4
            - suspectedCount * 2
            - mismatchCount * 6
            - updatedCount * 3
        return min(99, max(12, raw))
    }
}

enum SocialLimits {
    static let nagCooldown: TimeInterval = 6 * 60 * 60
    static let maxNagsPerProposal = 3
    static let suspicionCooldown: TimeInterval = 12 * 60 * 60
}
