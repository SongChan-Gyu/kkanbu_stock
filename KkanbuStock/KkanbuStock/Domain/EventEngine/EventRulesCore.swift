import Foundation

struct MemberJoinedRule: EventRule {
    let ruleId = "MemberJoinedRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case let .memberJoined(userId, groupId) = context.trigger else { return [] }
        return [
            FeedEvent(
                groupId: groupId,
                type: .memberJoined,
                actorId: userId,
                title: "👋 새 멤버",
                message: "\(context.after.nickname(userId))님이 그룹에 들어왔습니다. 이제 같이 놀 사람 한 명 늘었어요."
            )
        ]
    }
}

struct HoldingAddedRule: EventRule {
    let ruleId = "HoldingAddedRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case let .holdingAdded(holdingId) = context.trigger,
              let holding = context.after.holding(holdingId) else { return [] }
        return context.after.groups(for: holding.userId).map { group in
            FeedEvent(
                groupId: group.id,
                type: .holdingAdded,
                actorId: holding.userId,
                stockId: holding.stockId,
                holdingId: holding.id,
                title: "✨ 새 종목",
                message: "\(context.after.nickname(holding.userId))님이 \(context.stockName(holding.stockId))를 추가했습니다."
            )
        }
    }
}

struct NewKkangbuRule: EventRule {
    let ruleId = "NewKkangbuRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case let .holdingAdded(holdingId) = context.trigger,
              let holding = context.after.holding(holdingId) else { return [] }

        return context.after.groups(for: holding.userId).flatMap { group -> [FeedEvent] in
            let beforeBonds = Set(KkangbuMath.bonds(in: group.id, state: context.before, prices: context.beforePrices).map(\.id))
            let afterBonds = KkangbuMath.bonds(in: group.id, state: context.after, prices: context.prices)
            return afterBonds.filter { !beforeBonds.contains($0.id) && $0.members.contains(holding.userId) }.map { bond in
                let partner = bond.partner(of: holding.userId)
                let isRecruit = context.after.recommendations.contains {
                    $0.groupId == group.id &&
                    $0.stockId == holding.stockId &&
                    (($0.senderId == partner && $0.receiverId == holding.userId) ||
                     ($0.senderId == holding.userId && $0.receiverId == partner)) &&
                    $0.status == .accepted
                }
                return FeedEvent(
                    groupId: group.id,
                    type: isRecruit ? .kkangbuRecruited : .newKkangbu,
                    actorId: holding.userId,
                    targetUserId: partner,
                    stockId: holding.stockId,
                    holdingId: holding.id,
                    title: isRecruit ? "🎉 깐부 영입 성공" : "🤝 새로운 주식 깐부",
                    message: "\(context.after.nickname(holding.userId)) × \(context.after.nickname(partner))\n\(context.stockName(holding.stockId)) 깐부가 탄생했습니다."
                )
            }
        }
    }
}

struct GradeChangeRule: EventRule {
    let ruleId = "GradeChangeRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        context.after.groups.flatMap { group -> [FeedEvent] in
            let beforePairs = Dictionary(
                uniqueKeysWithValues: KkangbuMath.pairSummaries(in: group.id, state: context.before, prices: context.beforePrices).map { ($0.id, $0) }
            )
            return KkangbuMath.pairSummaries(in: group.id, state: context.after, prices: context.prices).compactMap { pair in
                let previous = beforePairs[pair.id]
                guard previous?.grade.id != pair.grade.id else { return nil }
                let type: EventType
                switch pair.grade.id {
                case KkangbuGradeBook.golden.id: type = .goldenKkangbu
                case KkangbuGradeBook.worst.id: type = .worstPartner
                case KkangbuGradeBook.graveyard.id: type = .graveyardPartners
                case KkangbuGradeBook.destiny.id: type = .destinyPartners
                case KkangbuGradeBook.godsMove.id: type = .godsMovePartners
                default: return nil
                }
                return FeedEvent(
                    groupId: group.id,
                    type: type,
                    actorId: pair.userA,
                    targetUserId: pair.userB,
                    title: "\(pair.grade.emoji) \(pair.grade.title)",
                    message: "\(context.after.nickname(pair.userA))와 \(context.after.nickname(pair.userB))가 \(pair.grade.title)가 되었습니다. 공동 수익률 \(MoneyFormat.percent(pair.averageReturn))"
                )
            }
        }
    }
}

struct SoloEscapeRule: EventRule {
    let ruleId = "SoloEscapeRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case let .holdingSold(holdingId) = context.trigger,
              let sold = context.after.holding(holdingId) else { return [] }

