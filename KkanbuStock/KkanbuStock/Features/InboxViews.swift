import SwiftUI
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(UIKit)
import UIKit
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
                        Text("매수 예정")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.faint)
                        HStack(spacing: 10) {
                            StockMark(ticker: stock.ticker, name: stock.name, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(sender) · \(stock.name)")
                                    .font(.body.weight(.semibold))
                                Text(stock.ticker)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(KkanbuTheme.faint)
                                PulseStrip(snapshot: pulse(for: stock), stock: stock)
                                SignalChips(labels: rec.signals)
                            }
                        }
                        VStack(spacing: 8) {
                            QuietButton(title: "매수가 기록") { onRegister(stock) }
                            QuietButton(title: "취소", kind: .secondary) { store.resolveRecommendation(rec.id, accept: false) }
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
                                Text("\(sender) · \(stock.name)")
                                    .font(.body.weight(.semibold))
                                Text(stock.ticker)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(KkanbuTheme.faint)
                                PulseStrip(snapshot: pulse(for: stock), stock: stock)
                                SignalChips(labels: rec.signals)
                            }
                        }
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
                    Text(item.kind == .nag ? "매수 제안 · 재요청" : "매수 제안")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.faint)
                    HStack(spacing: 10) {
                        StockMark(ticker: stock.ticker, name: stock.name, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(store.state.nickname(proposal.proposerId)) · \(stock.name)")
                                .font(.body.weight(.semibold))
                            Text(stock.ticker)
                                .font(.caption.monospaced())
                                .foregroundStyle(KkanbuTheme.faint)
                        }
                    }
                    VStack(spacing: 8) {
                        QuietButton(title: "관심 있음") { store.promiseCoBuy(proposalId: proposal.id) }
                        QuietButton(title: "패스", kind: .secondary) { store.declineProposal(proposal.id) }
                        threadButton(stock)
                    }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
            }
        case .suspect, .reverify:
            if let holding = item.holding, let stock = store.state.stock(holding.stockId) {
                let isSell = holding.status == .sold
                let title: String
                if item.kind == .reverify {
                    title = isSell ? "매도가 인증" : "평단 재인증"
                } else {
                    title = "매수가 확인 요청"
                }
                let price = MoneyFormat.price(holding.verificationPrice, market: stock.market)
                let blurb = isSell
                    ? "\(price)에 판 기록이 맞는지 캡처로 확인합니다. 사기라고 단정하지 않습니다."
                    : "\(price)에 산 기록이 맞는지 캡처로 확인합니다. 사기라고 단정하지 않습니다."
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
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
                    Text(blurb)
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    QuietButton(title: isSell ? "매도가 인증" : "캡처로 인증") { onVerify(holding) }
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
        store.pulseSnapshot(for: stock, in: store.state.selectedGroupId)
    }
}

