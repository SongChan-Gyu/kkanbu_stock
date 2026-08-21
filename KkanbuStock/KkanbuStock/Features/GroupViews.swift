import SwiftUI

struct GroupHomeContainer: View {
    @Environment(AppStore.self) private var store
    @State private var showCreate = false
    @State private var showJoin = false
    @State private var showSwitch = false

    var body: some View {
        NavigationStack {
            ZStack {
                KkanbuBackground()
                if let group = store.state.selectedGroup {
                    GroupHomeView(group: group)
                } else {
                    empty
                }
            }
            .navigationTitle(store.state.selectedGroup?.name ?? "그룹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("그룹") { showSwitch = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("새 그룹", systemImage: "plus") { showCreate = true }
                        Button("코드로 참여", systemImage: "link") { showJoin = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showCreate) { CreateGroupSheet() }
            .sheet(isPresented: $showJoin) { JoinGroupSheet() }
            .sheet(isPresented: $showSwitch) { GroupSwitchSheet() }
        }
    }

    private var empty: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                title: "아직 그룹이 없습니다",
                message: "그룹을 만들거나 초대 코드로 들어가세요.",
                centered: true
            )
            QuietButton(title: "그룹 만들기") { showCreate = true }
                .padding(.horizontal, 24)
            QuietButton(title: "초대 코드로 참여", kind: .secondary) { showJoin = true }
                .padding(.horizontal, 24)
        }
        .padding()
    }
}

struct GroupHomeView: View {
    @Environment(AppStore.self) private var store
    var group: Group
    @State private var showRank = false
    @State private var showAdd = false
    @State private var showPropose = false
    @State private var addPrefill: Stock?
    @State private var verifyHolding: Holding?
    @State private var threadStock: Stock?
    @State private var openSections: Set<String> = ["turn", "mood"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                members
                header
                myTurn
                if recCount > 0 {
                    FoldSection(title: "추천 종목", count: recCount, isOpen: openBinding("recs")) {
                        recommendedThreads
                    }
                }
                if pulseCount > 0 {
                    FoldSection(title: "종목 평가", count: pulseCount, isOpen: openBinding("mood")) {
                        todayPulse
                    }
                }
                if bondCount > 0 {
                    FoldSection(title: "깐부", count: bondCount, preview: kkPreview, isOpen: openBinding("kk")) {
                        kkangbuStrip
                    }
                }
                if pendingCount > 0 {
                    FoldSection(title: "매수 제안", count: pendingCount, isOpen: openBinding("pending")) {
                        pending
                    }
                }
                if friendCount > 0 {
                    FoldSection(title: "친구 주식", count: friendCount, isOpen: openBinding("friends")) {
                        friendsStocks
                    }
                }
                FoldSection(title: "활동", count: eventCount, preview: feedPreview, isOpen: openBinding("feed")) {
                    VStack(alignment: .leading, spacing: 12) {
                        hero
                        feed
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .animation(.spring(duration: 0.45), value: store.state.events.first?.id)
        .sheet(isPresented: $showRank) { RankingsView(group: group) }
        .sheet(isPresented: $showAdd) { AddStockView() }
        .sheet(isPresented: $showPropose) { ProposalSheet() }
        .sheet(item: $addPrefill) { AddStockView(prefill: $0) }
        .sheet(item: $verifyHolding) { ScreenshotVerifySheet(holding: $0) }
        .sheet(item: $threadStock) { RecommendationThreadView(stock: $0) }
    }

    private func openBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { openSections.contains(id) },
            set: { on in
                if on { openSections.insert(id) } else { openSections.remove(id) }
            }
        )
    }

