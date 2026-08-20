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
            EmptyStateView(title: "아직 그룹이 없습니다", message: "그룹을 만들거나 초대 코드로 들어가세요.")
            PillButton(title: "그룹 만들기", systemImage: "plus") { showCreate = true }
                .padding(.horizontal, 32)
            PillButton(title: "초대 코드로 참여", kind: .secondary) { showJoin = true }
                .padding(.horizontal, 32)
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                myTurn
                hero
                members
                kkangbuStrip
                pending
                friendsStocks
                feed
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.name)
                .font(.title2.weight(.semibold))
            HStack {
                Text("초대 코드 \(group.inviteCode)")
                    .font(.caption.monospaced())
                    .foregroundStyle(KkanbuTheme.faint)
                Spacer()
                Button("코드 복사") { store.copyInviteCode(group.inviteCode) }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KkanbuTheme.ink)
            }
            HStack(spacing: 8) {
                QuietButton(title: "내 주식 등록") { showAdd = true }
                QuietButton(title: "같이 살 종목 제안", kind: .secondary) { showPropose = true }
            }
            Button("칭호 랭킹") { showRank = true }
                .font(.caption.weight(.medium))
                .foregroundStyle(KkanbuTheme.muted)
        }
        .padding(.bottom, 4)
    }

    private var myTurn: some View {
        let items = store.inboxItems(for: store.state.currentUserId)
        return Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("내 차례")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.muted)
                    Text("추천과 제안")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    ForEach(items) { item in
                        InboxActionCard(item: item, onVerify: { verifyHolding = $0 }, onRegister: { addPrefill = $0 })
                    }
                }
            }
        }
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
            HStack(spacing: 12) {
                ForEach(store.state.memberUsers(of: group.id)) { user in
                    NavigationLink {
                        FriendDetailView(user: user, group: group)
                    } label: {
                        VStack(spacing: 8) {
                            AvatarView(emoji: user.avatarEmoji, name: user.nickname, size: 40)
                            Text(user.id == store.state.currentUserId ? "나" : user.nickname)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
    }

    private var kkangbuStrip: some View {
        let pairs = KkangbuMath.pairSummaries(in: group.id, state: store.state, prices: store.currentPrices)
        return Group {
            if !pairs.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("깐부")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.muted)
                    ForEach(pairs) { pair in
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(store.state.nickname(pair.userA)) · \(store.state.nickname(pair.userB))")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(pair.sharedCount)종목 · \(pair.grade.title)")
                                    .font(.caption)
                                    .foregroundStyle(KkanbuTheme.muted)
                            }
                            Spacer()
                            Text(MoneyFormat.percent(pair.averageReturn))
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(pair.averageReturn >= 0 ? Color.kkanbuUp : Color.kkanbuDown)
                        }
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
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
                    Text("같이 살 종목")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.muted)
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
                    Text("친구 주식")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.muted)
                    ForEach(rows.prefix(8), id: \.1.id) { user, holding in
                        if let stock = store.state.stock(holding.stockId) {
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
                                    ownerName: user.nickname
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("활동")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KkanbuTheme.muted)
            let events = store.state.events.filter { $0.groupId == group.id }
            if events.isEmpty {
                EmptyStateView(title: "아직 기록이 없습니다", message: "주식을 넣거나 친구를 초대하면 시작됩니다.")
            } else {
                ForEach(events) { event in
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
                Text("\(store.state.nickname(proposal.proposerId)) · \(stock?.name ?? "")")
                    .font(.subheadline.weight(.semibold))
                Text(proposal.message)
                    .font(.footnote)
                    .foregroundStyle(KkanbuTheme.muted)
                Text("같이 사기 \(promised.count)명 · \(promised.compactMap { store.state.nickname($0.userId) }.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
                HStack {
                    if mine, proposal.proposerId == store.state.currentUserId {
                        QuietButton(title: "조르기", kind: .secondary) { store.nag(proposalId: proposal.id) }
                    } else if !mine {
                        QuietButton(title: "확인", kind: .secondary) { store.declineProposal(proposal.id) }
                    }
                }
            }
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
        }
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
