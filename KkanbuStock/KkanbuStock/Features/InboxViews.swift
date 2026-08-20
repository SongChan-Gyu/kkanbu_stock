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
                        Text("📣 \(store.state.nickname(rec.senderId))가 \(stock.name)를 추천했어요")
                            .font(.headline)
                        if let holding = store.state.holding(rec.holdingId) {
                            Text("\(store.state.nickname(rec.senderId)) 평단 \(MoneyFormat.price(holding.averagePrice, market: stock.market)) · \(MoneyFormat.percent(holding.returnRate(currentPrice: store.price(for: stock.id))))")
                                .font(.subheadline)
                        }
                        Text("“\(rec.message)”")
                        HStack {
                            PillButton(title: "나도 추가하기") { store.resolveRecommendation(rec.id, accept: true) }
                            PillButton(title: "나중에", kind: .secondary) { store.resolveRecommendation(rec.id, accept: false) }
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
                            PillButton(title: "🤝 같이 사자") { store.promiseCoBuy(proposalId: proposal.id) }
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
                            .font(.subheadline)
                        Text("사기라고 단정하지 않아요. 캡처로 확인만 하면 됩니다.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        PillButton(title: "📸 캡처로 인증하기") { onVerify(holding) }
                    }
                }
            case .nag:
                if let proposal = item.proposal {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("😂 같이 사자고 또 찔렀어요")
                            .font(.headline)
                        Text(proposal.message)
                        HStack {
                            PillButton(title: "같이 사기") { store.promiseCoBuy(proposalId: proposal.id) }
                            PillButton(title: "나중에", kind: .secondary) { store.declineProposal(proposal.id) }
                        }
                    }
                }
            case .cobuyRegister:
                if let proposal = item.proposal, let stock = store.state.stock(proposal.stockId) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🤝 약속만 하고 아직 등록 전")
                            .font(.headline)
                        Text("\(stock.name)를 실제로 넣어야 깐부가 됩니다.")
                        PillButton(title: "지금 등록하기") { onRegister(stock) }
                    }
                }
            }
        }
    }
}
