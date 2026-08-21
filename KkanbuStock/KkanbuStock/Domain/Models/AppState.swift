import Foundation

struct AppState: Codable, Sendable {
    var currentUserId: UUID
    var selectedGroupId: UUID?
    var users: [User]
    var groups: [Group]
    var members: [GroupMember]
    var stocks: [Stock]
    var holdings: [Holding]
    var recommendations: [StockRecommendation]
    var proposals: [StockProposal]
    var coBuys: [CoBuyRequest]
    var relationships: [FriendRelationship]
    var events: [FeedEvent]
    var badges: [Badge]
    var suspicions: [GurapingSuspicion]
    var comments: [StockComment]
    var thresholds: EventThresholds
    var livePriceOffsets: [UUID: Double]
    var hasCompletedOnboarding: Bool
    var disclaimerAcknowledged: Bool

    static func empty(user: User, stocks: [Stock]) -> AppState {
        AppState(
            currentUserId: user.id,
            selectedGroupId: nil,
            users: [user],
            groups: [],
            members: [],
            stocks: stocks,
            holdings: [],
            recommendations: [],
            proposals: [],
            coBuys: [],
            relationships: [],
            events: [],
            badges: [],
            suspicions: [],
            comments: [],
            thresholds: .default,
            livePriceOffsets: [:],
            hasCompletedOnboarding: false,
            disclaimerAcknowledged: false
        )
    }

    var currentUser: User {
        users.first(where: { $0.id == currentUserId }) ?? User(id: currentUserId, nickname: "나")
    }

    var selectedGroup: Group? {
        groups.first(where: { $0.id == selectedGroupId })
    }

    func user(_ id: UUID) -> User? {
        users.first(where: { $0.id == id })
    }

    func stock(_ id: UUID) -> Stock? {
        stocks.first(where: { $0.id == id })
    }

    func holding(_ id: UUID) -> Holding? {
        holdings.first(where: { $0.id == id })
    }

    func group(_ id: UUID) -> Group? {
        groups.first(where: { $0.id == id })
    }

    func members(of groupId: UUID) -> [GroupMember] {
        members.filter { $0.groupId == groupId }
    }

    func memberUsers(of groupId: UUID) -> [User] {
        members(of: groupId).compactMap { user($0.userId) }
    }

    func groups(for userId: UUID) -> [Group] {
        let ids = Set(members.filter { $0.userId == userId }.map(\.groupId))
        return groups.filter { ids.contains($0.id) }
    }

    func activeHoldings(of userId: UUID) -> [Holding] {
        holdings.filter { $0.userId == userId && $0.status == .holding }
    }

    func holdings(of userId: UUID, stockId: UUID, status: HoldingStatus = .holding) -> [Holding] {
        holdings.filter { $0.userId == userId && $0.stockId == stockId && $0.status == status }
    }

    func nickname(_ id: UUID?) -> String {
        guard let id, let user = user(id) else { return "누군가" }
        return user.nickname
    }
}
