import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum KkanbuHaptic {
    static func tap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

enum KkanbuTheme {
    static let radius: CGFloat = 10
    static let pagePadding: CGFloat = 20

    static let bg = Color(red: 0.980, green: 0.980, blue: 0.980)
    static let surface = Color.white
    static let ink = Color(red: 0.067, green: 0.067, blue: 0.067)
    static let muted = Color(red: 0.42, green: 0.447, blue: 0.502)
    static let faint = Color(red: 0.612, green: 0.639, blue: 0.686)
    static let line = Color(red: 0.925, green: 0.933, blue: 0.941)
    static let chip = Color(red: 0.953, green: 0.957, blue: 0.965)
}

extension Color {
    static let kkanbuUp = Color(red: 0.882, green: 0.114, blue: 0.282)
    static let kkanbuDown = Color(red: 0.145, green: 0.388, blue: 0.922)

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct KkanbuBackground: View {
    var body: some View {
        KkanbuTheme.bg.ignoresSafeArea()
    }
}

struct BrandMark: View {
    var size: CGFloat = 56

    var body: some View {
        let diameter = size * 0.62
        ZStack {
            Circle()
                .fill(KkanbuTheme.ink)
                .frame(width: diameter, height: diameter)
                .offset(x: -diameter * 0.28)
            Circle()
                .fill(Color.kkanbuUp)
                .frame(width: diameter, height: diameter)
                .offset(x: diameter * 0.28)
        }
        .frame(width: size, height: size * 0.72)
        .accessibilityHidden(true)
    }
}

struct InitialsAvatar: View {
    var name: String
    var size: CGFloat = 36

    private var initial: String {
        String(name.trimmingCharacters(in: .whitespaces).prefix(1))
    }

    private var tint: Color {
        let palettes: [Color] = [
            Color(hex: "405DE6"),
            Color(hex: "C13584"),
            Color(hex: "F77737"),
            Color(hex: "833AB4"),
            Color(hex: "1FA2F1"),
            Color(hex: "2BB673")
        ]
        let sum = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palettes[sum % palettes.count]
    }

    var body: some View {
        Text(initial)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(tint, in: Circle())
    }
}

struct AvatarView: View {
    var emoji: String
    var name: String = ""
    var size: CGFloat = 52

    var body: some View {
        InitialsAvatar(name: name.isEmpty ? emoji : name, size: size)
    }
}

struct StockMark: View {
    var ticker: String
    var name: String = ""
    var size: CGFloat = 40

    var body: some View {
        let mark = StockIdentity.mark(ticker: ticker, name: name)
        ZStack {
            Circle().fill(Color(hex: mark.backgroundHex))
            if let url = StockIdentity.logoURL(ticker: ticker) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.22)
                    default:
                        glyph(mark)
                    }
                }
            } else {
                glyph(mark)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(name.isEmpty ? ticker : name)
    }

    private func glyph(_ mark: StockIdentity.Mark) -> some View {
        Text(mark.glyph)
            .font(.system(size: size * (mark.glyph.count > 1 ? 0.32 : 0.42), weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: mark.foregroundHex))
    }
}

struct CommentCountLabel: View {
    var count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bubble.right")
            if count > 0 {
                Text("\(count)")
                    .monospacedDigit()
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(KkanbuTheme.muted)
    }
}

struct PulseChip: View {
    var snapshot: StockPulse.Snapshot

    var body: some View {
        Text(snapshot.rating)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch snapshot.kick {
        case "glory": Color.kkanbuUp
        case "roast": Color.kkanbuDown
        default: KkanbuTheme.muted
        }
    }
}

