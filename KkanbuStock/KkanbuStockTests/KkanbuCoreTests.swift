import XCTest
@testable import KkanbuStock

final class StockTextParserTests: XCTestCase {
    private let parser = StockTextParser()
    private var catalog: [Stock] { StockCatalog.all }

    func testNVIDIATickerAndLabeledPrice() {
        let result = parser.analyze(
            text: "NVDA\nNVIDIA\n평균매입가 $163.40\n$182.40\n+11.59%",
            catalog: catalog,
            now: Date()
        )
        XCTAssertEqual(result.matchedStock?.ticker, "NVDA")
        XCTAssertEqual(result.recognizedPrice, 163.40, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.9)
        XCTAssertGreaterThanOrEqual(result.priceConfidence, 0.9)
        XCTAssertEqual(result.recognizedReturn ?? 0, 0.1159, accuracy: 0.001)
    }

    func testSamsungCode() {
        let result = parser.analyze(
            text: "005930\n삼성전자\n매입단가 72,300원",
            catalog: catalog,
            now: Date()
        )
        XCTAssertEqual(result.matchedStock?.krCode, "005930")
        XCTAssertEqual(result.recognizedPrice, 72300, accuracy: 1)
    }

    func testAppleEnglishAverage() {
        let result = parser.analyze(
            text: "AAPL\nApple\nAverage Price $198.20",
            catalog: catalog,
            now: Date()
        )
        XCTAssertEqual(result.matchedStock?.ticker, "AAPL")
        XCTAssertEqual(result.recognizedPrice, 198.20, accuracy: 0.01)
    }

    func testLowConfidenceWithoutMatch() {
        let result = parser.analyze(text: "hello world 123", catalog: catalog, now: Date())
        XCTAssertNil(result.matchedStock)
        XCTAssertTrue(result.tooLow)
    }
}

final class VerificationServiceTests: XCTestCase {
    func testMatchWithinTolerance() {
        let nvda = StockCatalog.stock(ticker: "NVDA")!
        let holding = Holding(userId: UUID(), stockId: nvda.id, averagePrice: 163.40)
        let analysis = ScreenshotAnalysisResult(
            recognizedTicker: "NVDA",
            recognizedName: "NVIDIA",
            recognizedPrice: 163.50,
            matchedStock: nvda,
            confidence: 0.96,
            rawText: "",
            priceConfidence: 0.93
        )
        let outcome = VerificationService().verify(holding: holding, analysis: analysis, stock: nvda)
        XCTAssertTrue(outcome.matched)
    }

    func testMismatchIsNotFraudJudgement() {
        let nvda = StockCatalog.stock(ticker: "NVDA")!
        let holding = Holding(userId: UUID(), stockId: nvda.id, averagePrice: 120)
        let analysis = ScreenshotAnalysisResult(
            recognizedTicker: "NVDA",
            recognizedPrice: 163.40,
            matchedStock: nvda,
            confidence: 0.96,
            rawText: "",
            priceConfidence: 0.93
        )
        let outcome = VerificationService().verify(holding: holding, analysis: analysis, stock: nvda)
        XCTAssertFalse(outcome.matched)
        XCTAssertEqual(outcome.ocrPrice, 163.40, accuracy: 0.01)
    }
}

final class KkangbuMathTests: XCTestCase {
    func testSharedHoldingCreatesBond() {
        let nvda = StockCatalog.stock(ticker: "NVDA")!
        let a = UUID()
        let b = UUID()
        let group = UUID()
        var state = AppState.empty(user: User(id: a, nickname: "철수"), stocks: StockCatalog.all)
        state.users.append(User(id: b, nickname: "영희"))
        state.groups.append(Group(id: group, name: "팟", inviteCode: "ABC123", ownerId: a))
        state.members = [
            GroupMember(groupId: group, userId: a),
            GroupMember(groupId: group, userId: b)
        ]
        state.holdings = [
            Holding(userId: a, stockId: nvda.id, averagePrice: 100),
            Holding(userId: b, stockId: nvda.id, averagePrice: 100)
        ]
        let bonds = KkangbuMath.bonds(in: group, state: state, prices: [nvda.id: 130])
        XCTAssertEqual(bonds.count, 1)
        XCTAssertEqual(bonds[0].grade.id, KkangbuGradeBook.golden.id)
    }

