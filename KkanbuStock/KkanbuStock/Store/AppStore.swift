import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
final class AppStore {
    var state: AppState
    var lastError: String?
    var toast: String?

    let priceService: StockPriceServing
    let parser: StockScreenshotAnalyzing
    let verificationService: VerificationService
    let notifications: InAppNotificationPort

    private var engine: EventEngine
    private let persistence: PersistenceStore
    private var saveTask: Task<Void, Never>?

    init(
        state: AppState? = nil,
        priceService: StockPriceServing = MockStockPriceService(),
        parser: StockScreenshotAnalyzing = StockTextParser(),
        verificationService: VerificationService = VerificationService(),
        notifications: InAppNotificationPort = InAppNotificationPort(),
        engine: EventEngine = EventEngine(),
        persistence: PersistenceStore = PersistenceStore()
    ) {
        self.priceService = priceService
        self.parser = parser
        self.verificationService = verificationService
        self.notifications = notifications
        self.engine = engine
        self.persistence = persistence
        if let state {
            self.state = state
        } else if let loaded = persistence.load() {
            self.state = loaded
        } else {
            let me = User(nickname: "나", avatarEmoji: "🐣")
            self.state = .empty(user: me, stocks: StockCatalog.all)
        }
    }

    var currentPrices: [UUID: Double] {
        prices(for: state)
    }

    func prices(for snapshot: AppState) -> [UUID: Double] {
        Dictionary(uniqueKeysWithValues: snapshot.stocks.map { stock in
            let offset = snapshot.livePriceOffsets[stock.id] ?? 0
            return (stock.id, priceService.currentPrice(for: stock, offset: offset))
        })
    }

    func price(for stockId: UUID) -> Double {
        currentPrices[stockId] ?? 0
    }

    func history(for stock: Stock, days: Int = 90) -> [PricePoint] {
        priceService.historicalPrices(for: stock, days: days, now: Date())
    }

    func searchStocks(_ query: String) -> [Stock] {
        priceService.searchStocks(query, in: state.stocks)
    }

    func completeOnboarding(nickname: String, emoji: String, useDemo: Bool) {
        var me = state.currentUser
        me.nickname = nickname
        me.avatarEmoji = emoji
        replaceUser(me)
        state.hasCompletedOnboarding = true
        state.disclaimerAcknowledged = true
        if useDemo {
            DemoSeeder.seed(into: &state, currentUser: me)
            refreshDerived()
        }
        persist()
        LocalPush.requestPermission()
    }

    func acknowledgeDisclaimer() {
        state.disclaimerAcknowledged = true
        persist()
    }

    func createGroup(name: String) {
        let group = Group(name: name, inviteCode: InviteCode.make(), ownerId: state.currentUserId)
        let before = state
        state.groups.append(group)
        state.members.append(GroupMember(groupId: group.id, userId: state.currentUserId))
        state.selectedGroupId = group.id
        emit(.memberJoined(userId: state.currentUserId, groupId: group.id), before: before)
    }

    func joinGroup(code: String) -> Bool {
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let group = state.groups.first(where: { $0.inviteCode == cleaned }) else {
            lastError = "초대 코드를 찾을 수 없어요."
            return false
        }
        guard !state.members.contains(where: { $0.groupId == group.id && $0.userId == state.currentUserId }) else {
            state.selectedGroupId = group.id
            return true
        }
        let before = state
        state.members.append(GroupMember(groupId: group.id, userId: state.currentUserId))
        state.selectedGroupId = group.id
        emit(.memberJoined(userId: state.currentUserId, groupId: group.id), before: before)
        return true
    }

    func selectGroup(_ id: UUID) {
        state.selectedGroupId = id
        persist()
    }

