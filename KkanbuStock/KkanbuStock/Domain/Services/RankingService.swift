import Foundation

enum RankingService {
    static func board(groupId: UUID, state: AppState, prices: [UUID: Double], now: Date = Date()) -> RankingBoard {
        let memberIds = state.members(of: groupId).map(\.userId)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now

        let weekly: [RankingRow] = memberIds.compactMap { userId in
            guard let user = state.user(userId) else { return nil }
            let value = weeklyReturn(userId: userId, state: state, prices: prices)
            return RankingRow(
                id: "week-\(userId)",
                title: user.nickname,
                emoji: placeEmoji(for: 0),
                userId: userId,
                subtitle: "이번 주 분위기",
                valueText: MoneyFormat.percent(value)
            )
        }
        .sorted { lhs, rhs in
            weeklyReturn(userId: lhs.userId!, state: state, prices: prices)
                > weeklyReturn(userId: rhs.userId!, state: state, prices: prices)
        }
        .enumerated()
        .map { index, row in
            var copy = row
            copy.emoji = placeEmoji(for: index)
            copy.title = "\(copy.emoji) \(state.nickname(copy.userId))"
            return copy
        }

        let bonds = KkangbuMath.bonds(in: groupId, state: state, prices: prices)
        let titles: [RankingRow] = [
            king("투자왕", "👑", memberIds.max(by: {
                avgReturn($0, state, prices) < avgReturn($1, state, prices)
            }), state, suffix: { MoneyFormat.percent(avgReturn($0, state, prices)) }, fallback: "아직 없음"),
            king("깐부왕", "🤝", memberIds.max(by: {
                bondCount($0, bonds) < bondCount($1, bonds)
            }), state, suffix: { "깐부 \(bondCount($0, bonds))명" }, fallback: "아직 없음"),
            king("깐부 영입왕", "🎉", memberIds.max(by: {
                eventCount($0, [.kkangbuRecruited, .recommendAccepted, .coBuyCompleted], groupId, state) <
                eventCount($1, [.kkangbuRecruited, .recommendAccepted, .coBuyCompleted], groupId, state)
            }), state, suffix: { "영입 \(eventCount($0, [.kkangbuRecruited, .recommendAccepted, .coBuyCompleted], groupId, state))회" }, fallback: "아직 없음"),
            king("같이 사기 성공왕", "🤝", memberIds.max(by: {
                eventCount($0, [.coBuyCompleted], groupId, state) < eventCount($1, [.coBuyCompleted], groupId, state)
            }), state, suffix: { "성공 \(eventCount($0, [.coBuyCompleted], groupId, state))회" }, fallback: "아직 없음"),
            king("주식 제안왕", "🤔", memberIds.max(by: {
                eventCount($0, [.proposalCreated, .recommendStock], groupId, state) <
                eventCount($1, [.proposalCreated, .recommendStock], groupId, state)
            }), state, suffix: { "제안 \(eventCount($0, [.proposalCreated, .recommendStock], groupId, state))회" }, fallback: "아직 없음"),
            king("신의 한 수", "🏆", bestRecommendation(groupId: groupId, state: state, prices: prices, now: now)?.0, state, suffix: { _ in
                bestRecommendation(groupId: groupId, state: state, prices: prices, now: now).map { MoneyFormat.percent($0.1) } ?? "-"
            }, fallback: "아직 없음"),
            king("최악의 추천", "📉", worstRecommendation(groupId: groupId, state: state, prices: prices)?.0, state, suffix: { _ in
                worstRecommendation(groupId: groupId, state: state, prices: prices).map { MoneyFormat.percent($0.1) } ?? "-"
            }, fallback: "아직 없음"),
            king("선견지명왕", "🧠", memberIds.max(by: {
                eventCount($0, [.foresight], groupId, state) < eventCount($1, [.foresight], groupId, state)
            }), state, suffix: { "선견지명 \(eventCount($0, [.foresight], groupId, state))회" }, fallback: "아직 없음"),
            king("혼자 튄 사람", "🏃", memberIds.max(by: {
                eventCount($0, [.soloEscape], groupId, state) < eventCount($1, [.soloEscape], groupId, state)
            }), state, suffix: { "탈출 \(eventCount($0, [.soloEscape], groupId, state))회" }, fallback: "아직 없음"),
            king("존버왕", "💎", memberIds.max(by: {
                eventCount($0, [.diamondHands], groupId, state) < eventCount($1, [.diamondHands], groupId, state)
            }), state, suffix: { "존버 \(eventCount($0, [.diamondHands], groupId, state))회" }, fallback: "아직 없음"),
            popularStock(groupId: groupId, state: state)
        ]

        _ = weekAgo
        return RankingBoard(weeklyReturns: weekly, titles: titles)
    }

