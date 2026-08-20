import SwiftUI

struct ActivityView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ZStack {
                KkanbuBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("친구가 나를 부른 일")
                            .font(.title2.bold())
                        let items = store.inboxItems(for: store.state.currentUserId)
                        if items.isEmpty {
                            EmptyStateView(emoji: "💤", title: "지금은 조용해요", message: "누가 너도 사! 하거나 같이 사자고 하면 여기에 쌓여요.")
                        }
                        ForEach(items) { item in
                            inboxCard(item)
                        }
                        Text("최근 알림")
                            .font(.title2.bold())
                            .padding(.top, 8)
                        ForEach(Array(store.state.events.prefix(20))) { event in
                            KkanbuCard(padding: 14) {
                                EventRow(event: event, relative: MoneyFormat.relative(event.createdAt))
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("활동")
        }
    }

    @ViewBuilder
    private func inboxCard(_ item: InboxItem) -> some View {
        KkanbuCard {
            switch item.kind {
            case .recommend:
                if let rec = item.recommendation, let stock = store.state.stock(rec.stockId) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📣 \(store.state.nickname(rec.senderId))가 \(stock.name)를 추천했어요")
                            .font(.headline)
                        if let holding = store.state.holding(rec.holdingId) {
                            Text("평단 \(MoneyFormat.price(holding.averagePrice, market: stock.market)) · \(MoneyFormat.percent(holding.returnRate(currentPrice: store.price(for: stock.id))))")
                        }
                        Text("“\(rec.message)”")
                        HStack {
                            PillButton(title: "나도 추가하기") {
                                store.resolveRecommendation(rec.id, accept: true)
                            }
                            PillButton(title: "나중에", kind: .secondary) {
                                store.resolveRecommendation(rec.id, accept: false)
                            }
                        }
                    }
                }
            case .proposal:
                if let proposal = item.proposal {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🤔 \(store.state.nickname(proposal.proposerId))가 같이 사자고 해요")
                            .font(.headline)
                        Text(proposal.message)
                        HStack {
                            PillButton(title: "같이 사기") { store.promiseCoBuy(proposalId: proposal.id) }
                            PillButton(title: "나중에", kind: .secondary) { store.declineProposal(proposal.id) }
                        }
                    }
                }
            case .suspect:
                if let holding = item.holding, let stock = store.state.stock(holding.stockId) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("😂 친구들이 네 \(stock.name) 매수가를 의심하고 있습니다")
                            .font(.headline)
                        Text("진짜 \(MoneyFormat.price(holding.averagePrice, market: stock.market))에 산 거 맞아?")
                        Text("낙인 찍는 기능이 아니라, 장난스러운 인증 요청이에요.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @State private var shareQty: Bool = false
    @State private var shareAmount: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                KkanbuBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        KkanbuCard {
                            HStack(spacing: 14) {
                                AvatarView(emoji: store.state.currentUser.avatarEmoji, size: 72)
                                VStack(alignment: .leading) {
                                    Text(store.state.currentUser.nickname)
                                        .font(.largeTitle.bold())
                                    Text("친구들이랑 주식으로 노는 중")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        trust
                        privacy
                        playground
                        badges
                    }
                    .padding(16)
                }
            }
            .navigationTitle("프로필")
            .onAppear {
                shareQty = store.state.currentUser.shareQuantity
                shareAmount = store.state.currentUser.shareInvestedAmount
            }
        }
    }

    private var trust: some View {
        let stats = TrustMath.stats(for: store.state.currentUserId, state: store.state)
        return KkanbuCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("주식 신뢰도 \(stats.score)")
                    .font(.title2.bold())
                Text("실제 신용이나 투자 실력이 아니라 앱 안 장난 지표예요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("🟢 인증 \(stats.verifiedCount)  👀 의심 \(stats.suspectedCount)  😂 해명 \(stats.successCount)  🚨 수정 \(stats.updatedCount)")
            }
        }
    }

    private var privacy: some View {
        KkanbuCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("공개 범위")
                    .font(.headline)
                Toggle("보유수량 공개", isOn: $shareQty)
                Toggle("투자금액 공개", isOn: $shareAmount)
                Text("기본은 종목, 매수가, 수익률, 보유 여부만 보여요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .onChange(of: shareQty) { _, value in
                store.updatePrivacy(shareQuantity: value, shareAmount: shareAmount)
            }
            .onChange(of: shareAmount) { _, value in
                store.updatePrivacy(shareQuantity: shareQty, shareAmount: value)
            }
        }
    }

    private var playground: some View {
        KkanbuCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("놀이터 · 시장 흔들기")
                    .font(.headline)
                Text("시세 API는 StockPriceService 뒤에 숨어 있어요. 지금은 데모 시세입니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let nvda = StockCatalog.stock(ticker: "NVDA") {
                    HStack {
                        PillButton(title: "NVDA +15%") { store.shock(stockId: nvda.id, percent: 0.15) }
                        PillButton(title: "NVDA -15%", kind: .danger) { store.shock(stockId: nvda.id, percent: -0.15) }
                    }
                }
                if let tsla = StockCatalog.stock(ticker: "TSLA") {
                    HStack {
                        PillButton(title: "TSLA 폭등", kind: .secondary) { store.shock(stockId: tsla.id, percent: 0.22) }
                        PillButton(title: "TSLA 폭락", kind: .secondary) { store.shock(stockId: tsla.id, percent: -0.17) }
                    }
                }
                PillButton(title: "데모 파티 리셋", kind: .ghost) { store.resetDemo() }
            }
        }
    }

    private var badges: some View {
        let mine = store.state.badges.filter { $0.userId == store.state.currentUserId }
        return KkanbuCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("칭호")
                    .font(.headline)
                if mine.isEmpty {
                    Text("사건이 쌓이면 칭호가 붙어요.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(mine) { badge in
                        Text("\(badge.emoji) \(badge.title)")
                    }
                }
            }
        }
    }
}