    private var recCount: Int {
        Set(store.state.recommendations.filter { $0.groupId == group.id }.map(\.stockId)).count
    }
    private var pulseCount: Int {
        let recIds = store.state.recommendations.filter { $0.groupId == group.id }.map(\.stockId)
        let bondIds = KkangbuMath.bonds(in: group.id, state: store.state, prices: store.currentPrices).map(\.stockId)
        return Set(recIds + bondIds).count
    }
    private var bondCount: Int {
        KkangbuMath.bonds(in: group.id, state: store.state, prices: store.currentPrices).count
    }
    private var kkPreview: String? {
        let bonds = KkangbuMath.bonds(in: group.id, state: store.state, prices: store.currentPrices)
        let mood = bonds.first(where: { $0.grade.isRoast }) ?? bonds.first(where: { $0.grade.isGlory })
        return mood?.grade.title
    }
    private var pendingCount: Int {
        store.state.proposals.filter { $0.groupId == group.id && $0.status == .open }.count
    }
    private var friendCount: Int {
        GroupSocial.memberHoldings(in: group.id, state: store.state)
            .filter { $0.1.status == .holding && $0.0.id != store.state.currentUserId }.count
    }
    private var eventCount: Int {
        store.state.events.filter { $0.groupId == group.id }.count
    }
    private var feedPreview: String? {
        store.state.events.first(where: { $0.groupId == group.id })?.title
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                InviteChip(code: group.inviteCode) { store.copyInviteCode(group.inviteCode) }
                Spacer()
                Button("랭킹") { showRank = true }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(KkanbuTheme.ink)
            }
            HStack(spacing: 8) {
                QuietButton(title: "주식 추가") { showAdd = true }
                QuietButton(title: "매수 제안", kind: .secondary) { showPropose = true }
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var myTurn: some View {
        let items = store.inboxItems(for: store.state.currentUserId)
        return Group {
            if !items.isEmpty {
                FoldSection(title: "내 차례", count: items.count, isOpen: openBinding("turn")) {
                    TabView {
                        ForEach(items) { item in
                            InboxActionCard(
                                item: item,
                                onVerify: { verifyHolding = $0 },
                                onRegister: { addPrefill = $0 },
                                onOpenThread: { threadStock = $0 }
                            )
                            .padding(.bottom, 28)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    .frame(minHeight: 280, idealHeight: 320, maxHeight: 360)
                }
            }
        }
    }

    private var recommendedThreads: some View {
        let recs = store.state.recommendations.filter { $0.groupId == group.id }
        let stockIds = recs.reduce(into: [UUID]()) { result, rec in
            if !result.contains(rec.stockId) { result.append(rec.stockId) }
        }
        return Group {
            if !stockIds.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(stockIds, id: \.self) { stockId in
                        if let stock = store.state.stock(stockId) {
                            let related = recs.filter { $0.stockId == stockId }
                            let count = store.commentCount(in: group.id, stockId: stockId)
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    threadStock = stock
                                } label: {
                                    HStack(alignment: .top, spacing: 12) {
                                        StockMark(ticker: stock.ticker, name: stock.name, size: 40)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(stock.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(KkanbuTheme.ink)
                                            Text(related.map { "\(store.state.nickname($0.senderId)) → \(store.state.nickname($0.receiverId))" }.joined(separator: " · "))
                                                .font(.caption)
                                                .foregroundStyle(KkanbuTheme.muted)
                                            Text(related.last.map { "“\($0.message)”" } ?? "")
                                                .font(.caption)
                                                .foregroundStyle(KkanbuTheme.ink)
                                        }
                                        Spacer()
                                        CommentCountLabel(count: count)
                                    }
                                }
                                .buttonStyle(.plain)
                                PulseStrip(snapshot: pulse(for: stock), stock: stock)
                            }
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                        }
                    }
                }
            }
        }
    }

    private var todayPulse: some View {
        let recIds = store.state.recommendations.filter { $0.groupId == group.id }.map(\.stockId)
        let bondIds = KkangbuMath.bonds(in: group.id, state: store.state, prices: store.currentPrices).map(\.stockId)
        let ids = (recIds + bondIds).reduce(into: [UUID]()) { result, id in
            if !result.contains(id) { result.append(id) }
        }
        return Group {
            if !ids.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(ids.prefix(3), id: \.self) { stockId in
                        if let stock = store.state.stock(stockId) {
                            let snap = pulse(for: stock)
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    threadStock = stock
                                } label: {
                                    HStack(spacing: 12) {
                                        StockMark(ticker: stock.ticker, name: stock.name, size: 36)
                                        Text(stock.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(KkanbuTheme.ink)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                PulseStrip(snapshot: snap, compact: false, stock: stock)
                            }
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                        }
                    }
                }
            }
        }
    }

    private func pulse(for stock: Stock) -> StockPulse.Snapshot {
        store.pulseSnapshot(for: stock, in: group.id)
    }

    private var hero: some View {
        let spicy = GroupSocial.spicyEvents(in: group.id, state: store.state)
        return Group {
            if let event = spicy.first {
                KkanbuCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("지금")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.muted)
                        EventRow(
                            event: event,
                            relative: MoneyFormat.relative(event.createdAt),
                            actorName: event.actorId.map { store.state.nickname($0) } ?? ""
                        )
                    }
                }
            }
        }
    }

    private var members: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(store.state.memberUsers(of: group.id)) { user in
                    NavigationLink {
                        FriendDetailView(user: user, group: group)
                    } label: {
                        VStack(spacing: 7) {
                            AvatarView(emoji: user.avatarEmoji, name: user.nickname, size: 56)
                                .overlay {
                                    Circle().stroke(KkanbuTheme.line, lineWidth: 1)
                                }
                            Text(user.id == store.state.currentUserId ? "나" : user.nickname)
                                .font(.caption)
                                .foregroundStyle(KkanbuTheme.ink)
                                .lineLimit(1)
                        }
                        .frame(width: 64)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var kkangbuStrip: some View {
        let bonds = KkangbuMath.bonds(in: group.id, state: store.state, prices: store.currentPrices)
        return Group {
            if !bonds.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    if let mood = bonds.first(where: { $0.grade.isRoast }) ?? bonds.first(where: { $0.grade.isGlory }) {
                        Text("지금 분위기 · \(store.state.nickname(mood.userA)) · \(store.state.nickname(mood.userB)), \(mood.grade.title)")
                            .font(.caption)
                            .foregroundStyle(mood.grade.isRoast ? Color.kkanbuDown : Color.kkanbuUp)
                    }
                    ForEach(bonds) { bond in
                        if let stock = store.state.stock(bond.stockId) {
                            HStack(alignment: .center, spacing: 12) {
                                StockMark(ticker: stock.ticker, name: stock.name, size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(store.state.nickname(bond.userA)) · \(store.state.nickname(bond.userB))")
                                        .font(.subheadline.weight(.semibold))
                                    GradeTitle(grade: bond.grade)
                                    Text(stock.name)
                                        .font(.caption)
                                        .foregroundStyle(KkanbuTheme.faint)
                                }
                                Spacer()
                                Text(MoneyFormat.percent(bond.sharedReturn))
                                    .font(.subheadline.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(bond.sharedReturn >= 0 ? Color.kkanbuUp : Color.kkanbuDown)
                            }
                            .padding(.vertical, 10)
                            .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                        }
                    }
                }
            }
        }
    }

    private var pending: some View {
        let open = store.state.proposals.filter { $0.groupId == group.id && $0.status == .open }
        return Group {
            if !open.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(open) { proposal in
                        ProposalCard(proposal: proposal, onRegister: { stock in
                            addPrefill = stock
                        })
                    }
                }
            }
        }
    }

    private var friendsStocks: some View {
        let rows = GroupSocial.memberHoldings(in: group.id, state: store.state)
            .filter { $0.1.status == .holding && $0.0.id != store.state.currentUserId }
        return Group {
            if !rows.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rows.prefix(8), id: \.1.id) { user, holding in
                        if let stock = store.state.stock(holding.stockId) {
                            VStack(alignment: .leading, spacing: 8) {
                                NavigationLink {
                                    FriendDetailView(user: user, group: group)
                                } label: {
                                    HoldingCardView(
                                        stock: stock,
                                        holding: holding,
                                        currentPrice: store.price(for: stock.id),
                                        partners: [],
                                        grade: nil,
                                        showsQuantity: user.shareQuantity,
                                        isMine: false,
                                        ownerName: user.nickname,
                                        showsPulse: false
                                    )
                                }
                                .buttonStyle(.plain)
                                PulseStrip(snapshot: store.pulseSnapshot(for: stock, in: group.id), stock: stock)
                            }
                        }
                    }
                }
            }
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 12) {
            let events = store.state.events.filter { $0.groupId == group.id }
            if events.isEmpty {
                EmptyStateView(title: "아직 기록이 없습니다", message: "주식을 넣거나 친구를 초대하면 시작됩니다.")
            } else {
                ForEach(Array(events.prefix(12))) { event in
                    EventRow(
                        event: event,
                        relative: MoneyFormat.relative(event.createdAt),
                        actorName: event.actorId.map { store.state.nickname($0) } ?? "",
                                onTap: event.opensRecommendationThread ? event.stockId.flatMap { store.state.stock($0) }.map { stock in { threadStock = stock } } : nil
                    )
                }
            }
        }
    }
}