struct RecommendationThreadView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var stock: Stock
    @State private var draft = ""
    @State private var replyTo: StockComment?
    @State private var pendingJPEG: Data?
    @State private var pickerItem: PhotosPickerItem?
    @State private var viewerIndex: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    history
                    photoRail
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
            .fullScreenCover(item: viewerBinding) { item in
                CommentPhotoPager(photos: threadPhotos, index: item)
            }
        }
    }

    private var groupId: UUID? { store.state.selectedGroupId }

    private var threadItems: [StockComment] {
        groupId.map { store.comments(in: $0, stockId: stock.id) } ?? []
    }

    private var threadPhotos: [CommentPhotoItem] {
        threadItems.compactMap { comment in
            guard let data = comment.imageJPEG, let image = platformImage(data) else { return nil }
            return CommentPhotoItem(
                id: comment.id,
                image: image,
                caption: comment.body.isEmpty ? store.state.nickname(comment.authorId) : "\(store.state.nickname(comment.authorId)) · \(comment.body)"
            )
        }
    }

    private var viewerBinding: Binding<CommentPhotoItem?> {
        Binding(
            get: {
                guard let viewerIndex, threadPhotos.indices.contains(viewerIndex) else { return nil }
                return threadPhotos[viewerIndex]
            },
            set: { viewerIndex = $0 == nil ? nil : viewerIndex }
        )
    }

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
            MiniChart(candles: store.history(for: stock, days: 40))
            if let rsi = ChartMath.snapshot(for: store.history(for: stock, days: 40)).rsi {
                Text("RSI \(Int(rsi.rounded())) · 데모 캔들입니다. 거래량·RSI 태그를 추천에 붙일 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
            } else {
                Text("데모 시세입니다. 차트 분석 캡처를 댓글에 넣을 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
            }
            if let url = ChartMath.tradingViewURL(for: stock) {
                Link("트레이딩뷰에서 보기", destination: url)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(KkanbuTheme.ink)
            }
            PulseStrip(snapshot: pulseSnapshot, compact: false, stock: stock)
        }
    }

    private var pulseSnapshot: StockPulse.Snapshot {
        store.pulseSnapshot(for: stock, in: groupId)
    }

    private var history: some View {
        let recs = groupId.map { store.recommendations(in: $0, stockId: stock.id) } ?? []
        let proposals = groupId.map { gid in
            store.state.proposals.filter { $0.groupId == gid && $0.stockId == stock.id }
        } ?? []
        return VStack(alignment: .leading, spacing: 8) {
            Text("이 종목 이야기")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KkanbuTheme.muted)
            if recs.isEmpty && proposals.isEmpty {
                Text("아직 추천이나 매수 제안이 없습니다.")
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
                        SignalChips(labels: rec.signals)
                        Text("\(rec.status.threadLabel) · \(MoneyFormat.relative(rec.createdAt))")
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                }
                ForEach(proposals) { proposal in
                    let promised = store.state.coBuys.filter { $0.proposalId == proposal.id && $0.status != .declined }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(store.state.nickname(proposal.proposerId)) · 매수 제안")
                            .font(.subheadline.weight(.semibold))
                        Text("“\(proposal.message)”")
                            .font(.footnote)
                            .foregroundStyle(KkanbuTheme.ink)
                        Text("관심 \(promised.count)명 · \(MoneyFormat.relative(proposal.createdAt))")
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                }
            }
        }
    }

    @ViewBuilder
    private var photoRail: some View {
        if !threadPhotos.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("사진 \(threadPhotos.count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(KkanbuTheme.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(threadPhotos.enumerated()), id: \.element.id) { index, photo in
                            Button {
                                viewerIndex = index
                            } label: {
                                Image(uiImage: photo.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 92, height: 92)
                                    .clipped()
                                    .background(KkanbuTheme.chip, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var comments: some View {
        let items = threadItems
        let roots = items.filter { $0.parentId == nil }
        return VStack(alignment: .leading, spacing: 8) {
            Text("댓글 \(items.count)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(KkanbuTheme.muted)
            if items.isEmpty {
                Text("아직 댓글이 없습니다. 차트 분석 사진이나 한마디를 남겨 보세요.")
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
            VStack(alignment: .leading, spacing: 6) {
                Text(store.state.nickname(comment.authorId))
                    .font(.caption.weight(.semibold))
                if !comment.body.isEmpty {
                    Text(comment.body)
                        .font(.subheadline)
                }
                if let data = comment.imageJPEG, let image = platformImage(data) {
                    Button {
                        if let idx = threadPhotos.firstIndex(where: { $0.id == comment.id }) {
                            viewerIndex = idx
                        }
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipped()
                            .background(KkanbuTheme.chip, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
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
            if let pendingJPEG, let image = platformImage(pendingJPEG) {
                HStack(alignment: .top) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipped()
                        .background(KkanbuTheme.chip, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Spacer()
                    Button("사진 빼기") { self.pendingJPEG = nil; pickerItem = nil }
                        .font(.caption.weight(.medium))
                }
            }
            HStack(alignment: .bottom, spacing: 8) {
                #if canImport(PhotosUI)
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(KkanbuTheme.ink)
                        .frame(width: 48, height: 48)
                }
                .onChange(of: pickerItem) { _, item in
                    Task { await loadPhoto(item) }
                }
                #endif
                Button {
                    attachChart()
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(KkanbuTheme.ink)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("차트 첨부")
                TextField(replyTo == nil ? "이 종목에 한마디" : "답글 적기", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 10)
                Button("보내기") { send() }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 48)
                    .disabled(!canSend)
            }
            .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(KkanbuTheme.bg)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingJPEG != nil
    }

    private func send() {
        store.addComment(stockId: stock.id, parentId: replyTo?.id, body: draft, imageJPEG: pendingJPEG)
        draft = ""
        replyTo = nil
        pendingJPEG = nil
        pickerItem = nil
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        pendingJPEG = CommentPhoto.jpeg(from: data)
    }

    private func attachChart() {
        #if canImport(UIKit)
        let candles = store.history(for: stock, days: 40)
        let last = candles.last?.close ?? store.price(for: stock.id)
        let rsi = ChartMath.snapshot(for: candles).rsi
        pendingJPEG = CommentPhoto.chartJPEG(
            candles: candles,
            title: "\(stock.name) · \(stock.ticker)",
            price: MoneyFormat.price(last, market: stock.market),
            rsiLabel: rsi.map { "RSI \(Int($0.rounded()))" }
        )
        #endif
    }

    private func platformImage(_ data: Data) -> UIImage? {
        #if canImport(UIKit)
        UIImage(data: data)
        #else
        nil
        #endif
    }
}

struct CommentPhotoItem: Identifiable {
    var id: UUID
    #if canImport(UIKit)
    var image: UIImage
    #else
    var image: Data
    #endif
    var caption: String
}

struct CommentPhotoPager: View {
    @Environment(\.dismiss) private var dismiss
    var photos: [CommentPhotoItem]
    var index: CommentPhotoItem
    @State private var current: UUID

    init(photos: [CommentPhotoItem], index: CommentPhotoItem) {
        self.photos = photos
        self.index = index
        _current = State(initialValue: index.id)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $current) {
                ForEach(photos) { photo in
                    VStack(spacing: 12) {
                        Spacer()
                        #if canImport(UIKit)
                        Image(uiImage: photo.image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .padding(.horizontal, 12)
                        #endif
                        Text(photo.caption)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                    .tag(photo.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            Button("닫기") { dismiss() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(16)
        }
    }
}