    func addHolding(
        stock: Stock,
        averagePrice: Double,
        quantity: Double?,
        purchaseDate: Date?,
        method: InputMethod,
        verification: VerificationState
    ) {
        if let existing = state.activeHoldings(of: state.currentUserId).first(where: { $0.stockId == stock.id }) {
            lastError = "이미 \(stock.name)를 보유 중이에요. 매수가를 수정하거나 매도 후 다시 등록해 주세요."
            return
        }
        let holding = Holding(
            userId: state.currentUserId,
            stockId: stock.id,
            averagePrice: averagePrice,
            quantity: quantity,
            purchaseDate: purchaseDate,
            inputMethod: method,
            verificationState: verification
        )
        let before = state
        state.holdings.append(holding)
        var acceptedRecIds: [UUID] = []
        for index in state.recommendations.indices where
            state.recommendations[index].receiverId == state.currentUserId &&
            state.recommendations[index].stockId == stock.id &&
            (state.recommendations[index].status == .pending || state.recommendations[index].status == .willBuy)
        {
            state.recommendations[index].status = .accepted
            state.recommendations[index].resolvedAt = Date()
            acceptedRecIds.append(state.recommendations[index].id)
        }
        let cobuyTriggers = completeCoBuysIfNeeded(userId: state.currentUserId, stockId: stock.id)
        var triggers: [Trigger] = [.holdingAdded(holdingId: holding.id)]
        triggers.append(contentsOf: acceptedRecIds.map { .recommendationResolved(id: $0) })
        if verification == .screenshotVerified {
            triggers.append(.verified(holdingId: holding.id, matched: true))
        }
        triggers.append(contentsOf: cobuyTriggers)
        emit(triggers, before: before)
        toast = acceptedRecIds.isEmpty ? "\(stock.name) 등록 완료" : "\(stock.name)를 사서 기록했습니다"
    }

    func sellHolding(id: UUID, sellPrice: Double, sellDate: Date) {
        guard let index = state.holdings.firstIndex(where: { $0.id == id }) else { return }
        let before = state
        state.holdings[index].status = .sold
        state.holdings[index].sellPrice = sellPrice
        state.holdings[index].sellDate = sellDate
        state.holdings[index].updatedAt = Date()
        emit(.holdingSold(holdingId: id), before: before)
        toast = "매도 처리됨"
    }

    func updateHoldingPrice(id: UUID, price: Double) {
        guard let index = state.holdings.firstIndex(where: { $0.id == id }) else { return }
        let before = state
        state.holdings[index].averagePrice = price
        state.holdings[index].updatedAt = Date()
        if state.holdings[index].verificationState == .mismatch {
            state.holdings[index].verificationState = .unverified
        }
        emit(.priceEdited(holdingId: id), before: before)
    }

    func recommend(holding: Holding, to userId: UUID, message: String) {
        guard let groupId = state.selectedGroupId else { return }
        let rec = StockRecommendation(
            groupId: groupId,
            senderId: state.currentUserId,
            receiverId: userId,
            stockId: holding.stockId,
            holdingId: holding.id,
            message: message
        )
        let before = state
        state.recommendations.append(rec)
        emit(.recommendationSent(id: rec.id), before: before)
        toast = "추천을 보냈습니다"
    }

    func resolveRecommendation(_ id: UUID, accept: Bool, averagePrice: Double? = nil, purchaseDate: Date? = nil) {
        guard let index = state.recommendations.firstIndex(where: { $0.id == id }) else { return }
        let rec = state.recommendations[index]
        let before = state
        if accept, averagePrice == nil {
            state.recommendations[index].status = .willBuy
            state.recommendations[index].resolvedAt = nil
            emit(.recommendationResolved(id: rec.id), before: before)
            toast = "살게요. 사면 매수가를 적으세요."
            return
        }
        state.recommendations[index].status = accept ? .accepted : .rejected
        state.recommendations[index].resolvedAt = Date()
        var triggers: [Trigger] = [.recommendationResolved(id: rec.id)]
        if accept, let averagePrice, let stock = state.stock(rec.stockId) {
            if state.activeHoldings(of: state.currentUserId).contains(where: { $0.stockId == stock.id }) == false {
                let holding = Holding(
                    userId: state.currentUserId,
                    stockId: stock.id,
                    averagePrice: averagePrice,
                    purchaseDate: purchaseDate ?? Date(),
                    inputMethod: .manual,
                    verificationState: .unverified
                )
                state.holdings.append(holding)
                triggers.append(.holdingAdded(holdingId: holding.id))
                triggers.append(contentsOf: completeCoBuysIfNeeded(userId: state.currentUserId, stockId: stock.id))
            }
        }
        emit(triggers, before: before)
        toast = accept ? "사서 기록했습니다" : "안 사기로 했습니다"
    }

