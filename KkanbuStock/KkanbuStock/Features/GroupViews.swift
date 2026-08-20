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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                members
                pending
                feed
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showRank) {
            RankingsView(group: group)
        }
    }

    private var header: some View {
        KkanbuCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(group.moodEmoji) \(group.name)")
                    .font(.title.bold())
                Text("초대 코드 \(group.inviteCode)")
                    .font(.headline.monospaced())
                    .foregroundStyle(KkanbuTheme.coral)
                Text("친구가 뭐 했는지가 주인공이에요. 숫자는 장난감입니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    PillButton(title: "칭호 랭킹", systemImage: "crown") { showRank = true }
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

    private var members: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.state.memberUsers(of: group.id)) { user in
                    NavigationLink {
                        FriendDetailView(user: user, group: group)
                    } label: {
                        VStack(spacing: 8) {
                            AvatarView(emoji: user.avatarEmoji, size: 58)
                            Text(user.nickname)
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
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
                        ProposalCard(proposal: proposal)
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

    var body: some View {
        let stock = store.state.stock(proposal.stockId)
        let promised = store.state.coBuys.filter { $0.proposalId == proposal.id && $0.status != .declined }
        let mine = promised.contains { $0.userId == store.state.currentUserId }
        KkanbuCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("🤔 \(store.state.nickname(proposal.proposerId)) · \(stock?.name ?? "")")
                    .font(.headline)
                Text(proposal.message)
                    .foregroundStyle(.secondary)
                Text("같이 사기 \(promised.count)명")
                    .font(.subheadline.bold())
                HStack {
                    if mine {
                        if proposal.proposerId == store.state.currentUserId {
                            PillButton(title: "조르기", kind: .secondary) { store.nag(proposalId: proposal.id) }
                        } else {
                            Text("약속함")
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