struct RankingsView: View {
    @Environment(AppStore.self) private var store
    var group: Group

    var body: some View {
        NavigationStack {
            ScrollView {
                let board = RankingService.board(groupId: group.id, state: store.state, prices: store.currentPrices)
                VStack(alignment: .leading, spacing: 16) {
                    Text("🏆 이번 주")
                        .font(.largeTitle.bold())
                    Text("금융 리그가 아니라 칭호 놀이입니다.")
                        .foregroundStyle(.secondary)
                    ForEach(board.weeklyReturns) { row in
                        KkanbuCard(padding: 14) {
                            HStack {
                                Text(row.title).font(.headline)
                                Spacer()
                                Text(row.valueText).font(.title3.bold())
                            }
                        }
                    }
                    Text("칭호")
                        .font(.title2.bold())
                    ForEach(board.titles) { row in
                        KkanbuCard(padding: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(row.emoji) \(row.title)").font(.headline)
                                Text(row.subtitle).foregroundStyle(.secondary)
                                Text(row.valueText).font(.subheadline.bold())
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(KkanbuBackground())
            .navigationTitle("랭킹")
        }
    }
}

struct FriendDetailView: View {
    @Environment(AppStore.self) private var store
    var user: User
    var group: Group

    var body: some View {
        ZStack {
            KkanbuBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    shared
                    holdings
                    history
                }
                .padding(16)
            }
        }
        .navigationTitle(user.nickname)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pair: PairSummary? {
        KkangbuMath.pairSummaries(in: group.id, state: store.state, prices: store.currentPrices)
            .first { $0.userA == user.id && $0.userB == store.state.currentUserId || $0.userB == user.id && $0.userA == store.state.currentUserId }
    }

    private var header: some View {
        KkanbuCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    AvatarView(emoji: user.avatarEmoji, size: 64)
                    VStack(alignment: .leading) {
                        Text("\(user.nickname) 🤝")
                            .font(.title.bold())
                        if let pair {
                            Text("\(pair.grade.emoji) \(pair.grade.title)")
                                .font(.headline)
                            Text("공동 보유 \(pair.sharedCount)종목 · 평균 \(MoneyFormat.percent(pair.averageReturn))")
                        } else {
                            Text("아직 공동 종목이 없어요")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                let stats = TrustMath.stats(for: user.id, state: store.state)
                Text("주식 신뢰도 \(stats.score)  ·  🟢 \(stats.verifiedCount)  👀 \(stats.suspectedCount)  🚨 \(stats.updatedCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var shared: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("공동 종목")
                .font(.headline)
            if let pair {
                ForEach(pair.bonds) { bond in
                    if let stock = store.state.stock(bond.stockId) {
                        Text("\(stock.name) \(MoneyFormat.percent(bond.sharedReturn))")
                            .font(.title3.bold())
                    }
                }
            }
        }
    }

    private var holdings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(user.nickname)의 주식")
                .font(.headline)
            ForEach(store.state.holdings.filter { $0.userId == user.id }) { holding in
                if let stock = store.state.stock(holding.stockId) {
                    HoldingCardView(
                        stock: stock,
                        holding: holding,
                        currentPrice: store.price(for: stock.id),
                        partners: partners(holding),
                        grade: nil,
                        showsQuantity: user.shareQuantity,
                        isMine: false,
                        onSuspect: { store.suspectHolding(holding.id) }
                    )
                }
            }
        }
    }

    private var history: some View {
        let events = store.state.events.filter {
            $0.groupId == group.id && ($0.actorId == user.id || $0.targetUserId == user.id)
        }
        return VStack(alignment: .leading, spacing: 10) {
            Text("관계 역사")
                .font(.headline)
            ForEach(Array(events.prefix(30))) { event in
                EventRow(event: event, relative: MoneyFormat.relative(event.createdAt))
            }
        }
    }

    private func partners(_ holding: Holding) -> [String] {
        KkangbuMath.bonds(in: group.id, state: store.state, prices: store.currentPrices)
            .filter { $0.stockId == holding.stockId && $0.members.contains(user.id) }
            .compactMap { store.state.nickname($0.partner(of: user.id)) }
    }
}
