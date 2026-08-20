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
            EmptyStateView(emoji: "🤝", title: "아직 그룹이 없어요", message: "친구 주식팟을 만들거나 초대 코드로 들어가세요.")
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
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
    }

    private var header: some View {
        KkanbuCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(group.moodEmoji) \(group.name)")
                    .font(.title.bold())
                Text("초대 코드 \(group.inviteCode)")
                    .font(.headline.monospaced())
                    .foregroundStyle(KkanbuTheme.coral)
                Text("오늘 누가 튀었지?")
                    .font(.title3.weight(.heavy))
                HStack {
                    PillButton(title: "주식 추가", systemImage: "plus") { showAdd = true }
                    PillButton(title: "🤔 이거 어때?", kind: .secondary) { showPropose = true }
                }
                HStack {
                    PillButton(title: "칭호 랭킹", systemImage: "crown", kind: .secondary) { showRank = true }
                    ShareLink(item: "주식 깐부 초대 코드: \(group.inviteCode)") {
                        Text("초대하기")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.primary.opacity(0.08), in: Capsule())
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
                        Text("지금 제일 핫한 일")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.coral)
                        EventRow(event: event, relative: MoneyFormat.relative(event.createdAt))
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
                            AvatarView(emoji: user.avatarEmoji, size: 58)
                            Text(user.id == store.state.currentUserId ? "나" : user.nickname)
                                .font(.caption.bold())
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
                    Text("지금 깐부")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(pairs) { pair in
                                KkanbuCard(padding: 14) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("\(pair.grade.emoji) \(pair.grade.title)")
                                            .font(.headline)
                                        Text("\(store.state.nickname(pair.userA)) × \(store.state.nickname(pair.userB))")
                                        Text("\(pair.sharedCount)종목 · \(MoneyFormat.percent(pair.averageReturn))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 200, alignment: .leading)
                                }
                            }
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
                    Text("같이 사기 진행 중")
                        .font(.headline)
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
                    Text("친구들 주식")
                        .font(.headline)
                    ForEach(rows.prefix(8), id: \.1.id) { user, holding in
                        if let stock = store.state.stock(holding.stockId) {
                            NavigationLink {
                                FriendDetailView(user: user, group: group)
                            } label: {
                                HStack {
                                    Text(user.avatarEmoji)
                                    VStack(alignment: .leading) {
                                        Text("\(user.nickname) · \(stock.name)")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(MoneyFormat.percent(holding.returnRate(currentPrice: store.price(for: stock.id))))
                                            .foregroundStyle(holding.returnRate(currentPrice: store.price(for: stock.id)) >= 0 ? Color.kkanbuUp : Color.kkanbuDown)
                                    }
                                    Spacer()
                                    VerificationBadge(state: holding.verificationState)
                                }
                                .padding(12)
                                .background(.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
    }

    private var feed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("오늘 무슨 일이")
                .font(.title3.bold())
            let events = store.state.events.filter { $0.groupId == group.id }
            if events.isEmpty {
                EmptyStateView(emoji: "😴", title: "아직 사건이 없어요", message: "주식을 넣거나 친구를 초대하면 바로 이야기가 시작됩니다.")
            } else {
                ForEach(events) { event in
                    KkanbuCard(padding: 14) {
                        EventRow(event: event, relative: MoneyFormat.relative(event.createdAt))
                    }
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
        let alreadyHolding = stock.map { item in
            store.state.activeHoldings(of: store.state.currentUserId).contains(where: { $0.stockId == item.id })
        } ?? false
        KkanbuCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("🤔 \(store.state.nickname(proposal.proposerId)) · \(stock?.name ?? "")")
                    .font(.headline)
                Text(proposal.message)
                    .foregroundStyle(.secondary)
                Text("같이 사기 \(promised.count)명 · \(promised.compactMap { store.state.nickname($0.userId) }.joined(separator: ", "))")
                    .font(.subheadline.bold())
                HStack {
                    if mine {
                        if proposal.proposerId == store.state.currentUserId {
                            PillButton(title: "조르기", kind: .secondary) { store.nag(proposalId: proposal.id) }
                        }
                        if !alreadyHolding, let stock {
                            PillButton(title: "지금 등록") { onRegister?(stock) }
                        } else if alreadyHolding {
                            Text("등록됨")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        PillButton(title: "🤝 같이 사자") { store.promiseCoBuy(proposalId: proposal.id) }
                        PillButton(title: "나중에", kind: .secondary) { store.declineProposal(proposal.id) }
                    }
                }
            }
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
                        Text("\(group.moodEmoji) \(group.name)")
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