    func testNoBondAcrossGroups() {
        let nvda = StockCatalog.stock(ticker: "NVDA")!
        let a = UUID()
        let b = UUID()
        let g1 = UUID()
        let g2 = UUID()
        var state = AppState.empty(user: User(id: a, nickname: "철수"), stocks: StockCatalog.all)
        state.users.append(User(id: b, nickname: "영희"))
        state.groups = [
            Group(id: g1, name: "회사", inviteCode: "AAAAAA", ownerId: a),
            Group(id: g2, name: "학교", inviteCode: "BBBBBB", ownerId: b)
        ]
        state.members = [
            GroupMember(groupId: g1, userId: a),
            GroupMember(groupId: g2, userId: b)
        ]
        state.holdings = [
            Holding(userId: a, stockId: nvda.id, averagePrice: 100),
            Holding(userId: b, stockId: nvda.id, averagePrice: 100)
        ]
        XCTAssertTrue(KkangbuMath.bonds(in: g1, state: state, prices: [nvda.id: 120]).isEmpty)
    }
}

final class EventEngineTests: XCTestCase {
    private let engine = EventEngine()
    private let nvda = StockCatalog.stock(ticker: "NVDA")!

    func testNewKkangbuAndSoloEscape() {
        let cheolsu = User(nickname: "철수")
        let younghee = User(nickname: "영희")
        let group = Group(name: "팟", inviteCode: "KKANBU", ownerId: cheolsu.id)
        var before = AppState.empty(user: cheolsu, stocks: StockCatalog.all)
        before.users.append(younghee)
        before.groups = [group]
        before.members = [
            GroupMember(groupId: group.id, userId: cheolsu.id),
            GroupMember(groupId: group.id, userId: younghee.id)
        ]
        before.holdings = [Holding(userId: cheolsu.id, stockId: nvda.id, averagePrice: 160)]

        var after = before
        let added = Holding(userId: younghee.id, stockId: nvda.id, averagePrice: 165)
        after.holdings.append(added)
        let prices = [nvda.id: 182.4]
        let born = engine.evaluate(
            context: EventContext(
                trigger: .holdingAdded(holdingId: added.id),
                before: before,
                after: after,
                now: Date(),
                prices: prices,
                beforePrices: prices
            )
        )
        XCTAssertTrue(born.contains { $0.type == .newKkangbu })

        var soldState = after
        var sold = after.holdings[0]
        sold.status = .sold
        sold.sellPrice = 190
        sold.sellDate = Date()
        soldState.holdings[0] = sold
        let escape = engine.evaluate(
            context: EventContext(
                trigger: .holdingSold(holdingId: sold.id),
                before: after,
                after: soldState,
                now: Date(),
                prices: prices,
                beforePrices: prices
            )
        )
        XCTAssertTrue(escape.contains { $0.type == .soloEscape })
        XCTAssertTrue(escape.contains { $0.type == .diamondHands })
    }

    func testForesightAndSoldTooEarly() {
        let user = User(nickname: "철수")
        let group = Group(name: "팟", inviteCode: "KKANBU", ownerId: user.id)
        var state = AppState.empty(user: user, stocks: StockCatalog.all)
        state.groups = [group]
        state.members = [GroupMember(groupId: group.id, userId: user.id)]
        var holding = Holding(
            userId: user.id,
            stockId: nvda.id,
            averagePrice: 160,
            sellPrice: 190,
            sellDate: Date().addingTimeInterval(-3600),
            status: .sold
        )
        state.holdings = [holding]
        let down = engine.evaluate(
            context: EventContext(
                trigger: .pricesUpdated,
                before: state,
                after: state,
                now: Date(),
                prices: [nvda.id: 150],
                beforePrices: [nvda.id: 190]
            )
        )
        XCTAssertTrue(down.contains { $0.type == .foresight })

        let up = engine.evaluate(
            context: EventContext(
                trigger: .pricesUpdated,
                before: state,
                after: state,
                now: Date(),
                prices: [nvda.id: 240],
                beforePrices: [nvda.id: 190]
            )
        )
        XCTAssertTrue(up.contains { $0.type == .soldTooEarly })
    }