struct TakeStepper: View {
    var selected: TakeLevel?
    var action: (TakeLevel) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(TakeLevel.allCases, id: \.self) { level in
                Button {
                    KkanbuHaptic.tap()
                    action(level)
                } label: {
                    Text(level.shortTitle)
                        .font(.caption2.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(selected == level ? color(level) : KkanbuTheme.muted)
                        .background(
                            (selected == level ? color(level).opacity(0.12) : KkanbuTheme.chip),
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func color(_ level: TakeLevel) -> Color {
        switch level.kick {
        case "glory": Color.kkanbuUp
        case "roast": Color.kkanbuDown
        default: KkanbuTheme.ink
        }
    }
}

struct NewsCard: View {
    var item: StockPulse.NewsItem

    var body: some View {
        Link(destination: item.url) {
            HStack(alignment: .top, spacing: 10) {
                AsyncImage(url: item.imageURL) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    default:
                        KkanbuTheme.chip
                    }
                }
                .frame(width: 72, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(KkanbuTheme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("\(item.source) · \(item.ago)")
                        .font(.caption2)
                        .foregroundStyle(KkanbuTheme.faint)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct PulseStrip: View {
    @Environment(AppStore.self) private var store
    var snapshot: StockPulse.Snapshot
    var compact: Bool = true
    var stock: Stock? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                PulseChip(snapshot: snapshot)
                Text(snapshot.take)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KkanbuTheme.muted)
                    .lineLimit(1)
            }
            if !compact {
                if let stock {
                    TakeStepper(selected: snapshot.myTake ?? snapshot.groupTake) { level in
                        store.setTake(stockId: stock.id, level: level)
                    }
                }
                Text(snapshot.blurb)
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
                Text("주요 뉴스")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(KkanbuTheme.faint)
                    .padding(.top, 2)
                ForEach(snapshot.items.prefix(2)) { item in
                    NewsCard(item: item)
                }
            } else if let first = snapshot.items.first {
                NewsCard(item: first)
            }
        }
    }
}

struct FoldSection<Content: View>: View {
    var title: String
    var count: Int
    var preview: String?
    @Binding var isOpen: Bool
    var content: Content

    init(
        title: String,
        count: Int = 0,
        preview: String? = nil,
        isOpen: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.count = count
        self.preview = preview
        self._isOpen = isOpen
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                KkanbuHaptic.tap()
                withAnimation(.easeInOut(duration: 0.2)) { isOpen.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.muted)
                    Spacer(minLength: 8)
                    if !isOpen, let preview, !preview.isEmpty {
                        Text(preview)
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                            .lineLimit(1)
                    } else if count > 0 {
                        Text("\(count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(KkanbuTheme.faint)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(KkanbuTheme.faint)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if isOpen {
                content
                    .padding(.bottom, 10)
            }
            KkanbuTheme.line.frame(height: 1)
        }
    }
}

struct QuietButton: View {
    var title: String
    var kind: Kind = .primary
    var action: () -> Void

    enum Kind { case primary, secondary, ghost }

    var body: some View {
        Button {
            KkanbuHaptic.tap()
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
                .foregroundStyle(foreground)
                .background(background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch kind {
        case .primary: KkanbuTheme.bg
        case .secondary, .ghost: KkanbuTheme.ink
        }
    }

    private var background: Color {
        switch kind {
        case .primary: KkanbuTheme.ink
        case .secondary: KkanbuTheme.chip
        case .ghost: .clear
        }
    }
}

struct PillButton: View {
    var title: String
    var systemImage: String? = nil
    var kind: Kind = .primary
    var action: () -> Void

    enum Kind { case primary, secondary, ghost, danger }

    var body: some View {
        QuietButton(
            title: title,
            kind: kind == .secondary || kind == .ghost ? .secondary : .primary,
            action: action
        )
    }
}

struct ReturnText: View {
    var value: Double
    var size: CGFloat = 22

    var body: some View {
        Text(MoneyFormat.percent(value))
            .font(.system(size: size, weight: .semibold, design: .default).monospacedDigit())
            .foregroundStyle(value >= 0 ? Color.kkanbuUp : Color.kkanbuDown)
    }
}

struct VerificationBadge: View {
    var state: VerificationState

    var body: some View {
        if state == .screenshotVerified {
            Text("✓")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .background(Color(red: 0.22, green: 0.592, blue: 0.941), in: Circle())
                .accessibilityLabel("캡처 인증")
        }
    }
}

struct EmptyStateView: View {
    var emoji: String = ""
    var title: String
    var message: String
    var centered: Bool = false

    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 8) {
            if centered {
                BrandMark(size: 64)
                    .padding(.bottom, 8)
            }
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(centered ? .center : .leading)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(KkanbuTheme.muted)
                .multilineTextAlignment(centered ? .center : .leading)
                .lineSpacing(2)
        }
        .padding(.vertical, centered ? 28 : 20)
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }
}

struct InviteChip: View {
    var code: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("초대")
                    .foregroundStyle(KkanbuTheme.muted)
                Text(code)
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(KkanbuTheme.ink)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(KkanbuTheme.chip, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("초대 코드 \(code) 복사")
    }
}

struct DisclaimerBanner: View {
    var body: some View {
        Text("직접 입력한 보유 정보는 증권 계좌로 검증되지 않습니다. 투자 자문이 아닙니다.")
            .font(.caption)
            .foregroundStyle(KkanbuTheme.faint)
            .padding(.vertical, 8)
    }
}

struct EventRow: View {
    var event: FeedEvent
    var relative: String
    var actorName: String = ""
    var onTap: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) { content }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if actorName.isEmpty {
                    Image(systemName: event.type.systemImage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(KkanbuTheme.ink)
                        .frame(width: 32, height: 32)
                        .background(KkanbuTheme.chip, in: Circle())
                } else {
                    InitialsAvatar(name: actorName, size: 32)
                    Image(systemName: event.type.systemImage)
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 14, height: 14)
                        .background(kickColor(for: event.type) == KkanbuTheme.muted ? KkanbuTheme.ink : kickColor(for: event.type), in: Circle())
                        .offset(x: 1, y: 1)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(kickColor(for: event.type))
                Text(event.message)
                    .font(.subheadline)
                    .foregroundStyle(KkanbuTheme.ink)
                Text(relative)
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
            }
        }
        .padding(.vertical, 10)
    }

    private func kickColor(for type: EventType) -> Color {
        switch type {
        case .goldenKkangbu, .godsMovePartners, .destinyPartners, .moonTogether, .recommendAccepted:
            Color.kkanbuUp
        case .worstPartner, .graveyardPartners, .soloEscape, .soldTooEarly, .recommendRejected:
            Color.kkanbuDown
        default:
            KkanbuTheme.muted
        }
    }
}

struct GradeTitle: View {
    var grade: KkangbuGrade
    var size: CGFloat = 13