    func propose(stock: Stock, message: String) {
        guard let groupId = state.selectedGroupId else { return }
        let proposal = StockProposal(groupId: groupId, proposerId: state.currentUserId, stockId: stock.id, message: message)
        let mine = CoBuyRequest(proposalId: proposal.id, groupId: groupId, userId: state.currentUserId, stockId: stock.id, status: .promised)
        let before = state
        state.proposals.append(proposal)
        state.coBuys.append(mine)
        emit([.proposalCreated(id: proposal.id), .coBuyPromised(id: mine.id)], before: before)
        toast = "그룹에 같이 사자고 제안했습니다"
    }

    func promiseCoBuy(proposalId: UUID) {
        guard let proposal = state.proposals.first(where: { $0.id == proposalId }) else { return }
        let before = state
        if let existing = state.coBuys.first(where: { $0.proposalId == proposalId && $0.userId == state.currentUserId }) {
            if existing.status == .promised { return }
            if let index = state.coBuys.firstIndex(where: { $0.id == existing.id }) {
                state.coBuys[index].status = .promised
                emit(.coBuyPromised(id: existing.id), before: before)
                toast = "관심만 남겼습니다. 그룹 제안이지 매수가 아닙니다."
            }
            return
        }
        let cobuy = CoBuyRequest(proposalId: proposalId, groupId: proposal.groupId, userId: state.currentUserId, stockId: proposal.stockId)
        state.coBuys.append(cobuy)
        emit(.coBuyPromised(id: cobuy.id), before: before)
        toast = "관심만 남겼습니다. 그룹 제안이지 매수가 아닙니다."
    }

    func declineProposal(_ proposalId: UUID) {
        guard let proposal = state.proposals.first(where: { $0.id == proposalId }) else { return }
        let before = state
        if let index = state.coBuys.firstIndex(where: { $0.proposalId == proposalId && $0.userId == state.currentUserId }) {
            state.coBuys[index].status = .declined
        } else {
            state.coBuys.append(
                CoBuyRequest(
                    proposalId: proposalId,
                    groupId: proposal.groupId,
                    userId: state.currentUserId,
                    stockId: proposal.stockId,
                    status: .declined
                )
            )
        }
        emit(.proposalDeclined(id: proposalId), before: before)
        toast = "패스했습니다"
    }

    func nag(proposalId: UUID) {
        guard let proposal = state.proposals.first(where: { $0.id == proposalId }) else { return }
        guard proposal.proposerId == state.currentUserId else { return }
        let mine = state.coBuys.first(where: { $0.proposalId == proposalId && $0.userId == state.currentUserId })
        let count = (mine?.nagCount ?? 0) + 1
        if let last = mine?.lastNagAt, Date().timeIntervalSince(last) < SocialLimits.nagCooldown {
            lastError = "조금 뒤에 다시 조를 수 있어요."
            return
        }
        if count > SocialLimits.maxNagsPerProposal {
            lastError = "조르기는 제안당 3번까지예요."
            return
        }
        let before = state
        if let index = state.coBuys.firstIndex(where: { $0.proposalId == proposalId && $0.userId == state.currentUserId }) {
            state.coBuys[index].nagCount = count
            state.coBuys[index].lastNagAt = Date()
        }
        let responded = Set(state.coBuys.filter { $0.proposalId == proposalId }.map(\.userId))
        let holdouts = state.members(of: proposal.groupId).map(\.userId).filter { !responded.contains($0) && $0 != state.currentUserId }
        let targets = holdouts.isEmpty ? [nil] : holdouts.map(Optional.some)
        emit(targets.map { .nagged(proposalId: proposalId, actorId: state.currentUserId, targetUserId: $0, count: count) }, before: before)
        toast = "같이 사자고 한 번 더 찔렀어요"
    }