        return context.after.groups(for: sold.userId).compactMap { group -> FeedEvent? in
            let beforeHolders = KkangbuMath.activeHolders(stockId: sold.stockId, groupId: group.id, state: context.before)
            let afterHolders = KkangbuMath.activeHolders(stockId: sold.stockId, groupId: group.id, state: context.after)
            guard beforeHolders.count >= 2, afterHolders.count == beforeHolders.count - 1 else { return nil }
            let leftover = afterHolders.map { context.after.nickname($0.userId) }.joined(separator: ", ")
            return FeedEvent(
                groupId: group.id,
                type: .soloEscape,
                actorId: sold.userId,
                stockId: sold.stockId,
                holdingId: sold.id,
                title: "🏃 혼자 튐",
                message: "\(context.after.nickname(sold.userId))가 \(context.stockName(sold.stockId))를 팔고 혼자 튀었습니다.\n\(leftover)는 아직 남아 있습니다."
            )
        }
    }
}

struct KkangbuBreakupRule: EventRule {
    let ruleId = "KkangbuBreakupRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case .holdingSold = context.trigger else { return [] }
        return context.after.groups.flatMap { group -> [FeedEvent] in
            let beforePairs = Set(KkangbuMath.pairSummaries(in: group.id, state: context.before, prices: context.beforePrices).map(\.id))
            let afterPairs = Set(KkangbuMath.pairSummaries(in: group.id, state: context.after, prices: context.prices).map(\.id))
            let vanished = beforePairs.subtracting(afterPairs)
            let beforeSummaries = KkangbuMath.pairSummaries(in: group.id, state: context.before, prices: context.beforePrices)
            return vanished.compactMap { id in
                guard let pair = beforeSummaries.first(where: { $0.id == id }) else { return nil }
                return FeedEvent(
                    groupId: group.id,
                    type: .kkangbuBreakup,
                    actorId: pair.userA,
                    targetUserId: pair.userB,
                    title: "💔 깐부 결별",
                    message: "\(context.after.nickname(pair.userA))와 \(context.after.nickname(pair.userB))의 공동 보유 종목이 사라져 깐부가 끝났습니다."
                )
            }
        }
    }
}

struct DiamondHandsRule: EventRule {
    let ruleId = "DiamondHandsRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case let .holdingSold(holdingId) = context.trigger,
              let sold = context.after.holding(holdingId) else { return [] }

        return context.after.groups(for: sold.userId).compactMap { group -> FeedEvent? in
            let beforeHolders = KkangbuMath.activeHolders(stockId: sold.stockId, groupId: group.id, state: context.before)
            let afterHolders = KkangbuMath.activeHolders(stockId: sold.stockId, groupId: group.id, state: context.after)
            guard beforeHolders.count >= 2, afterHolders.count == 1,
                  let last = afterHolders.first else { return nil }
            return FeedEvent(
                groupId: group.id,
                type: .diamondHands,
                actorId: last.userId,
                targetUserId: sold.userId,
                stockId: sold.stockId,
                holdingId: last.id,
                title: "💎 끝까지 존버",
                message: "친구들이 \(context.stockName(sold.stockId))에서 다 떠났는데 \(context.after.nickname(last.userId))만 남아 있습니다."
            )
        }
    }
}

struct PostSellMoveRule: EventRule {
    let ruleId = "PostSellMoveRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard context.trigger == .pricesUpdated || {
            if case .holdingSold = context.trigger { return true }
            return false
        }() else { return [] }

        let window = Double(context.after.thresholds.postSellWindowDays * 24 * 3600)
        return context.after.holdings.filter { $0.status == .sold }.flatMap { holding -> [FeedEvent] in
            guard let sellDate = holding.sellDate, context.now.timeIntervalSince(sellDate) <= window,
                  let move = holding.postSellMove(currentPrice: context.prices[holding.stockId] ?? holding.sellPrice ?? holding.averagePrice)
            else { return [] }

            return context.after.groups(for: holding.userId).compactMap { group -> FeedEvent? in
                if move <= -context.after.thresholds.foresightDrop,
                   !holding.firedEventKeys.contains("FORESIGHT-\(group.id)") {
                    return FeedEvent(
                        groupId: group.id,
                        type: .foresight,
                        actorId: holding.userId,
                        stockId: holding.stockId,
                        holdingId: holding.id,
                        title: "🧠 선견지명",
                        message: "\(context.after.nickname(holding.userId))의 선견지명!\n\(context.stockName(holding.stockId)) 매도 후 \(MoneyFormat.percent(move))",
                        metadata: ["key": "FORESIGHT-\(group.id)", "holdingId": holding.id.uuidString]
                    )
                }
                if move >= context.after.thresholds.soldTooEarlyRise,
                   !holding.firedEventKeys.contains("SOLD_TOO_EARLY-\(group.id)") {
                    return FeedEvent(
                        groupId: group.id,
                        type: .soldTooEarly,
                        actorId: holding.userId,
                        stockId: holding.stockId,
                        holdingId: holding.id,
                        title: "🤡 너무 일찍 튐",
                        message: "\(context.after.nickname(holding.userId))야 조금만 더 기다리지...\n매도 후 \(context.stockName(holding.stockId)) \(MoneyFormat.percent(move))",
                        metadata: ["key": "SOLD_TOO_EARLY-\(group.id)", "holdingId": holding.id.uuidString]
                    )
                }
                return nil
            }
        }
    }
}

