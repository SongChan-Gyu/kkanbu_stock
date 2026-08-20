import SwiftUI
import Charts
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

struct AddStockView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var prefill: Stock? = nil
    @State private var query = ""
    @State private var selected: Stock?
    @State private var priceText = ""
    @State private var quantityText = ""
    @State private var date = Date()
    @State private var showChart = false
    @State private var showOCR = false
    @State private var method: InputMethod = .manual

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(prefill == nil
                         ? "내가 산 종목을 기록합니다. 버튼을 눌러도 주문이 나가지 않습니다."
                         : "추천받은 종목입니다. 샀으면 내가 산 가격을 적으세요. 현재가로 채우지 않습니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        showOCR = true
                    } label: {
                        Label("📷 캡처로 추가", systemImage: "camera.viewfinder")
                    }
                }
                Section("종목") {
                    TextField("종목명, 티커, 코드", text: $query)
                    ForEach(Array(store.searchStocks(query).prefix(10))) { stock in
                        Button {
                            selected = stock
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(stock.name).foregroundStyle(.primary)
                                    Text("\(stock.ticker) · \(stock.market.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selected?.id == stock.id {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(KkanbuTheme.ink)
                                }
                            }
                        }
                    }
                }
                if let selected {
                    Section("매수가") {
                        TextField(selected.market == .krx ? "예: 72300" : "예: 163.40", text: $priceText)
                            .keyboardType(.decimalPad)
                        Button("차트에서 고르기") { showChart = true }
                        DatePicker("언제 샀나요?", selection: $date, displayedComponents: .date)
                    }
                    Section("선택") {
                        TextField("보유수량 (비공개 기본)", text: $quantityText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("주식 추가")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("등록") { save() }
                        .disabled(selected == nil || parsedPrice == nil)
                }
            }
            .sheet(isPresented: $showChart) {
                if let selected {
                    ChartPricePickerView(stock: selected, date: $date, priceText: $priceText)
                }
            }
            .sheet(isPresented: $showOCR) {
                ScreenshotAddView { stock, price, recognizedDate, verified in
                    selected = stock
                    query = stock.name
                    priceText = String(format: stock.market == .krx ? "%.0f" : "%.2f", price)
                    if let recognizedDate { date = recognizedDate }
                    method = .screenshot
                    if verified { save(verification: .screenshotVerified) }
                }
            }
            .onAppear {
                if let prefill {
                    selected = prefill
                    query = prefill.name
                }
            }
        }
    }

    private var parsedPrice: Double? {
        Double(priceText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: ""))
    }

    private func defaultPrice(_ stock: Stock) -> String {
        let value = store.price(for: stock.id)
        return String(format: stock.market == .krx ? "%.0f" : "%.2f", value)
    }

    private func save(verification: VerificationState = .unverified) {
        guard let selected, let price = parsedPrice else { return }
        let qty = Double(quantityText.replacingOccurrences(of: ",", with: ""))
        store.addHolding(
            stock: selected,
            averagePrice: price,
            quantity: qty,
            purchaseDate: date,
            method: method,
            verification: verification
        )
        dismiss()
    }
}