    private static func placeEmoji(for index: Int) -> String {
        switch index {
        case 0: "🥇"
        case 1: "🥈"
        case 2: "🥉"
        default: "🎮"
        }
    }

    private static func avgReturn(_ userId: UUID, _ state: AppState, _ prices: [UUID: Double]) -> Double {
        let list = state.activeHoldings(of: userId)
        guard !list.isEmpty else { return 0 }
        let values = list.map { $0.returnRate(currentPrice: prices[$0.stockId] ?? $0.averagePrice) }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func weeklyReturn(userId: UUID, state: AppState, prices: [UUID: Double]) -> Double {
        avgReturn(userId, state, prices)
    }

    private static func bondCount(_ userId: UUID, _ bonds: [KkangbuBond]) -> Int {
        Set(bonds.filter { $0.userA == userId || $0.userB == userId }.map { $0.partner(of: userId)! }).count
    }

    private static func eventCount(_ userId: UUID, _ types: [EventType], _ groupId: UUID, _ state: AppState) -> Int {
        state.events.filter { $0.groupId == groupId && $0.actorId == userId && types.contains($0.type) }.count
    }

    private static func king(
        _ title: String,
        _ emoji: String,
        _ userId: UUID?,
        _ state: AppState,
        suffix: (UUID) -> String,
        fallback: String
    ) -> RankingRow {
        guard let userId else {
            return RankingRow(id: title, title: title, emoji: emoji, userId: nil, subtitle: fallback, valueText: "-")
        }
        return RankingRow(
            id: title,
            title: title,
            emoji: emoji,
            userId: userId,
            subtitle: state.nickname(userId),
            valueText: suffix(userId)
        )
    }

    private static func recommendationMove(
        groupId: UUID,
        state: AppState,
        prices: [UUID: Double]
    ) -> [(UUID, Double)] {
        state.recommendations
            .filter { $0.groupId == groupId && $0.status == .accepted }
            .compactMap { rec in
                guard let holding = state.holdings.first(where: {
                    $0.userId == rec.receiverId && $0.stockId == rec.stockId && $0.status == .holding
                }) else { return nil }
                let price = prices[rec.stockId] ?? holding.averagePrice
                return (rec.senderId, holding.returnRate(currentPrice: price))
            }
    }

    private static func bestRecommendation(groupId: UUID, state: AppState, prices: [UUID: Double], now: Date) -> (UUID, Double)? {
        _ = now
        return recommendationMove(groupId: groupId, state: state, prices: prices).max(by: { $0.1 < $1.1 })
    }

    private static func worstRecommendation(groupId: UUID, state: AppState, prices: [UUID: Double]) -> (UUID, Double)? {
        recommendationMove(groupId: groupId, state: state, prices: prices).min(by: { $0.1 < $1.1 })
    }

    private static func popularStock(groupId: UUID, state: AppState) -> RankingRow {
        let memberIds = Set(state.members(of: groupId).map(\.userId))
        let counts = Dictionary(grouping: state.holdings.filter { $0.status == .holding && memberIds.contains($0.userId) }, by: \.stockId)
            .mapValues { Set($0.map(\.userId)).count }
        guard let best = counts.max(by: { $0.value < $1.value }), let stock = state.stock(best.key) else {
            return RankingRow(id: "popular", title: "가장 인기 있는 종목", emoji: "⭐", userId: nil, subtitle: "아직 없음", valueText: "-")
        }
        return RankingRow(
            id: "popular",
            title: "가장 인기 있는 종목",
            emoji: "⭐",
            userId: nil,
            subtitle: stock.name,
            valueText: "\(best.value)명 보유"
        )
    }
}

enum TrustMath {
    static func stats(for userId: UUID, state: AppState) -> TrustStats {
        let holdings = state.holdings.filter { $0.userId == userId }
        let verified = holdings.filter { $0.verificationState == .screenshotVerified }.count
        let suspected = state.suspicions.filter { $0.targetUserId == userId }.count
        let success = state.events.filter { $0.actorId == userId && $0.type == .verificationSuccess }.count
        let mismatch = state.events.filter { $0.actorId == userId && $0.type == .verificationMismatch }.count
        let updated = state.events.filter { $0.actorId == userId && $0.type == .holdingPriceUpdated }.count
        return TrustStats(
            verifiedCount: verified,
            suspectedCount: suspected,
            successCount: success,
            mismatchCount: mismatch,
            updatedCount: updated
        )
    }
}
