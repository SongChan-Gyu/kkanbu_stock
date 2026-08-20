import Foundation

struct RecommendRule: EventRule {
    let ruleId = "RecommendRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        switch context.trigger {
        case let .recommendationSent(id):
            guard let rec = context.after.recommendations.first(where: { $0.id == id }) else { return [] }
            return [
                FeedEvent(
                    groupId: rec.groupId,
                    type: .recommendStock,
                    actorId: rec.senderId,
                    targetUserId: rec.receiverId,
                    stockId: rec.stockId,
                    title: "📣 너도 사!",
                    message: "\(context.after.nickname(rec.senderId))가 \(context.after.nickname(rec.receiverId))에게 \(context.stockName(rec.stockId))를 추천했습니다.\n“\(rec.message)”"
                )
            ]
        case let .recommendationResolved(id):
            guard let rec = context.after.recommendations.first(where: { $0.id == id }) else { return [] }
            if rec.status == .accepted {
                return [
                    FeedEvent(
                        groupId: rec.groupId,
                        type: .recommendAccepted,
                        actorId: rec.receiverId,
                        targetUserId: rec.senderId,
                        stockId: rec.stockId,
                        title: "🎉 추천 수락",
                        message: "\(context.after.nickname(rec.receiverId))가 \(context.stockName(rec.stockId)) 추천을 받았습니다. 주식 흑역사에 한 줄 추가될지도..."
                    )
                ]
            }
            if rec.status == .rejected || rec.status == .later {
                return [
                    FeedEvent(
                        groupId: rec.groupId,
                        type: .recommendRejected,
                        actorId: rec.receiverId,
                        targetUserId: rec.senderId,
                        stockId: rec.stockId,
                        title: "📭 제안 거절",
                        message: "\(context.after.nickname(rec.receiverId))가 \(context.stockName(rec.stockId))를 일단 패스했습니다. 나중에 재미있는 흑역사가 될 수 있어요."
                    )
                ]
            }
            return []
        default:
            return []
        }
    }
}

struct ProposalRule: EventRule {
    let ruleId = "ProposalRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case let .proposalCreated(id) = context.trigger,
              let proposal = context.after.proposals.first(where: { $0.id == id }) else { return [] }
        return [
            FeedEvent(
                groupId: proposal.groupId,
                type: .proposalCreated,
                actorId: proposal.proposerId,
                stockId: proposal.stockId,
                title: "🤔 이거 어때?",
                message: "\(context.after.nickname(proposal.proposerId))가 \(context.stockName(proposal.stockId)) 같이 사자고 제안했습니다.\n“\(proposal.message)”"
            )
        ]
    }
}

struct CoBuyRule: EventRule {
    let ruleId = "CoBuyRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        switch context.trigger {
        case let .coBuyPromised(id):
            guard let cobuy = context.after.coBuys.first(where: { $0.id == id }) else { return [] }
            let promised = context.after.coBuys.filter { $0.proposalId == cobuy.proposalId && $0.status != .declined }.count
            return [
                FeedEvent(
                    groupId: cobuy.groupId,
                    type: .coBuyAccepted,
                    actorId: cobuy.userId,
                    stockId: cobuy.stockId,
                    title: "🤝 같이 사기 약속",
                    message: "\(context.after.nickname(cobuy.userId))가 \(context.stockName(cobuy.stockId)) 같이 사기에 손을 올렸습니다. 현재 \(promised)명."
                )
            ]
        case let .coBuyCompleted(id):
            guard let cobuy = context.after.coBuys.first(where: { $0.id == id }) else { return [] }
            return [
                FeedEvent(
                    groupId: cobuy.groupId,
                    type: .coBuyCompleted,
                    actorId: cobuy.userId,
                    stockId: cobuy.stockId,
                    title: "🎉 같이 사기 성공",
                    message: "\(context.after.nickname(cobuy.userId))가 \(context.stockName(cobuy.stockId))를 실제로 등록했습니다. 약속이 깐부가 되는 순간."
                )
            ]
        default:
            return []
        }
    }
}

struct NagRule: EventRule {
    let ruleId = "NagRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case let .nagged(proposalId, actorId, count) = context.trigger,
              let proposal = context.after.proposals.first(where: { $0.id == proposalId }) else { return [] }
        return [
            FeedEvent(
                groupId: proposal.groupId,
                type: .persistentNagging,
                actorId: actorId,
                stockId: proposal.stockId,
                title: "😂 같이 사자고 조르기",
                message: "\(context.after.nickname(actorId))가 \(context.stockName(proposal.stockId))를 \(count)번째로 같이 사자고 조르고 있습니다."
            )
        ]
    }
}

struct VerificationRule: EventRule {
    let ruleId = "VerificationRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        switch context.trigger {
        case let .suspected(holdingId, actorId):
            guard let holding = context.after.holding(holdingId) else { return [] }
            return context.after.groups(for: holding.userId).map { group in
                FeedEvent(
                    groupId: group.id,
                    type: .verificationRequested,
                    actorId: actorId,
                    targetUserId: holding.userId,
                    stockId: holding.stockId,
                    holdingId: holding.id,
                    title: "🕵️ 구라핑 의혹",
                    message: "친구들이 \(context.after.nickname(holding.userId))의 \(context.stockName(holding.stockId)) 매수가를 의심하고 있습니다. “진짜 \(MoneyFormat.price(holding.averagePrice, market: context.after.stock(holding.stockId)?.market ?? .nasdaq))에 산 거 맞아?”"
                )
            }
        case let .verified(holdingId, matched):
            guard let holding = context.after.holding(holdingId) else { return [] }
            let type: EventType = matched ? (holding.suspicionCount > 0 ? .verificationSuccess : .screenshotVerified) : .verificationMismatch
            let title: String
            let message: String
            switch type {
            case .verificationSuccess:
                title = "😎 의혹 해명"
                message = "\(context.after.nickname(holding.userId))가 캡처 인증으로 구라핑 의혹을 깔끔하게 해명했습니다."
            case .screenshotVerified:
                title = "📸 매수가 인증 완료"
                message = "\(context.after.nickname(holding.userId))가 \(context.stockName(holding.stockId)) 매수가를 인증했습니다."
            default:
                title = "🚨 정보 불일치"
                message = "\(context.after.nickname(holding.userId))의 입력 정보와 캡처 정보가 다릅니다. 사기라고 단정하지 않고, 확인이 필요하다는 뜻이에요."
            }
            return context.after.groups(for: holding.userId).map { group in
                FeedEvent(
                    groupId: group.id,
                    type: type,
                    actorId: holding.userId,
                    stockId: holding.stockId,
                    holdingId: holding.id,
                    title: title,
                    message: message
                )
            }
        case let .priceEdited(holdingId):
            guard let holding = context.after.holding(holdingId) else { return [] }
            return context.after.groups(for: holding.userId).map { group in
                FeedEvent(
                    groupId: group.id,
                    type: .holdingPriceUpdated,
                    actorId: holding.userId,
                    stockId: holding.stockId,
                    holdingId: holding.id,
                    title: "😂 매수가 수정됨",
                    message: "\(context.after.nickname(holding.userId))가 \(context.stockName(holding.stockId)) 매수가를 \(MoneyFormat.price(holding.averagePrice, market: context.after.stock(holding.stockId)?.market ?? .nasdaq))로 고쳤습니다."
                )
            }
        default:
            return []
        }
    }
}
