import SwiftUI

struct HoldingsView: View {
    @Environment(AppStore.self) private var store
    @State private var showAdd = false
    @State private var recommendHolding: Holding?
    @State private var proposeStock: Stock?
    @State private var sellHolding: Holding?
    @State private var verifyHolding: Holding?
    @State private var showPropose = false

    var body: some View {
        NavigationStack {
            ZStack {
                KkanbuBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        DisclaimerBanner()
                        summary
                        let mine = store.state.holdings.filter { $0.userId == store.state.currentUserId }
                        let active = mine.filter { $0.status == .holding }
                        let sold = mine.filter { $0.status == .sold }
                        if mine.isEmpty {
                            EmptyStateView(title: "아직 주식이 없습니다", message: "종목을 넣으면 친구가 같은 걸 샀을 때 깐부가 됩니다.")
                            QuietButton(title: "주식 추가") { showAdd = true }
                            QuietButton(title: "같이 사기", kind: .secondary) { showPropose = true }
                        }
                        if !active.isEmpty {
                            Text("보유 중")
                                .font(.headline)
                            ForEach(active) { holding in
                                holdingBlock(holding)
                            }
                        }
                        if !sold.isEmpty {
                            Text("매도 기록")
                                .font(.headline)
                            ForEach(sold) { holding in
                                holdingBlock(holding)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("내 주식")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("같이 사기") { showPropose = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(KkanbuTheme.ink)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddStockView() }
            .sheet(item: $recommendHolding) { RecommendSheet(holding: $0) }
            .sheet(item: $proposeStock) { ProposalSheet(preselected: $0) }
            .sheet(item: $sellHolding) { SellSheet(holding: $0) }
            .sheet(item: $verifyHolding) { ScreenshotVerifySheet(holding: $0) }
            .sheet(isPresented: $showPropose) { ProposalSheet() }
        }
    }

    @ViewBuilder
    private func holdingBlock(_ holding: Holding) -> some View {
        if let stock = store.state.stock(holding.stockId) {
            HoldingCardView(
                stock: stock,
                holding: holding,
                currentPrice: store.price(for: stock.id),
                partners: partners(for: holding),
                grade: grade(for: holding),
                showsQuantity: store.state.currentUser.shareQuantity,
                isMine: true,
                onRecommend: { recommendHolding = holding },
                onPropose: nil,
                onSell: holding.status == .holding ? { sellHolding = holding } : nil,
                onVerify: { verifyHolding = holding }
            )
        }
    }

    private var summary: some View {
        let mine = store.state.activeHoldings(of: store.state.currentUserId)
        let avg = mine.isEmpty ? 0 : mine.map { $0.returnRate(currentPrice: store.price(for: $0.stockId)) }.reduce(0, +) / Double(mine.count)
        return KkanbuCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("평균 수익률")
                    .font(.footnote)
                    .foregroundStyle(KkanbuTheme.muted)
                ReturnText(value: avg, size: 28)
                Text("보유 \(mine.count)종목")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
            }
        }
    }

    private func partners(for holding: Holding) -> [String] {
        guard let groupId = store.state.selectedGroupId else { return [] }
        return KkangbuMath.bonds(in: groupId, state: store.state, prices: store.currentPrices)
            .filter { $0.stockId == holding.stockId && $0.members.contains(store.state.currentUserId) }
            .compactMap { store.state.nickname($0.partner(of: store.state.currentUserId)) }
    }

    private func grade(for holding: Holding) -> KkangbuGrade? {
        guard let groupId = store.state.selectedGroupId else { return nil }
        return KkangbuMath.bonds(in: groupId, state: store.state, prices: store.currentPrices)
            .first { $0.stockId == holding.stockId && $0.members.contains(store.state.currentUserId) }?
            .grade
    }
}

struct SellSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var holding: Holding
    @State private var priceText = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                if let stock = store.state.stock(holding.stockId) {
                    Text(stock.name)
                    Text("현재가 \(MoneyFormat.price(store.price(for: stock.id), market: stock.market))")
                    TextField("매도가", text: $priceText)
                        .keyboardType(.decimalPad)
                    DatePicker("매도일", selection: $date, displayedComponents: .date)
                    Text("매도해도 기록은 남아요. 혼자 튐, 선견지명, 너무 일찍 튐 같은 사건이 여기서 시작됩니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("매도하기")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("매도 처리") {
                        let value = Double(priceText.replacingOccurrences(of: ",", with: "")) ?? store.price(for: holding.stockId)
                        store.sellHolding(id: holding.id, sellPrice: value, sellDate: date)
                        dismiss()
                    }
                }
            }
            .onAppear {
                priceText = String(format: "%.2f", store.price(for: holding.stockId))
            }
        }
    }
}

struct RecommendSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var holding: Holding
    @State private var message = "같이 들어가 봐."
    @State private var selected: UUID?

    var body: some View {
        NavigationStack {
            Form {
                if let stock = store.state.stock(holding.stockId) {
                    Section("종목") {
                        Text("\(stock.name) · \(MoneyFormat.percent(holding.returnRate(currentPrice: store.price(for: stock.id))))")
                    }
                }
                Section("누구한테") {
                    Button("그룹 전체에게") {
                        store.recommendToGroup(holding: holding, message: message)
                        dismiss()
                    }
                    ForEach(friends, id: \.id) { user in
                        Button {
                            selected = user.id
                        } label: {
                            HStack {
                                Text("\(user.avatarEmoji) \(user.nickname)")
                                Spacer()
                                if selected == user.id { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }
                Section("메시지") {
                    TextField("한마디", text: $message, axis: .vertical)
                }
            }
            .navigationTitle("추천하기")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("보내기") {
                        if let selected {
                            store.recommend(holding: holding, to: selected, message: message)
                            dismiss()
                        }
                    }
                    .disabled(selected == nil)
                }
            }
        }
    }

    private var friends: [User] {
        guard let groupId = store.state.selectedGroupId else { return [] }
        return store.state.memberUsers(of: groupId).filter { $0.id != store.state.currentUserId }
    }
}

struct ProposalSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var preselected: Stock?
    @State private var query = ""
    @State private var stock: Stock?
    @State private var message = "이번에 같이 들어갈 사람?"

    var body: some View {
        NavigationStack {
            Form {
                Section("아직 안 산 종목") {
                    TextField("종목 검색", text: $query)
                    ForEach(Array(store.searchStocks(query).prefix(8))) { item in
                        Button("\(item.name) \(item.ticker)") { stock = item }
                    }
                    if let stock {
                        Text("선택됨: \(stock.name)")
                            .foregroundStyle(KkanbuTheme.ink)
                    }
                }
                Section("메시지") {
                    TextField("제안", text: $message, axis: .vertical)
                    Text("추천은 이미 보유한 종목, 같이 사기는 아직 안 산 종목을 제안합니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("같이 사기")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("제안") {
                        if let stock {
                            store.propose(stock: stock, message: message)
                            dismiss()
                        }
                    }
                    .disabled(stock == nil)
                }
            }
            .onAppear { stock = preselected }
        }
    }
}