struct ChartPricePickerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var stock: Stock
    @Binding var date: Date
    @Binding var priceText: String
    @State private var selected: PricePoint?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("언제 샀나요?")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)
                Text("차트를 터치해서 그날의 가격을 고르세요. 정확한 값은 아래에서 고쳐도 돼요.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                Chart(store.history(for: stock)) { point in
                    LineMark(x: .value("날짜", point.date), y: .value("가격", point.price))
                        .foregroundStyle(KkanbuTheme.ink)
                    AreaMark(x: .value("날짜", point.date), y: .value("가격", point.price))
                        .foregroundStyle(KkanbuTheme.ink.opacity(0.12))
                    if let selected, Calendar.current.isDate(selected.date, inSameDayAs: point.date) {
                        PointMark(x: .value("날짜", point.date), y: .value("가격", point.price))
                            .foregroundStyle(KkanbuTheme.ink)
                            .symbolSize(80)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { _ in
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        if let date: Date = proxy.value(atX: value.location.x) {
                                            selected = nearest(to: date)
                                        }
                                    }
                            )
                    }
                }
                .frame(height: 260)
                .padding()
                .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal)

                if let selected {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(MoneyFormat.compactDate(selected.date))
                            .font(.headline)
                        Text(MoneyFormat.price(selected.price, market: stock.market))
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                    }
                    .padding(.horizontal)
                }
                TextField("정확한 가격 직접 입력", text: $priceText)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                PillButton(title: "이 가격으로 등록") {
                    if let selected {
                        date = selected.date
                        priceText = String(format: stock.market == .krx ? "%.0f" : "%.2f", parsedOverride ?? selected.price)
                    }
                    dismiss()
                }
                .padding()
                Spacer()
            }
            .background(KkanbuBackground())
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
            .onAppear {
                selected = store.history(for: stock).last
            }
        }
    }

    private var parsedOverride: Double? {
        Double(priceText.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: ""))
    }

    private func nearest(to date: Date) -> PricePoint? {
        store.history(for: stock).min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
}

struct ScreenshotAddView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var onConfirm: (Stock, Double, Date?, Bool) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var result: ScreenshotAnalysisResult?
    @State private var working = false
    @State private var editedPrice = ""
    @State private var sample = 0
    @State private var showCamera = false

    private let samples = [
        "NVDA\nNVIDIA\n평균매입가 $163.40\n$182.40\n+11.59%",
        "005930\n삼성전자\n매입단가 72,300원\n현재가 78,400원",
        "AAPL\nApple\nAverage Price $198.20\n$231.42"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("캡처는 편의 기능이에요. 원본 이미지는 친구에게 공개되지 않고, OCR로 필요한 정보만 뽑습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("앨범에서 고르기", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(KkanbuTheme.ink.opacity(0.15), in: RoundedRectangle(cornerRadius: 18))
                    }
                    #if canImport(UIKit)
                    Button {
                        showCamera = true
                    } label: {
                        Label("사진 촬영", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(KkanbuTheme.chip, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .sheet(isPresented: $showCamera) {
                        CameraPicker(
                            onImage: { data in Task { await analyze(data: data) } },
                            onClose: { showCamera = false }
                        )
                    }
                    #endif
                    Button("샘플 캡처로 테스트") {
                        sample = (sample + 1) % samples.count
                        result = store.analyzeText(samples[sample])
                        editedPrice = result?.recognizedPrice.map { String($0) } ?? ""
                    }
                    if working { ProgressView("글자를 읽고 있어요") }
                    if let result {
                        resultCard(result)
                    }
                }
                .padding()
            }
            .navigationTitle("캡처로 추가")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
            .onChange(of: pickerItem) { _, item in
                Task { await load(item) }
            }
        }
    }

    @ViewBuilder
    private func resultCard(_ result: ScreenshotAnalysisResult) -> some View {
        KkanbuCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("이렇게 인식했어요")
                    .font(.headline)
                Text("confidence \(Int(result.confidence * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if result.tooLow {
                    Text("글자가 너무 흐려요. 다시 촬영하거나 다른 이미지를 사용해 주세요.")
                        .foregroundStyle(KkanbuTheme.ink)
                } else {
                    Text("종목: \(result.recognizedName ?? "모름") \(result.recognizedTicker ?? "")")
                    TextField("매수가", text: $editedPrice)
                        .keyboardType(.decimalPad)
                    if result.needsUserConfirm {
                        Text("확신이 낮아서 자동 등록하지 않았어요. 맞는지 확인해 주세요.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        PillButton(title: "맞아요") {
                            guard let stock = result.matchedStock else { return }
                            let price = Double(editedPrice.replacingOccurrences(of: ",", with: "")) ?? result.recognizedPrice ?? 0
                            onConfirm(stock, price, result.recognizedDate, result.confidence >= 0.9 && result.priceConfidence >= 0.6)
                            dismiss()
                        }
                        PillButton(title: "다시 선택", kind: .secondary) {
                            self.result = nil
                        }
                    }
                }
                Text(result.rawText)
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func load(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        await analyze(data: data)
    }

    private func analyze(data: Data) async {
        working = true
        defer { working = false }
        var analyzer = StockScreenshotAnalyzer(parser: StockTextParser())
        #if canImport(Vision) && canImport(UIKit)
        analyzer.recognizer = VisionTextRecognizer()
        #endif
        if let analyzed = try? await analyzer.analyze(imageData: data, fallbackText: nil, catalog: store.state.stocks) {
            result = analyzed
            editedPrice = analyzed.recognizedPrice.map { String($0) } ?? ""
            if analyzed.tooLow {
                store.lastError = OCRError.lowConfidence.localizedDescription
            }
        }
    }
}

