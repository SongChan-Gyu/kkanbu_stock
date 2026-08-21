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
                    title: "추천",
                    message: "\(context.after.nickname(rec.senderId))가 \(context.after.nickname(rec.receiverId))에게 \(context.stockName(rec.stockId))를 추천했습니다.\n“\(rec.message)”"
                )
            ]
        case let .recommendationResolved(id):
            guard let rec = context.after.recommendations.first(where: { $0.id == id }) else { return [] }
            if rec.status == .willBuy {
                return [
                    FeedEvent(
                        groupId: rec.groupId,
                        type: .recommendWillBuy,
                        actorId: rec.receiverId,
                        targetUserId: rec.senderId,
                        stockId: rec.stockId,
                        title: "매수 예정",
                        message: "\(context.after.nickname(rec.receiverId))가 \(context.stockName(rec.stockId)) 매수 예정으로 남겼습니다."
                    )
                ]
            }
            if rec.status == .accepted {
                return [
                    FeedEvent(
                        groupId: rec.groupId,
                        type: .recommendAccepted,
                        actorId: rec.receiverId,
                        targetUserId: rec.senderId,
                        stockId: rec.stockId,
                        title: "매수 기록",
                        message: "\(context.after.nickname(rec.receiverId))가 \(context.stockName(rec.stockId))를 사서 기록했습니다."
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
                        title: "거절",
                        message: "\(context.after.nickname(rec.receiverId))가 \(context.stockName(rec.stockId)) 추천을 거절했습니다."
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
        switch context.trigger {
        case let .proposalCreated(id):
            guard let proposal = context.after.proposals.first(where: { $0.id == id }) else { return [] }
            return [
                FeedEvent(
                    groupId: proposal.groupId,
                    type: .proposalCreated,
                    actorId: proposal.proposerId,
                    stockId: proposal.stockId,
                    title: "매수 제안",
                    message: "\(context.after.nickname(proposal.proposerId))가 \(context.stockName(proposal.stockId)) 매수를 제안했습니다.\n“\(proposal.message)”"
                )
            ]
        case let .proposalDeclined(id):
            guard let proposal = context.after.proposals.first(where: { $0.id == id }) else { return [] }
            return [
                FeedEvent(
                    groupId: proposal.groupId,
                    type: .recommendRejected,
                    actorId: context.after.currentUserId,
                    targetUserId: proposal.proposerId,
                    stockId: proposal.stockId,
                    title: "제안 거절",
                    message: "\(context.after.nickname(context.after.currentUserId))가 \(context.stockName(proposal.stockId)) 매수 제안을 거절했습니다."
                )
            ]
        default:
            return []
        }
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
                    title: "관심",
                    message: "\(context.after.nickname(cobuy.userId))가 \(context.stockName(cobuy.stockId)) 매수 제안에 관심을 남겼습니다. 현재 \(promised)명."
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
                    title: "매수 기록",
                    message: "\(context.after.nickname(cobuy.userId))가 \(context.stockName(cobuy.stockId))를 기록했습니다."
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
        guard case let .nagged(proposalId, actorId, targetUserId, count) = context.trigger,
              let proposal = context.after.proposals.first(where: { $0.id == proposalId }) else { return [] }
        let targetName = targetUserId.map { context.after.nickname($0) }
        let message: String
        if let targetName {
            message = "\(context.after.nickname(actorId))가 \(targetName)에게 \(context.stockName(proposal.stockId)) 매수를 \(count)번째로 다시 제안했습니다."
        } else {
            message = "\(context.after.nickname(actorId))가 \(context.stockName(proposal.stockId)) 매수를 \(count)번째로 다시 제안했습니다."
        }
        return [
            FeedEvent(
                groupId: proposal.groupId,
                type: .persistentNagging,
                actorId: actorId,
                targetUserId: targetUserId,
                stockId: proposal.stockId,
                title: "매수 제안 · 재요청",
                message: message
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
                    title: "구라핑 의심",
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
                title = "의혹 해명"
                message = "\(context.after.nickname(holding.userId))가 캡처 인증으로 구라핑 의혹을 깔끔하게 해명했습니다."
            case .screenshotVerified:
                title = "매수가 인증"
                message = "\(context.after.nickname(holding.userId))가 \(context.stockName(holding.stockId)) 매수가를 인증했습니다."
            default:
                title = "정보 불일치"
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
                    title: "평단 수정",
                    message: "\(context.after.nickname(holding.userId))가 \(context.stockName(holding.stockId)) 평단을 \(MoneyFormat.price(holding.averagePrice, market: context.after.stock(holding.stockId)?.market ?? .nasdaq))로 고쳤습니다."
                )
            }
        default:
            return []
        }
    }
}

struct CommentRule: EventRule {
    let ruleId = "CommentRule"

    func evaluate(context: EventContext) -> [FeedEvent] {
        guard case let .commentPosted(id) = context.trigger,
              let comment = context.after.comments.first(where: { $0.id == id }) else { return [] }
        let clipped = comment.body.count > 40 ? String(comment.body.prefix(40)) + "…" : comment.body
        let isReply = comment.parentId != nil
        return [
            FeedEvent(
                groupId: comment.groupId,
                type: .commentPosted,
                actorId: comment.authorId,
                stockId: comment.stockId,
                title: isReply ? "대댓글" : "댓글",
                message: "\(context.after.nickname(comment.authorId))가 \(context.stockName(comment.stockId)) 추천에 \(isReply ? "답글" : "댓글")을 남겼습니다. “\(clipped)”"
            )
        ]
    }
}
