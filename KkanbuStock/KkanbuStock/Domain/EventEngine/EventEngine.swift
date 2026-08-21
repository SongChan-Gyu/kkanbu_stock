import Foundation

enum Trigger: Equatable {
    case memberJoined(userId: UUID, groupId: UUID)
    case holdingAdded(holdingId: UUID)
    case holdingSold(holdingId: UUID)
    case pricesUpdated
    case recommendationSent(id: UUID)
    case recommendationResolved(id: UUID)
    case proposalCreated(id: UUID)
    case coBuyPromised(id: UUID)
    case coBuyCompleted(id: UUID)
    case nagged(proposalId: UUID, actorId: UUID, targetUserId: UUID?, count: Int)
    case suspected(holdingId: UUID, actorId: UUID)
    case verified(holdingId: UUID, matched: Bool)
    case priceEdited(holdingId: UUID)
    case proposalDeclined(id: UUID)
    case commentPosted(id: UUID)
}

struct EventContext {
    var trigger: Trigger
    var before: AppState
    var after: AppState
    var now: Date
    var prices: [UUID: Double]
    var beforePrices: [UUID: Double]

    func stockName(_ id: UUID?) -> String {
        guard let id, let stock = after.stock(id) else { return "어떤 종목" }
        return stock.name
    }

    func ticker(_ id: UUID?) -> String {
        guard let id, let stock = after.stock(id) else { return "" }
        return stock.ticker
    }
}

protocol EventRule {
    var ruleId: String { get }
    func evaluate(context: EventContext) -> [FeedEvent]
}

/// 이벤트는 화면에 하드코딩하지 않습니다.
/// 새 사건 = EventRule 구현 후 `EventEngine.register` 또는 `defaultRules()`에 추가.
struct EventEngine {
    var rules: [any EventRule]

    init(rules: [any EventRule] = EventEngine.defaultRules()) {
        self.rules = rules
    }

    mutating func register(_ rule: any EventRule) {
        rules.append(rule)
    }

    func evaluate(context: EventContext) -> [FeedEvent] {
        rules.flatMap { $0.evaluate(context: context) }
    }

    static func defaultRules() -> [any EventRule] {
        [
            MemberJoinedRule(),
            HoldingAddedRule(),
            NewKkangbuRule(),
            GradeChangeRule(),
            SoloEscapeRule(),
            KkangbuBreakupRule(),
            DiamondHandsRule(),
            PostSellMoveRule(),
            TogetherMoveRule(),
            RecordMoveRule(),
            RankChangeRule(),
            RecommendRule(),
            ProposalRule(),
            CoBuyRule(),
            NagRule(),
            VerificationRule(),
            CommentRule()
        ]
    }
}

enum EventCopy {
    static func name(_ id: UUID?, state: AppState) -> String {
        state.nickname(id)
    }
}