    var body: some View {
        Text(grade.title)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
    }

    private var color: Color {
        if grade.isRoast { return Color.kkanbuDown }
        if grade.isGlory { return Color.kkanbuUp }
        return KkanbuTheme.muted
    }
}

struct HoldingCardView: View {
    @Environment(AppStore.self) private var store
    var stock: Stock
    var holding: Holding
    var currentPrice: Double
    var partners: [String]
    var grade: KkangbuGrade?
    var showsQuantity: Bool
    var isMine: Bool
    var ownerName: String? = nil
    var onRecommend: (() -> Void)?
    var onAddOn: (() -> Void)?
    var onSell: (() -> Void)?
    var onVerify: (() -> Void)?
    var showsPulse: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 12) {
                StockMark(ticker: stock.ticker, name: stock.name, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    if let ownerName {
                        Text(ownerName)
                            .font(.caption)
                            .foregroundStyle(KkanbuTheme.faint)
                    }
                    HStack(spacing: 5) {
                        Text(stock.name)
                            .font(.body.weight(.semibold))
                        VerificationBadge(state: holding.verificationState)
                    }
                    Text(stock.ticker)
                        .font(.caption.monospaced())
                        .foregroundStyle(KkanbuTheme.faint)
                }
                Spacer()
                ReturnText(value: holding.returnRate(currentPrice: currentPrice), size: 16)
            }
            Text("평단 \(MoneyFormat.price(holding.averagePrice, market: stock.market)) · 현재가 \(MoneyFormat.price(currentPrice, market: stock.market))")
                .font(.footnote)
                .foregroundStyle(KkanbuTheme.muted)
            if showsPulse {
                PulseStrip(snapshot: rowPulse, stock: stock)
            }
            if showsQuantity, let qty = holding.quantity {
                Text("수량 \(String(format: "%g", qty))")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
            }
            if let grade, !partners.isEmpty {
                HStack(spacing: 4) {
                    Text("\(partners.joined(separator: " · "))와")
                        .font(.caption)
                        .foregroundStyle(KkanbuTheme.muted)
                    GradeTitle(grade: grade, size: 12)
                }
            } else if !partners.isEmpty {
                Text("\(partners.joined(separator: " · "))와 깐부")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.muted)
            }
            if holding.status == .sold {
                Text("매도 · \(MoneyFormat.percent(holding.returnRate(currentPrice: holding.sellPrice ?? currentPrice)))")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
            }
            HStack(spacing: 8) {
                if isMine, holding.status == .holding {
                    small("친구에게 추천", action: onRecommend)
                    small("추매", action: onAddOn)
                    small("매도", action: onSell)
                }
                if isMine, holding.verificationState != .screenshotVerified {
                    small("캡처 인증", action: onVerify)
                }
            }
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            KkanbuTheme.line.frame(height: 1)
        }
    }

    private var rowPulse: StockPulse.Snapshot {
        store.pulseSnapshot(for: stock, in: store.state.selectedGroupId)
    }

    @ViewBuilder
    private func small(_ title: String, action: (() -> Void)?) -> some View {
        if let action {
            Button(title, action: action)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(KkanbuTheme.chip, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(KkanbuTheme.ink)
        }
    }
}

struct KkanbuCard<Content: View>: View {
    var padding: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.vertical, padding == 0 ? 0 : 8)
    }
}

struct SectionLabel: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(KkanbuTheme.muted)
            .padding(.top, 20)
            .padding(.bottom, 4)
    }
}
