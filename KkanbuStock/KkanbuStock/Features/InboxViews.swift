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
        KkanbuCard {
            switch item.kind {
            case .recommend:
                if let rec = item.recommendation, let stock = store.state.stock(rec.stockId) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(store.state.nickname(rec.senderId)) · \(stock.name) 추천")
                            .font(.subheadline.weight(.semibold))
                        if let holding = store.state.holding(rec.holdingId) {
                            Text("\(store.state.nickname(rec.senderId)) 평단 \(MoneyFormat.price(holding.averagePrice, market: stock.market)) · \(MoneyFormat.percent(holding.returnRate(currentPrice: store.price(for: stock.id))))")
                                .font(.footnote)
                                .foregroundStyle(KkanbuTheme.muted)
                        }
                        Text(rec.message)
                            .font(.footnote)
                        HStack {
                            QuietButton(title: "나도 추가") { store.resolveRecommendation(rec.id, accept: true) }
                            QuietButton(title: "나중에", kind: .secondary) { store.resolveRecommendation(rec.id, accept: false) }
                        }
                    }
                }
            case .proposal:
                if let proposal = item.proposal {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(store.state.nickname(proposal.proposerId)) · 같이 사기 제안")
                            .font(.subheadline.weight(.semibold))
                        Text(proposal.message)
                            .font(.footnote)
                            .foregroundStyle(KkanbuTheme.muted)
                        HStack {
                            QuietButton(title: "같이 사기") { store.promiseCoBuy(proposalId: proposal.id) }
                            QuietButton(title: "나중에", kind: .secondary) { store.declineProposal(proposal.id) }
                        }
                    }
                }
            case .suspect:
                if let holding = item.holding, let stock = store.state.stock(holding.stockId) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(stock.name) 매수가 의심")
                            .font(.subheadline.weight(.semibold))
                        Text("\(MoneyFormat.price(holding.averagePrice, market: stock.market))에 산 기록이 맞는지 확인해 주세요.")
                            .font(.footnote)
                        Text("사기라고 단정하지 않습니다.")
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                        QuietButton(title: "캡처로 인증") { onVerify(holding) }
                    }
                }
            case .nag:
                if let proposal = item.proposal {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("같이 사자고 조르는 중")
                            .font(.subheadline.weight(.semibold))
                        Text(proposal.message)
                            .font(.footnote)
                            .foregroundStyle(KkanbuTheme.muted)
                        HStack {
                            QuietButton(title: "같이 사기") { store.promiseCoBuy(proposalId: proposal.id) }
                            QuietButton(title: "나중에", kind: .secondary) { store.declineProposal(proposal.id) }
                        }
                    }
                }
            case .cobuyRegister:
                if let proposal = item.proposal, let stock = store.state.stock(proposal.stockId) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("약속만 하고 아직 미등록")
                            .font(.subheadline.weight(.semibold))
                        Text("\(stock.name)를 등록해야 깐부가 됩니다.")
                            .font(.footnote)
                            .foregroundStyle(KkanbuTheme.muted)
                        QuietButton(title: "지금 등록") { onRegister(stock) }
                    }
                }
            }
        }
    }
}