    func testRecommendAndCoBuyCopy() {
        let a = User(nickname: "영희")
        let b = User(nickname: "민수")
        let group = Group(name: "팟", inviteCode: "KKANBU", ownerId: a.id)
        var state = AppState.empty(user: a, stocks: StockCatalog.all)
        state.users.append(b)
        state.groups = [group]
        let rec = StockRecommendation(
            groupId: group.id,
            senderId: a.id,
            receiverId: b.id,
            stockId: nvda.id,
            holdingId: UUID(),
            message: "너도 사 ㅋㅋ"
        )
        state.recommendations = [rec]
        let events = engine.evaluate(
            context: EventContext(
                trigger: .recommendationSent(id: rec.id),
                before: state,
                after: state,
                now: Date(),
                prices: [:],
                beforePrices: [:]
            )
        )
        XCTAssertEqual(events.first?.type, .recommendStock)
        XCTAssertTrue(events.first?.message.contains("너도 사") == true)
    }

    func testEngineIsExtensible() {
        struct ExtraRule: EventRule {
            let ruleId = "EXTRA"
            func evaluate(context: EventContext) -> [FeedEvent] { [] }
        }
        var engine = EventEngine(rules: [])
        engine.register(ExtraRule())
        XCTAssertEqual(engine.rules.count, 1)
        XCTAssertEqual(EventEngine.defaultRules().count, 16)
    }
}

@MainActor
final class AppStoreFlowTests: XCTestCase {
    func testInviteJoinAddStockAndRecommendLoop() {
        let store = AppStore(state: .empty(user: User(nickname: "나"), stocks: StockCatalog.all), persistence: PersistenceStore(filename: "test-\(UUID().uuidString).json"))
        store.createGroup(name: "회사 주식팟")
        XCTAssertEqual(store.state.groups.count, 1)
        let code = store.state.groups[0].inviteCode

        let friend = User(nickname: "철수", avatarEmoji: "🦊")
        store.state.users.append(friend)
        store.state.members.append(GroupMember(groupId: store.state.groups[0].id, userId: friend.id))

        let nvda = StockCatalog.stock(ticker: "NVDA")!
        store.addHolding(stock: nvda, averagePrice: 163.4, quantity: nil, purchaseDate: Date(), method: .manual, verification: .unverified)
        XCTAssertEqual(store.state.activeHoldings(of: store.state.currentUserId).count, 1)

        let holding = store.state.activeHoldings(of: store.state.currentUserId)[0]
        store.recommend(holding: holding, to: friend.id, message: "너도 사")
        XCTAssertEqual(store.state.recommendations.count, 1)
        XCTAssertTrue(store.state.events.contains { $0.type == .recommendStock })

        let originalUser = store.state.currentUserId
        store.state.currentUserId = friend.id
        store.resolveRecommendation(store.state.recommendations[0].id, accept: true, averagePrice: 170)
        store.state.currentUserId = originalUser

        XCTAssertTrue(store.state.events.contains { $0.type == .newKkangbu || $0.type == .kkangbuRecruited })
        XCTAssertEqual(KkangbuMath.bonds(in: store.state.groups[0].id, state: store.state, prices: store.currentPrices).count, 1)

        store.sellHolding(id: holding.id, sellPrice: 200, sellDate: Date())
        XCTAssertTrue(store.state.events.contains { $0.type == .soloEscape })
        _ = code
    }

    func testNagCooldown() {
        let store = AppStore(state: .empty(user: User(nickname: "민수"), stocks: StockCatalog.all), persistence: PersistenceStore(filename: "test-nag-\(UUID().uuidString).json"))
        store.createGroup(name: "팟")
        let amd = StockCatalog.stock(ticker: "AMD")!
        store.propose(stock: amd, message: "같이 사자")
        store.nag(proposalId: store.state.proposals[0].id)
        store.nag(proposalId: store.state.proposals[0].id)
        XCTAssertNotNil(store.lastError)
    }