    func suspectHolding(_ holdingId: UUID) {
        guard let groupId = state.selectedGroupId, let holding = state.holding(holdingId) else { return }
        guard holding.userId != state.currentUserId else { return }
        if let last = state.suspicions.last(where: { $0.holdingId == holdingId && $0.actorId == state.currentUserId }),
           Date().timeIntervalSince(last.createdAt) < SocialLimits.suspicionCooldown {
            lastError = "이미 의심을 남겼어요. 친구가 인증할 시간을 줍시다."
            return
        }
        let before = state
        state.suspicions.append(
            GurapingSuspicion(groupId: groupId, holdingId: holdingId, actorId: state.currentUserId, targetUserId: holding.userId)
        )
        if let index = state.holdings.firstIndex(where: { $0.id == holdingId }) {
            state.holdings[index].suspicionCount += 1
            if state.holdings[index].verificationState == .unverified {
                state.holdings[index].verificationState = .suspected
            }
        }
        emit(.suspected(holdingId: holdingId, actorId: state.currentUserId), before: before)
        toast = "구라핑 의심을 남겼어요. 단정은 하지 않아요."
    }

    func applyScreenshotVerification(holdingId: UUID, analysis: ScreenshotAnalysisResult) {
        guard let holding = state.holding(holdingId), let stock = state.stock(holding.stockId) else { return }
        let outcome = verificationService.verify(holding: holding, analysis: analysis, stock: stock)
        guard analysis.confidence >= 0.4, outcome.stockMatched else {
            lastError = "캡처에서 종목을 충분히 확신하지 못했어요. 다시 찍거나 직접 확인해 주세요."
            return
        }
        let before = state
        if outcome.matched {
            if let index = state.holdings.firstIndex(where: { $0.id == holdingId }) {
                state.holdings[index].verificationState = .screenshotVerified
                state.holdings[index].inputMethod = .screenshot
            }
            emit(.verified(holdingId: holdingId, matched: true), before: before)
            toast = "캡처 인증 완료"
        } else {
            if let index = state.holdings.firstIndex(where: { $0.id == holdingId }) {
                state.holdings[index].verificationState = .mismatch
            }
            emit(.verified(holdingId: holdingId, matched: false), before: before)
            lastError = "입력한 매수가와 캡처 정보가 달라요. 사기라고 단정하지 않고, 확인이 필요하다는 뜻입니다."
        }
    }

    func tickMarket(delta: Double? = nil) {
        let before = state
        for stock in state.stocks {
            let jitter = delta ?? Double.random(in: -0.012...0.012)
            let current = state.livePriceOffsets[stock.id] ?? 0
            state.livePriceOffsets[stock.id] = max(-0.45, min(0.8, current + jitter))
        }
        emit(.pricesUpdated, before: before)
    }

    func shock(stockId: UUID, percent: Double) {
        let before = state
        let current = state.livePriceOffsets[stockId] ?? 0
        state.livePriceOffsets[stockId] = current + percent
        emit(.pricesUpdated, before: before)
        toast = "시장이 흔들렸습니다"
    }

    func resetDemo() {
        persistence.reset()
        let me = state.currentUser
        state = .empty(user: me, stocks: StockCatalog.all)
        state.hasCompletedOnboarding = true
        state.disclaimerAcknowledged = true
        DemoSeeder.seed(into: &state, currentUser: me)
        refreshDerived()
        persist()
    }

    func updatePrivacy(shareQuantity: Bool, shareAmount: Bool) {
        var me = state.currentUser
        me.shareQuantity = shareQuantity
        me.shareInvestedAmount = shareAmount
        replaceUser(me)
        persist()
    }

    func analyzeText(_ text: String) -> ScreenshotAnalysisResult {
        parser.analyze(text: text, catalog: state.stocks, now: Date())
    }