#if canImport(UIKit)
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (Data) -> Void
    var onClose: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImage: onImage, onClose: onClose) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (Data) -> Void
        let onClose: () -> Void
        init(onImage: @escaping (Data) -> Void, onClose: @escaping () -> Void) {
            self.onImage = onImage
            self.onClose = onClose
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onClose()
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.85) {
                onImage(data)
            }
            onClose()
        }
    }
}
#endif

struct ScreenshotVerifySheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var holding: Holding
    @State private var pickerItem: PhotosPickerItem?
    @State private var mismatch: (Double, Double)?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("친구에게 원본 캡처는 보여주지 않아요. 인증 배지만 올라갑니다.")
                    .foregroundStyle(.secondary)
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("캡처로 인증하기", systemImage: "camera.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(KkanbuTheme.chip, in: RoundedRectangle(cornerRadius: 8))
                }
                Button("샘플로 인증 테스트") {
                    if let stock = store.state.stock(holding.stockId) {
                        let text = "\(stock.ticker)\n\(stock.name)\n평균매입가 \(MoneyFormat.price(holding.averagePrice, market: stock.market))"
                        apply(store.analyzeText(text))
                    }
                }
                Button("일부러 다른 가격 샘플") {
                    if let stock = store.state.stock(holding.stockId) {
                        let fake = holding.averagePrice * 1.2
                        let text = "\(stock.ticker)\n\(stock.name)\n평균매입가 \(MoneyFormat.price(fake, market: stock.market))"
                        apply(store.analyzeText(text))
                    }
                }
                if let mismatch {
                    KkanbuCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🚨 입력한 정보와 캡처 정보가 다릅니다.")
                                .font(.headline)
                            Text("등록: \(mismatch.0)")
                            Text("캡처: \(mismatch.1)")
                            Text("시스템이 사기라고 단정하지 않아요.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            PillButton(title: "수정하기") {
                                store.updateHoldingPrice(id: holding.id, price: mismatch.1)
                                dismiss()
                            }
                            PillButton(title: "인증 취소", kind: .secondary) { dismiss() }
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("캡처 인증")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("닫기") { dismiss() } } }
            .onChange(of: pickerItem) { _, item in
                Task { await load(item) }
            }
        }
    }

    private func apply(_ analysis: ScreenshotAnalysisResult) {
        let before = holding.averagePrice
        store.applyScreenshotVerification(holdingId: holding.id, analysis: analysis)
        if store.state.holding(holding.id)?.verificationState == .mismatch, let ocr = analysis.recognizedPrice {
            mismatch = (before, ocr)
        } else {
            dismiss()
        }
    }

    private func load(_ item: PhotosPickerItem?) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self) else { return }
        var analyzer = StockScreenshotAnalyzer(parser: StockTextParser())
        #if canImport(Vision) && canImport(UIKit)
        analyzer.recognizer = VisionTextRecognizer()
        #endif
        if let analyzed = try? await analyzer.analyze(imageData: data, fallbackText: nil, catalog: store.state.stocks) {
            apply(analyzed)
        }
    }
}