struct ProposalCard: View {
    @Environment(AppStore.self) private var store
    var proposal: StockProposal
    var onRegister: ((Stock) -> Void)? = nil

    var body: some View {
        let stock = store.state.stock(proposal.stockId)
        let promised = store.state.coBuys.filter { $0.proposalId == proposal.id && $0.status != .declined }
        let mine = promised.contains { $0.userId == store.state.currentUserId }
        KkanbuCard(padding: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("매수 제안 · \(store.state.nickname(proposal.proposerId))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KkanbuTheme.faint)
                HStack(spacing: 10) {
                    if let stock {
                        StockMark(ticker: stock.ticker, name: stock.name, size: 36)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stock?.name ?? "")
                            .font(.subheadline.weight(.semibold))
                        if let stock {
                            PulseStrip(snapshot: pulse(for: stock), stock: stock)
                        }
                    }
                }
                Text(proposal.message)
                    .font(.footnote)
                    .foregroundStyle(KkanbuTheme.muted)
                Text("관심 \(promised.count)명 · \(promised.compactMap { store.state.nickname($0.userId) }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
                VStack(spacing: 8) {
                    if mine, proposal.proposerId == store.state.currentUserId {
                        QuietButton(title: "다시 제안", kind: .secondary) { store.nag(proposalId: proposal.id) }
                    } else if !mine {
                        QuietButton(title: "관심 있음") { store.promiseCoBuy(proposalId: proposal.id) }
                        QuietButton(title: "패스", kind: .secondary) { store.declineProposal(proposal.id) }
                    }
                }
            }
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
        }
    }

    private func pulse(for stock: Stock) -> StockPulse.Snapshot {
        store.pulseSnapshot(for: stock, in: proposal.groupId)
    }
}

struct CreateGroupSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = "우리 주식팟"

    var body: some View {
        NavigationStack {
            Form {
                TextField("그룹 이름", text: $name)
            }
            .navigationTitle("그룹 만들기")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("만들기") {
                        store.createGroup(name: name)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
            }
        }
    }
}

struct JoinGroupSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("초대 코드", text: $code)
                    .textInputAutocapitalization(.characters)
                Text("비공개 그룹이라 코드가 있어야 들어갈 수 있어요.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("그룹 참여")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("참여") {
                        if store.joinGroup(code: code) { dismiss() }
                    }
                }
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
            }
        }
    }
}

struct GroupSwitchSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(store.state.groups(for: store.state.currentUserId)) { group in
                Button {
                    store.selectGroup(group.id)
                    dismiss()
                } label: {
                    HStack {
                        Text(group.name)
                        Spacer()
                        if group.id == store.state.selectedGroupId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("내 그룹")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
        }
    }
}
