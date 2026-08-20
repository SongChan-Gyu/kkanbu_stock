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

    var body: some View {
        switch item.kind {
        case .recommend:
            if let rec = item.recommendation, let stock = store.state.stock(rec.stockId) {
                let holding = store.state.holding(rec.holdingId)
                VStack(alignment: .leading, spacing: 6) {
                    Text("친구가 이미 보유한 종목")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.faint)
                    HStack(spacing: 5) {
                        Text(stock.name)
                            .font(.body.weight(.semibold))
                        if let holding {
                            VerificationBadge(state: holding.verificationState)
                        }
                    }
                    Text("\(stock.ticker) · \(store.state.nickname(rec.senderId))")
                        .font(.caption.monospaced())
                        .foregroundStyle(KkanbuTheme.faint)
                    if let holding {
                        Text("평단 \(MoneyFormat.price(holding.averagePrice, market: stock.market)) · \(MoneyFormat.percent(holding.returnRate(currentPrice: store.price(for: stock.id))))")
                            .font(.footnote)
                            .foregroundStyle(KkanbuTheme.muted)
                    }
                    Text("같은 종목을 내 보유로 등록하면 \(store.state.nickname(rec.senderId))와 깐부가 됩니다.")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    HStack {
                        QuietButton(title: "같은 종목 등록") { store.resolveRecommendation(rec.id, accept: true) }
                        QuietButton(title: "나중에", kind: .secondary) { store.resolveRecommendation(rec.id, accept: false) }
                    }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
            }
        case .proposal, .nag:
            if let proposal = item.proposal, let stock = store.state.stock(proposal.stockId) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.kind == .nag ? "같이 사자고 다시 요청" : "아직 안 산 종목을 같이 사자는 제안")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.faint)
                    Text(stock.name)
                        .font(.body.weight(.semibold))
                    Text("\(stock.ticker) · \(store.state.nickname(proposal.proposerId))")
                        .font(.caption.monospaced())
                        .foregroundStyle(KkanbuTheme.faint)
                    Text("지금은 참여 약속만 합니다. 이후 실제로 등록해야 깐부가 됩니다.")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    HStack {
                        QuietButton(title: "같이 살게요") { store.promiseCoBuy(proposalId: proposal.id) }
                        QuietButton(title: "나중에", kind: .secondary) { store.declineProposal(proposal.id) }
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
                    Text(stock.name)
                        .font(.body.weight(.semibold))
                    Text(stock.ticker)
                        .font(.caption.monospaced())
                        .foregroundStyle(KkanbuTheme.faint)
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
                    Text(stock.name)
                        .font(.body.weight(.semibold))
                    Text(stock.ticker)
                        .font(.caption.monospaced())
                        .foregroundStyle(KkanbuTheme.faint)
                    Text("약속만으로는 깐부가 되지 않습니다. \(stock.name)를 내 보유로 등록하세요.")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.faint)
                    QuietButton(title: "\(stock.name) 등록") { onRegister(stock) }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
            }
        }
    }
}
