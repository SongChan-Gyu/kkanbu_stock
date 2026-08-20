import SwiftUI

struct ActivityView: View {
    @Environment(AppStore.self) private var store
    @State private var verifyHolding: Holding?
    @State private var addPrefill: Stock?

    var body: some View {
        NavigationStack {
            ZStack {
                KkanbuBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("나를 향한 일")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.muted)
                        let items = store.inboxItems(for: store.state.currentUserId)
                        if items.isEmpty {
                            EmptyStateView(title: "대기 중인 일이 없습니다", message: "추천이나 같이 사기 제안이 오면 여기에 모입니다.")
                        }
                        ForEach(items) { item in
                            InboxActionCard(item: item, onVerify: { verifyHolding = $0 }, onRegister: { addPrefill = $0 })
                        }
                        Text("최근 기록")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.muted)
                            .padding(.top, 8)
                        ForEach(Array(store.state.events.prefix(20))) { event in
                            EventRow(
                                event: event,
                                relative: MoneyFormat.relative(event.createdAt),
                                actorName: event.actorId.map { store.state.nickname($0) } ?? ""
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("활동")
            .sheet(item: $verifyHolding) { ScreenshotVerifySheet(holding: $0) }
            .sheet(item: $addPrefill) { AddStockView(prefill: $0) }
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
                                AvatarView(emoji: store.state.currentUser.avatarEmoji, name: store.state.currentUser.nickname, size: 48)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.state.currentUser.nickname)
                                        .font(.title3.weight(.semibold))
                                    Text("로컬 데모")
                                        .font(.caption)
                                        .foregroundStyle(KkanbuTheme.faint)
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
                    .font(.headline)
                Text("실제 신용이나 투자 실력이 아니라 앱 안 지표입니다.")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
                Text("인증 \(stats.verifiedCount) · 의심 \(stats.suspectedCount) · 해명 \(stats.successCount) · 수정 \(stats.updatedCount)")
                    .font(.footnote)
                    .foregroundStyle(KkanbuTheme.muted)
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
                Text("지금은 데모 시세입니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("사건 기준")
                    .font(.subheadline.bold())
                HStack {
                    Text("선견지명 \(Int(store.state.thresholds.foresightDrop * 100))%")
                    Spacer()
                    Button("-") {
                        var t = store.state.thresholds
                        t.foresightDrop = max(0.05, t.foresightDrop - 0.05)
                        store.updateThresholds(t)
                    }
                    Button("+") {
                        var t = store.state.thresholds
                        t.foresightDrop = min(0.4, t.foresightDrop + 0.05)
                        store.updateThresholds(t)
                    }
                }
                HStack {
                    Text("너무 일찍 튐 \(Int(store.state.thresholds.soldTooEarlyRise * 100))%")
                    Spacer()
                    Button("-") {
                        var t = store.state.thresholds
                        t.soldTooEarlyRise = max(0.05, t.soldTooEarlyRise - 0.05)
                        store.updateThresholds(t)
                    }
                    Button("+") {
                        var t = store.state.thresholds
                        t.soldTooEarlyRise = min(0.4, t.soldTooEarlyRise + 0.05)
                        store.updateThresholds(t)
                    }
                }
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
                if let groupId = store.state.selectedGroupId {
                    Text("친구로 플레이 (테스트용)")
                        .font(.subheadline.bold())
                        .padding(.top, 6)
                    ForEach(store.state.memberUsers(of: groupId)) { user in
                    Button("\(user.nickname)으로 보기") {
                            store.playAs(user.id)
                        }
                    }
                }
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
                        Text(badge.title)
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
                    Text("이번 주")
                        .font(.title3.weight(.semibold))
                    Text("금융 리그가 아니라 그룹 안 기록입니다.")
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
                                Text(row.title).font(.headline)
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
                    historySections
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
                    AvatarView(emoji: user.avatarEmoji, name: user.nickname, size: 48)
                    VStack(alignment: .leading) {
                        Text(user.nickname)
                            .font(.title3.weight(.semibold))
                        if let pair {
                            Text(pair.grade.title)
                                .font(.subheadline)
                            Text("공동 보유 \(pair.sharedCount)종목 · 평균 \(MoneyFormat.percent(pair.averageReturn))")
                                .font(.caption)
                                .foregroundStyle(KkanbuTheme.muted)
                        } else {
                            Text("아직 공동 종목이 없습니다")
                                .font(.footnote)
                                .foregroundStyle(KkanbuTheme.muted)
                        }
                    }
                }
                let stats = TrustMath.stats(for: user.id, state: store.state)
                Text("주식 신뢰도 \(stats.score)  ·  인증 \(stats.verifiedCount) · 의심 \(stats.suspectedCount) · 수정 \(stats.updatedCount)")
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

    private var historySections: some View {
        let records = SocialHistory.records(
            between: store.state.currentUserId,
            friend: user.id,
            groupId: group.id,
            state: store.state,
            prices: store.currentPrices
        )
        return VStack(alignment: .leading, spacing: 14) {
            historyBlock("내가 추천한 종목", records.recommendedByMe)
            historyBlock("\(user.nickname)가 제안한 종목", records.proposedByFriend)
            historyBlock("같이 사기로 한 종목", records.coBuys)
            historyBlock("\(user.nickname)가 매도한 기록", records.escapes)
            historyBlock("\(user.nickname)의 선견지명", records.foresights)
            historyBlock("너무 이른 매도", records.soldTooEarly)
        }
    }

    @ViewBuilder
    private func historyBlock(_ title: String, _ items: [HistoryRecord]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                ForEach(items) { item in
                    KkanbuCard(padding: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.detail)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text(item.result)
                                    .font(.subheadline.bold())
                                if let value = item.currentReturn {
                                    Spacer()
                                    Text("현재 \(MoneyFormat.percent(value))")
                                        .foregroundStyle(value >= 0 ? Color.kkanbuUp : Color.kkanbuDown)
                                }
                            }
                        }
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
                        isMine: false
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