    func testTwentyScenarioMVPLoop() {
        let me = User(nickname: "나", avatarEmoji: "🐣")
        let store = AppStore(
            state: .empty(user: me, stocks: StockCatalog.all),
            persistence: PersistenceStore(filename: "test-20-\(UUID().uuidString).json")
        )
        store.createGroup(name: "우리 주식팟")
        let group = store.state.groups[0]
        XCTAssertFalse(group.inviteCode.isEmpty)

        let younghee = User(nickname: "영희", avatarEmoji: "🐰")
        store.state.users.append(younghee)
        store.state.members.append(GroupMember(groupId: group.id, userId: younghee.id))

        let nvda = StockCatalog.stock(ticker: "NVDA")!
        let ocr = store.analyzeText("NVDA\nNVIDIA\n평균매입가 $163.40")
        XCTAssertEqual(ocr.matchedStock?.ticker, "NVDA")
        store.addHolding(
            stock: nvda,
            averagePrice: ocr.recognizedPrice ?? 163.4,
            quantity: nil,
            purchaseDate: Date(),
            method: .screenshot,
            verification: .screenshotVerified
        )
        XCTAssertEqual(store.state.activeHoldings(of: me.id).first?.verificationState, .screenshotVerified)

        let mine = store.state.activeHoldings(of: me.id)[0]
        store.recommend(holding: mine, to: younghee.id, message: "너도 사 ㅋㅋ")
        store.playAs(younghee.id)
        store.resolveRecommendation(store.state.recommendations[0].id, accept: true, averagePrice: 168.2)
        XCTAssertFalse(KkangbuMath.bonds(in: group.id, state: store.state, prices: store.currentPrices).isEmpty)
        XCTAssertTrue(store.state.events.contains { $0.type == .newKkangbu || $0.type == .kkangbuRecruited })
        XCTAssertFalse(store.state.relationships.isEmpty)

        let tsla = StockCatalog.stock(ticker: "TSLA")!
        store.playAs(me.id)
        store.propose(stock: tsla, message: "이번에 같이 들어갈 사람?")
        XCTAssertEqual(store.state.proposals.count, 1)
        store.playAs(younghee.id)
        store.promiseCoBuy(proposalId: store.state.proposals[0].id)
        XCTAssertTrue(store.inboxItems(for: younghee.id).contains { $0.kind == .cobuyRegister })
        store.addHolding(stock: tsla, averagePrice: 241, quantity: nil, purchaseDate: Date(), method: .chart, verification: .unverified)
        store.playAs(me.id)
        store.addHolding(stock: tsla, averagePrice: 240, quantity: nil, purchaseDate: Date(), method: .manual, verification: .unverified)
        XCTAssertTrue(store.state.events.contains { $0.type == .coBuyCompleted })
        XCTAssertGreaterThanOrEqual(KkangbuMath.bonds(in: group.id, state: store.state, prices: store.currentPrices).count, 2)

        store.playAs(younghee.id)
        store.suspectHolding(mine.id)
        store.playAs(me.id)
        XCTAssertTrue(store.inboxItems(for: me.id).contains { $0.kind == .suspect })

        store.sellHolding(id: mine.id, sellPrice: 200, sellDate: Date())
        XCTAssertTrue(store.state.events.contains { $0.type == .soloEscape })

        store.shock(stockId: nvda.id, percent: -0.2)
        XCTAssertTrue(store.state.events.contains { $0.type == .foresight })

        let board = RankingService.board(groupId: group.id, state: store.state, prices: store.currentPrices)
        XCTAssertFalse(board.weeklyReturns.isEmpty)
        XCTAssertFalse(store.state.events.filter { $0.groupId == group.id }.isEmpty)
    }

    func testGurapingMismatchDoesNotCallFraud() {
        let store = AppStore(state: .empty(user: User(nickname: "준호"), stocks: StockCatalog.all), persistence: PersistenceStore(filename: "test-gura-\(UUID().uuidString).json"))
        store.createGroup(name: "팟")
        let tsla = StockCatalog.stock(ticker: "TSLA")!
        store.addHolding(stock: tsla, averagePrice: 120, quantity: nil, purchaseDate: Date(), method: .manual, verification: .unverified)
        let holding = store.state.activeHoldings(of: store.state.currentUserId)[0]
        let analysis = store.analyzeText("TSLA\nTesla\n평균매입가 $241.00")
        store.applyScreenshotVerification(holdingId: holding.id, analysis: analysis)
        XCTAssertEqual(store.state.holding(holding.id)?.verificationState, .mismatch)
        XCTAssertTrue(store.state.events.contains { $0.type == .verificationMismatch })
        XCTAssertFalse(store.state.events.contains { $0.message.contains("사기꾼") })
    }
}
