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
                let sender = store.state.nickname(rec.senderId)
                if rec.status == .willBuy {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("살게요 · 아직 안 삼")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.faint)
                        Text("\(sender)가 추천한 \(stock.name)")
                            .font(.body.weight(.semibold))
                        Text(stock.ticker)
                            .font(.caption.monospaced())
                            .foregroundStyle(KkanbuTheme.faint)
                        Text("사겠다고 한 다음 단계입니다. 샀으면 매수가를 적으세요. 버튼을 눌러도 주문이 나가지 않습니다.")
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                        VStack(spacing: 8) {
                            QuietButton(title: "샀어요 · 매수가 적기") { onRegister(stock) }
                            QuietButton(title: "마음 바뀜", kind: .secondary) { store.resolveRecommendation(rec.id, accept: false) }
                        }
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("추천")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(KkanbuTheme.faint)
                        Text("\(sender)가 \(stock.name)를 추천함")
                            .font(.body.weight(.semibold))
                        Text(stock.ticker)
                            .font(.caption.monospaced())
                            .foregroundStyle(KkanbuTheme.faint)
                        Text("살게요는 약속입니다. 산 뒤에 매수가를 적습니다. 버튼을 눌러도 주문이 나가지 않습니다.")
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                        VStack(spacing: 8) {
                            QuietButton(title: "살게요") { store.resolveRecommendation(rec.id, accept: true) }
                            QuietButton(title: "안 살게", kind: .secondary) { store.resolveRecommendation(rec.id, accept: false) }
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
                    Text(stock.ticker)
                        .font(.caption.monospaced())
                        .foregroundStyle(KkanbuTheme.faint)
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
}
