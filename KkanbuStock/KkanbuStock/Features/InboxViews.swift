import SwiftUI
#if canImport(UserNotifications)
import UserNotifications
#endif

enum LocalPush {
    static func requestPermission() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        #endif
    }

    static func post(_ payload: PushPayload) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.3, repeats: false)
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        #endif
    }
}

struct InboxActionCard: View {
    @Environment(AppStore.self) private var store
    var item: InboxItem
    var onVerify: (Holding) -> Void
    var onRegister: (Stock) -> Void
    var onOpenThread: ((Stock) -> Void)? = nil

    var body: some View {
        switch item.kind {
        case .recommend:
            if let rec = item.recommendation, let stock = store.state.stock(rec.stockId) {
                let sender = store.state.nickname(rec.senderId)
                if rec.status == .willBuy {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("살게요 · 아직 안 삼")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.faint)
                        HStack(spacing: 10) {
                            StockMark(ticker: stock.ticker, name: stock.name, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(sender)가 추천한 \(stock.name)")
                                    .font(.body.weight(.semibold))
                                Text(stock.ticker)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(KkanbuTheme.faint)
                                PulseStrip(snapshot: pulse(for: stock))
                            }
                        }
                        Text("사겠다고 한 다음 단계입니다. 샀으면 매수가를 적으세요. 버튼을 눌러도 주문이 나가지 않습니다.")
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                        VStack(spacing: 8) {
                            QuietButton(title: "샀어요 · 매수가 적기") { onRegister(stock) }
                            QuietButton(title: "마음 바뀜", kind: .secondary) { store.resolveRecommendation(rec.id, accept: false) }
                            threadButton(stock)
                        }
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("추천")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.faint)
                        HStack(spacing: 10) {
                            StockMark(ticker: stock.ticker, name: stock.name, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(sender)가 \(stock.name)를 추천함")
                                    .font(.body.weight(.semibold))
                                Text(stock.ticker)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(KkanbuTheme.faint)
                                PulseStrip(snapshot: pulse(for: stock))
                            }
                        }
                        Text("살게요는 약속입니다. 산 뒤에 매수가를 적습니다. 버튼을 눌러도 주문이 나가지 않습니다.")
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                        VStack(spacing: 8) {
                            QuietButton(title: "살게요") { store.resolveRecommendation(rec.id, accept: true) }
                            QuietButton(title: "안 살게", kind: .secondary) { store.resolveRecommendation(rec.id, accept: false) }
                            threadButton(stock)
                        }
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                }
            }
        case .proposal, .nag:
            if let proposal = item.proposal, let stock = store.state.stock(proposal.stockId) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.kind == .nag ? "그룹이 다시 조름" : "그룹 제안")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.faint)
                    Text("\(store.state.nickname(proposal.proposerId))가 그룹에 \(stock.name) 같이 사자고 함")
                        .font(.body.weight(.semibold))
                    HStack(spacing: 8) {
                        StockMark(ticker: stock.ticker, name: stock.name, size: 28)
                        Text(stock.ticker)
                            .font(.caption.monospaced())
                            .foregroundStyle(KkanbuTheme.faint)
                    }
                    Text("친구 한 명 추천이 아닙니다. 그룹 전체에 아직 안 산 종목을 제안한 겁니다.")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    VStack(spacing: 8) {
                        QuietButton(title: "관심 있음") { store.promiseCoBuy(proposalId: proposal.id) }
                        QuietButton(title: "패스", kind: .secondary) { store.declineProposal(proposal.id) }
                    }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
            }
        case .suspect:
            if let holding = item.holding, let stock = store.state.stock(holding.stockId) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("매수가 확인 요청")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.faint)
                    HStack(spacing: 10) {
                        StockMark(ticker: stock.ticker, name: stock.name, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stock.name)
                                .font(.body.weight(.semibold))
                            Text(stock.ticker)
                                .font(.caption.monospaced())
                                .foregroundStyle(KkanbuTheme.faint)
                        }
                    }
                    Text("\(MoneyFormat.price(holding.averagePrice, market: stock.market))에 산 기록이 맞는지 캡처로 확인합니다. 사기라고 단정하지 않습니다.")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    QuietButton(title: "캡처로 인증") { onVerify(holding) }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
            }
        case .cobuyRegister:
            if let proposal = item.proposal, let stock = store.state.stock(proposal.stockId) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("약속 완료 · 보유 등록 전")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.faint)
                    HStack(spacing: 10) {
                        StockMark(ticker: stock.ticker, name: stock.name, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stock.name)
                                .font(.body.weight(.semibold))
                            Text(stock.ticker)
                                .font(.caption.monospaced())
                                .foregroundStyle(KkanbuTheme.faint)
                        }
                    }
                    Text("아직 매수한 것이 아닙니다. 내가 이 종목을 사면 내 주식에서 기록합니다.")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    QuietButton(title: "확인", kind: .secondary) { }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
            }
        }
    }

    @ViewBuilder
    private func threadButton(_ stock: Stock) -> some View {
        if let onOpenThread, let groupId = store.state.selectedGroupId {
            let count = store.commentCount(in: groupId, stockId: stock.id)
            Button {
                onOpenThread(stock)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.right")
                    Text(count == 0 ? "댓글" : "\(count)")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(KkanbuTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
    }

    private func pulse(for stock: Stock) -> StockPulse.Snapshot {
        let gid = store.state.selectedGroupId
        let comments = gid.map { store.commentCount(in: $0, stockId: stock.id) } ?? 0
        let pending = store.state.recommendations.filter {
            $0.stockId == stock.id && ($0.status == .pending || $0.status == .willBuy)
        }.count
        let shared = gid.flatMap { id in
            KkangbuMath.bonds(in: id, state: store.state, prices: store.currentPrices)
                .first { $0.stockId == stock.id }?.sharedReturn
        }
        return StockPulse.snapshot(
            ticker: stock.ticker,
            commentCount: comments,
            pendingRecommendations: pending,
            sharedReturn: shared
        )
    }
}

struct RecommendationThreadView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var stock: Stock
    @State private var draft = ""
    @State private var replyTo: StockComment?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    history
                    comments
                }
                .padding(16)
            }
            .safeAreaInset(edge: .bottom) { composer }
            .navigationTitle(stock.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
            }
        }
    }

    private var groupId: UUID? { store.state.selectedGroupId }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                StockMark(ticker: stock.ticker, name: stock.name, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(stock.name)
                        .font(.title3.weight(.semibold))
                    Text(stock.ticker)
                        .font(.caption.monospaced())
                        .foregroundStyle(KkanbuTheme.faint)
                }
            }
            PulseStrip(snapshot: pulseSnapshot, compact: false)
        }
    }

    private var pulseSnapshot: StockPulse.Snapshot {
        let comments = groupId.map { store.commentCount(in: $0, stockId: stock.id) } ?? 0
        let pending = store.state.recommendations.filter {
            $0.stockId == stock.id && ($0.status == .pending || $0.status == .willBuy)
        }.count
        let shared = groupId.flatMap { gid in
            KkangbuMath.bonds(in: gid, state: store.state, prices: store.currentPrices)
                .first { $0.stockId == stock.id }?.sharedReturn
        }
        return StockPulse.snapshot(
            ticker: stock.ticker,
            commentCount: comments,
            pendingRecommendations: pending,
            sharedReturn: shared
        )
    }

    private var history: some View {
        let recs = groupId.map { store.recommendations(in: $0, stockId: stock.id) } ?? []
        return VStack(alignment: .leading, spacing: 8) {
            Text("추천 히스토리")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KkanbuTheme.muted)
            if recs.isEmpty {
                Text("아직 이 종목을 추천한 기록이 없습니다.")
                    .font(.footnote)
                    .foregroundStyle(KkanbuTheme.faint)
            } else {
                ForEach(recs) { rec in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(store.state.nickname(rec.senderId)) → \(store.state.nickname(rec.receiverId))")
                            .font(.subheadline.weight(.semibold))
                        Text("“\(rec.message)”")
                            .font(.footnote)
                            .foregroundStyle(KkanbuTheme.ink)
                        Text("\(rec.status.threadLabel) · \(MoneyFormat.relative(rec.createdAt))")
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                }
            }
        }
    }

    private var comments: some View {
        let items = groupId.map { store.comments(in: $0, stockId: stock.id) } ?? []
        let roots = items.filter { $0.parentId == nil }
        return VStack(alignment: .leading, spacing: 8) {
            Text("댓글 \(items.count)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KkanbuTheme.muted)
            if items.isEmpty {
                Text("아직 댓글이 없습니다. 이 추천에 한마디 남겨 보세요.")
                    .font(.footnote)
                    .foregroundStyle(KkanbuTheme.faint)
                    .padding(.vertical, 8)
            } else {
                ForEach(roots) { comment in
                    commentBlock(comment)
                    ForEach(items.filter { $0.parentId == comment.id }) { reply in
                        commentBlock(reply, isReply: true)
                    }
                }
            }
        }
    }

    private func commentBlock(_ comment: StockComment, isReply: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if isReply { Color.clear.frame(width: 18) }
            InitialsAvatar(name: store.state.nickname(comment.authorId), size: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.state.nickname(comment.authorId))
                    .font(.caption.weight(.semibold))
                Text(comment.body)
                    .font(.subheadline)
                HStack(spacing: 10) {
                    Text(MoneyFormat.relative(comment.createdAt))
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    if !isReply {
                        Button("답글") { replyTo = comment }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(KkanbuTheme.ink)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let replyTo {
                HStack {
                    Text("\(store.state.nickname(replyTo.authorId))에게 답글")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.muted)
                    Spacer()
                    Button("취소") { self.replyTo = nil }
                        .font(.caption.weight(.medium))
                }
            }
            HStack(spacing: 8) {
                TextField(replyTo == nil ? "이 추천에 한마디" : "답글 적기", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 10)
                Button("보내기") { send() }
                    .font(.subheadline.weight(.semibold))
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(KkanbuTheme.bg)
    }

    private func send() {
        store.addComment(stockId: stock.id, parentId: replyTo?.id, body: draft)
        draft = ""
        replyTo = nil
    }
}