    func recommendToGroup(holding: Holding, message: String) {
        guard let groupId = state.selectedGroupId else { return }
        let friends = state.members(of: groupId).map(\.userId).filter { $0 != state.currentUserId }
        let before = state
        var triggers: [Trigger] = []
        for friend in friends {
            let rec = StockRecommendation(
                groupId: groupId,
                senderId: state.currentUserId,
                receiverId: friend,
                stockId: holding.stockId,
                holdingId: holding.id,
                message: message
            )
            state.recommendations.append(rec)
            triggers.append(.recommendationSent(id: rec.id))
        }
        emit(triggers, before: before)
        toast = "그룹에 추천을 보냈습니다"
    }

    func copyInviteCode(_ code: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = code
        #endif
        toast = "초대 코드 \(code) 복사됨"
    }

    func refreshDerived() {
        syncRelationships()
        persist()
    }

    func playAs(_ userId: UUID) {
        guard state.users.contains(where: { $0.id == userId }) else { return }
        state.currentUserId = userId
        persist()
        toast = "\(state.nickname(userId))로 플레이 중. 친구 테스트용이에요."
    }

    func updateThresholds(_ thresholds: EventThresholds) {
        state.thresholds = thresholds
        persist()
    }

    func inboxItems(for userId: UUID) -> [InboxItem] {
        let recs = state.recommendations.filter {
            $0.receiverId == userId && ($0.status == .pending || $0.status == .willBuy)
        }.map {
            InboxItem(id: $0.id, kind: .recommend, date: $0.createdAt, recommendation: $0, proposal: nil, holding: nil)
        }
        let proposals = state.proposals.filter { proposal in
            proposal.proposerId != userId &&
            proposal.status == .open &&
            !state.coBuys.contains { $0.proposalId == proposal.id && $0.userId == userId } &&
            !state.events.contains { $0.type == .persistentNagging && $0.targetUserId == userId && $0.stockId == proposal.stockId }
        }.map {
            InboxItem(id: $0.id, kind: .proposal, date: $0.createdAt, recommendation: nil, proposal: $0, holding: nil)
        }
        let nags = state.events.filter {
            $0.type == .persistentNagging && $0.targetUserId == userId
        }.prefix(8).map { event in
            let proposal = state.proposals.first { $0.stockId == event.stockId && $0.groupId == event.groupId && $0.status == .open }
            return InboxItem(id: event.id, kind: .nag, date: event.createdAt, recommendation: nil, proposal: proposal, holding: nil)
        }
        let suspects = state.holdings.filter { $0.userId == userId && ($0.verificationState == .suspected || $0.verificationState == .mismatch) }.map {
            InboxItem(id: $0.id, kind: .suspect, date: $0.updatedAt, recommendation: nil, proposal: nil, holding: $0)
        }
        return (recs + proposals + Array(nags) + suspects).sorted { $0.date > $1.date }
    }

    private func completeCoBuysIfNeeded(userId: UUID, stockId: UUID) -> [Trigger] {
        var triggers: [Trigger] = []
        for index in state.coBuys.indices where state.coBuys[index].userId == userId && state.coBuys[index].stockId == stockId && state.coBuys[index].status == .promised {
            state.coBuys[index].status = .completed
            state.coBuys[index].completedAt = Date()
            triggers.append(.coBuyCompleted(id: state.coBuys[index].id))
        }
        for index in state.proposals.indices {
            let proposal = state.proposals[index]
            if proposal.stockId == stockId {
                let related = state.coBuys.filter { $0.proposalId == proposal.id }
                let promised = related.filter { $0.status == .promised }
                let completed = related.filter { $0.status == .completed }
                if !completed.isEmpty && promised.isEmpty {
                    state.proposals[index].status = .completed
                }
            }
        }
        return triggers
    }

    private func replaceUser(_ user: User) {
        if let index = state.users.firstIndex(where: { $0.id == user.id }) {
            state.users[index] = user
        } else {
            state.users.append(user)
        }
    }

    private func emit(_ trigger: Trigger, before: AppState) {
        emit([trigger], before: before)
    }

