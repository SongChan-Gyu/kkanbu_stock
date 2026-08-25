import Foundation

struct HistoryRecord: Identifiable, Hashable, Sendable {
    var id: UUID
    var emoji: String
    var title: String
    var detail: String
    var result: String
    var currentReturn: Double?
}

enum SocialHistory {
    static func records(between me: UUID, friend: UUID, groupId: UUID, state: AppState, prices: [UUID: Double]) -> RelationshipHistory {
        RelationshipHistory(
            recommendedByMe: recommendations(sender: me, receiver: friend, groupId: groupId, state: state, prices: prices),
            proposedByFriend: proposals(from: friend, groupId: groupId, state: state, prices: prices),
            coBuys: cobuys(me: me, friend: friend, groupId: groupId, state: state, prices: prices),
            escapes: events(types: [.soloEscape], actor: friend, groupId: groupId, state: state),
            foresights: events(types: [.foresight], actor: friend, groupId: groupId, state: state),
            soldTooEarly: events(types: [.soldTooEarly], actor: friend, groupId: groupId, state: state),
            nags: events(types: [.persistentNagging], actor: friend, groupId: groupId, state: state)
        )
    }

    static func recommendations(sender: UUID, receiver: UUID, groupId: UUID, state: AppState, prices: [UUID: Double]) -> [HistoryRecord] {
        state.recommendations
            .filter { $0.groupId == groupId && $0.senderId == sender && $0.receiverId == receiver }
            .map { rec in
                let stock = state.stock(rec.stockId)
                let current = currentMove(stockId: rec.stockId, userId: rec.receiverId, fallbackPrice: prices[rec.stockId], state: state, prices: prices)
                let result: String
                switch rec.status {
                case .pending: result = "대기"
                case .willBuy: result = "매수 예정"
                case .accepted: result = "매수 기록"
                case .later, .rejected: result = "거절"
                }
                return HistoryRecord(
                    id: rec.id,
                    emoji: "📣",
                    title: stock?.name ?? "종목",
                    detail: "\(MoneyFormat.compactDate(rec.createdAt)) · “\(rec.message)”",
                    result: result,
                    currentReturn: current
                )
            }
    }

    static func proposals(from proposer: UUID, groupId: UUID, state: AppState, prices: [UUID: Double]) -> [HistoryRecord] {
        state.proposals
            .filter { $0.groupId == groupId && $0.proposerId == proposer }
            .map { proposal in
                let related = state.coBuys.filter { $0.proposalId == proposal.id }
                let joined = related.filter { $0.status == .completed || $0.status == .promised }.count
                let declined = related.contains { $0.status == .declined }
                let current = prices[proposal.stockId].map { price in
                    let base = StockCatalog.all.first(where: { $0.id == proposal.stockId }).map { MockStockPriceService().basePrice(for: $0) } ?? price
                    return (price - base) / max(base, 0.01)
                }
                let result: String
                if related.contains(where: { $0.status == .completed }) {
                    result = "매수 완료"
                } else if declined {
                    result = "거절 있음"
                } else {
                    result = "약속 \(joined)명"
                }
                return HistoryRecord(
                    id: proposal.id,
                    emoji: "🤔",
                    title: state.stock(proposal.stockId)?.name ?? "종목",
                    detail: "\(MoneyFormat.compactDate(proposal.createdAt)) · “\(proposal.message)”",
                    result: result,
                    currentReturn: current
                )
            }
    }

    static func cobuys(me: UUID, friend: UUID, groupId: UUID, state: AppState, prices: [UUID: Double]) -> [HistoryRecord] {
        let proposalIds = Set(
            state.coBuys.filter { $0.groupId == groupId && ($0.userId == me || $0.userId == friend) }.map(\.proposalId)
        )
        return state.proposals.filter { proposalIds.contains($0.id) }.map { proposal in
            let related = state.coBuys.filter { $0.proposalId == proposal.id }
            let names = related.filter { $0.status != .declined }.compactMap { state.nickname($0.userId) }
            let done = related.contains { $0.status == .completed }
            return HistoryRecord(
                id: proposal.id,
                emoji: "🤝",
                title: state.stock(proposal.stockId)?.name ?? "종목",
                detail: names.joined(separator: " · "),
                result: done ? "매수 완료" : "진행 중",
                currentReturn: currentMove(stockId: proposal.stockId, userId: me, fallbackPrice: prices[proposal.stockId], state: state, prices: prices)
            )
        }
    }

    static func events(types: [EventType], actor: UUID, groupId: UUID, state: AppState) -> [HistoryRecord] {
        state.events
            .filter { $0.groupId == groupId && $0.actorId == actor && types.contains($0.type) }
            .map { event in
                HistoryRecord(
                    id: event.id,
                    emoji: event.type.emoji,
                    title: event.title,
                    detail: event.message,
                    result: MoneyFormat.relative(event.createdAt),
                    currentReturn: nil
                )
            }
    }

    private static func currentMove(stockId: UUID, userId: UUID, fallbackPrice: Double?, state: AppState, prices: [UUID: Double]) -> Double? {
        if let holding = state.holdings.first(where: { $0.userId == userId && $0.stockId == stockId }) {
            return holding.returnRate(currentPrice: prices[stockId] ?? holding.averagePrice)
        }
        guard let price = fallbackPrice, let stock = state.stock(stockId) else { return nil }
        let base = MockStockPriceService().basePrice(for: stock)
        return (price - base) / max(base, 0.01)
    }
}

struct RelationshipHistory: Sendable {
    var recommendedByMe: [HistoryRecord]
    var proposedByFriend: [HistoryRecord]
    var coBuys: [HistoryRecord]
    var escapes: [HistoryRecord]
    var foresights: [HistoryRecord]
    var soldTooEarly: [HistoryRecord]
    var nags: [HistoryRecord]
}

enum GroupSocial {
    static func spicyEvents(in groupId: UUID, state: AppState) -> [FeedEvent] {
        let spicy: Set<EventType> = [
            .soloEscape, .foresight, .soldTooEarly, .newKkangbu, .goldenKkangbu,
            .worstPartner, .graveyardPartners, .godsMovePartners, .destinyPartners,
            .buriedTogether, .moonTogether, .persistentNagging, .verificationRequested,
            .coBuyCompleted, .kkangbuRecruited, .diamondHands
        ]
        return state.events.filter { $0.groupId == groupId && spicy.contains($0.type) }
    }

    static func memberHoldings(in groupId: UUID, state: AppState) -> [(User, Holding)] {
        let memberIds = Set(state.members(of: groupId).map(\.userId))
        return state.holdings
            .filter { memberIds.contains($0.userId) }
            .compactMap { holding in
                guard let user = state.user(holding.userId) else { return nil }
                return (user, holding)
            }
            .sorted { $0.1.updatedAt > $1.1.updatedAt }
    }
}