struct TogetherMoveRule: EventRule {
    let ruleId = "TogetherMoveRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard context.trigger == .pricesUpdated else { return [] }
        return context.after.groups.flatMap { group -> [FeedEvent] in
            KkangbuMath.bonds(in: group.id, state: context.after, prices: context.prices).compactMap { bond in
                if bond.sharedReturn >= context.after.thresholds.moonTogetherReturn,
                   !alreadyFired("MOON-\(bond.id)", in: context.after) {
                    return FeedEvent(
                        groupId: group.id,
                        type: .moonTogether,
                        actorId: bond.userA,
                        targetUserId: bond.userB,
                        stockId: bond.stockId,
                        title: "🚀 같이 떡상",
                        message: "\(context.after.nickname(bond.userA))와 \(context.after.nickname(bond.userB))의 \(context.stockName(bond.stockId))가 \(MoneyFormat.percent(bond.sharedReturn))!",
                        metadata: ["key": "MOON-\(bond.id)"]
                    )
                }
                if bond.sharedReturn <= context.after.thresholds.graveyardReturn,
                   !alreadyFired("BURIED-\(bond.id)", in: context.after) {
                    return FeedEvent(
                        groupId: group.id,
                        type: .buriedTogether,
                        actorId: bond.userA,
                        targetUserId: bond.userB,
                        stockId: bond.stockId,
                        title: "🪦 같이 묻힘",
                        message: "\(context.after.nickname(bond.userA))와 \(context.after.nickname(bond.userB))가 \(context.stockName(bond.stockId))에서 함께 묻혔습니다. \(MoneyFormat.percent(bond.sharedReturn))",
                        metadata: ["key": "BURIED-\(bond.id)"]
                    )
                }
                return nil
            }
        }
    }
}

struct RecordMoveRule: EventRule {
    let ruleId = "RecordMoveRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard context.trigger == .pricesUpdated else { return [] }
        return context.after.groups.flatMap { group -> [FeedEvent] in
            let memberIds = Set(context.after.members(of: group.id).map(\.userId))
            return context.after.holdings.compactMap { holding -> FeedEvent? in
                guard holding.status == .holding, memberIds.contains(holding.userId) else { return nil }
                let value = holding.returnRate(currentPrice: context.prices[holding.stockId] ?? holding.averagePrice)
                if value >= context.after.thresholds.recordMove,
                   !holding.firedEventKeys.contains("HIGH-\(group.id)") {
                    return FeedEvent(
                        groupId: group.id,
                        type: .recordHigh,
                        actorId: holding.userId,
                        stockId: holding.stockId,
                        holdingId: holding.id,
                        title: "🏆 기록 갱신",
                        message: "\(context.after.nickname(holding.userId))의 \(context.stockName(holding.stockId))가 \(MoneyFormat.percent(value))까지 갔습니다.",
                        metadata: ["key": "HIGH-\(group.id)", "holdingId": holding.id.uuidString]
                    )
                }
                if value <= -context.after.thresholds.recordMove,
                   !holding.firedEventKeys.contains("LOW-\(group.id)") {
                    return FeedEvent(
                        groupId: group.id,
                        type: .recordLow,
                        actorId: holding.userId,
                        stockId: holding.stockId,
                        holdingId: holding.id,
                        title: "📉 최악의 한 수",
                        message: "\(context.after.nickname(holding.userId))의 \(context.stockName(holding.stockId))가 \(MoneyFormat.percent(value)). 이번 주 흑역사 후보입니다.",
                        metadata: ["key": "LOW-\(group.id)", "holdingId": holding.id.uuidString]
                    )
                }
                return nil
            }
        }
    }
}

struct RankChangeRule: EventRule {
    let ruleId = "RankChangeRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard context.trigger == .pricesUpdated else { return [] }
        return context.after.groups.compactMap { group -> FeedEvent? in
            let beforeBoard = RankingService.board(groupId: group.id, state: context.before, prices: context.beforePrices)
            let afterBoard = RankingService.board(groupId: group.id, state: context.after, prices: context.prices)
            let beforeLead = beforeBoard.weeklyReturns.first?.userId
            let afterLead = afterBoard.weeklyReturns.first?.userId
            guard beforeLead != afterLead, let afterLead else { return nil }
            return FeedEvent(
                groupId: group.id,
                type: .groupRankChanged,
                actorId: afterLead,
                title: "👑 이번 주 1위가 바뀌었습니다",
                message: "\(context.after.nickname(afterLead))가 이번 주 분위기 1위입니다."
            )
        }
    }
}

private func alreadyFired(_ key: String, in state: AppState) -> Bool {
    state.events.contains { $0.metadata["key"] == key }
}