    private func emit(_ triggers: [Trigger], before: AppState) {
        for trigger in triggers {
            let context = EventContext(
                trigger: trigger,
                before: before,
                after: state,
                now: Date(),
                prices: prices(for: state),
                beforePrices: prices(for: before)
            )
            let events = engine.evaluate(context: context)
            for event in events {
                if state.events.contains(where: { $0.type == event.type && $0.actorId == event.actorId && $0.targetUserId == event.targetUserId && $0.stockId == event.stockId && $0.message == event.message && abs($0.createdAt.timeIntervalSince(event.createdAt)) < 1 }) {
                    continue
                }
                state.events.insert(event, at: 0)
                stampFiredKeys(event)
                maybeAwardBadge(event)
                notifications.deliver(PushPayload(title: event.title, body: event.message, eventType: event.type, groupId: event.groupId))
                LocalPush.post(PushPayload(title: event.title, body: event.message, eventType: event.type, groupId: event.groupId))
            }
        }
        syncRelationships()
        persist()
    }

    private func syncRelationships() {
        let prices = currentPrices
        for group in state.groups {
            let pairs = KkangbuMath.pairSummaries(in: group.id, state: state, prices: prices)
            for pair in pairs {
                let a = min(pair.userA.uuidString, pair.userB.uuidString)
                let b = max(pair.userA.uuidString, pair.userB.uuidString)
                if let index = state.relationships.firstIndex(where: {
                    $0.groupId == group.id &&
                    min($0.userId.uuidString, $0.friendUserId.uuidString) == a &&
                    max($0.userId.uuidString, $0.friendUserId.uuidString) == b
                }) {
                    state.relationships[index].gradeRaw = pair.grade.id
                    state.relationships[index].score = pair.averageReturn
                    state.relationships[index].updatedAt = Date()
                } else {
                    state.relationships.append(
                        FriendRelationship(
                            groupId: group.id,
                            userId: pair.userA,
                            friendUserId: pair.userB,
                            gradeRaw: pair.grade.id,
                            score: pair.averageReturn
                        )
                    )
                }
            }
        }
    }

    private func stampFiredKeys(_ event: FeedEvent) {
        guard let key = event.metadata["key"], let holdingId = event.metadata["holdingId"].flatMap(UUID.init(uuidString:)),
              let index = state.holdings.firstIndex(where: { $0.id == holdingId }) else {
            if let key = event.metadata["key"], event.holdingId == nil {
                return
            }
            if let holdingId = event.holdingId ?? event.metadata["holdingId"].flatMap(UUID.init(uuidString:)),
               let key = event.metadata["key"],
               let index = state.holdings.firstIndex(where: { $0.id == holdingId }) {
                if !state.holdings[index].firedEventKeys.contains(key) {
                    state.holdings[index].firedEventKeys.append(key)
                }
            }
            return
        }
        if !state.holdings[index].firedEventKeys.contains(key) {
            state.holdings[index].firedEventKeys.append(key)
        }
    }

    private func maybeAwardBadge(_ event: FeedEvent) {
        guard let actor = event.actorId else { return }
        let type: String?
        switch event.type {
        case .foresight: type = "FORESIGHT"
        case .goldenKkangbu: type = "GOLDEN"
        case .diamondHands: type = "DIAMOND"
        case .verificationSuccess: type = "CLEARED"
        case .coBuyCompleted: type = "COBUY"
        default: type = nil
        }
        guard let type else { return }
        if state.badges.contains(where: { $0.userId == actor && $0.type == type && $0.groupId == event.groupId }) { return }
        state.badges.append(
            Badge(userId: actor, groupId: event.groupId, type: type, title: event.title, emoji: event.type.emoji)
        )
    }

    private func persist() {
        saveTask?.cancel()
        let snapshot = state
        let store = persistence
        saveTask = Task.detached(priority: .utility) {
            store.save(snapshot)
        }
    }
}

struct InboxItem: Identifiable {
    enum Kind { case recommend, proposal, suspect, nag, cobuyRegister }
    var id: UUID
    var kind: Kind
    var date: Date
    var recommendation: StockRecommendation?
    var proposal: StockProposal?
    var holding: Holding?
}
