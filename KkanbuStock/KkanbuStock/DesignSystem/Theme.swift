import SwiftUI

enum KkanbuTheme {
    static let radius: CGFloat = 28
    static let innerRadius: CGFloat = 18

    static let cream = Color(red: 1.0, green: 0.965, blue: 0.922)
    static let ink = Color(red: 0.122, green: 0.086, blue: 0.067)
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.29)
    static let mint = Color(red: 0.18, green: 0.83, blue: 0.75)
    static let gold = Color(red: 0.95, green: 0.72, blue: 0.22)
    static let grape = Color(red: 0.45, green: 0.29, blue: 0.72)
    static let night = Color(red: 0.09, green: 0.075, blue: 0.07)
}

extension Color {
    static let kkanbuUp = Color(red: 1.0, green: 0.42, blue: 0.29)
    static let kkanbuDown = Color(red: 0.45, green: 0.42, blue: 0.82)
}

struct KkanbuBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [KkanbuTheme.night, Color(red: 0.16, green: 0.08, blue: 0.07)]
                : [KkanbuTheme.cream, Color(red: 1, green: 0.93, blue: 0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct KkanbuCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.opacity(0.72), in: RoundedRectangle(cornerRadius: KkanbuTheme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: KkanbuTheme.radius, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }
}

struct AvatarView: View {
    var emoji: String
    var size: CGFloat = 52

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.48))
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [KkanbuTheme.coral.opacity(0.9), KkanbuTheme.gold], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: Circle()
            )
    }
}

struct PillButton: View {
    var title: String
    var systemImage: String? = nil
    var kind: Kind = .primary
    var action: () -> Void

    enum Kind { case primary, secondary, ghost, danger }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.headline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: kind == .ghost ? nil : .infinity)
            .foregroundStyle(foreground)
            .background(background, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch kind {
        case .primary: .white
        case .secondary, .ghost: .primary
        case .danger: .white
        }
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .primary:
            LinearGradient(colors: [KkanbuTheme.coral, Color.orange], startPoint: .leading, endPoint: .trailing)
        case .secondary:
            Color.primary.opacity(0.08)
        case .ghost:
            Color.clear
        case .danger:
            KkanbuTheme.grape
        }
    }
}

struct ReturnText: View {
    var value: Double
    var size: CGFloat = 34

    var body: some View {
        Text(MoneyFormat.percent(value))
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(value >= 0 ? Color.kkanbuUp : Color.kkanbuDown)
            .contentTransition(.numericText())
    }
}

struct VerificationBadge: View {
    var state: VerificationState

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.16), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch state {
        case .unverified: "⚪ 직접 입력"
        case .screenshotVerified: "🟢 캡처 인증"
        case .suspected: "👀 의심 중"
        case .mismatch: "🚨 정보 불일치"
        }
    }

    private var color: Color {
        switch state {
        case .unverified: .secondary
        case .screenshotVerified: KkanbuTheme.mint
        case .suspected: .orange
        case .mismatch: KkanbuTheme.coral
        }
    }
}

struct EmptyStateView: View {
    var emoji: String
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 10) {
            Text(emoji).font(.system(size: 52))
            Text(title).font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

struct DisclaimerBanner: View {
    var body: some View {
        Text("직접 입력한 보유 정보는 증권 계좌로 검증되지 않아요. 이 앱은 투자 자문이 아니라 친구랑 노는 게임입니다.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct EventRow: View {
    var event: FeedEvent
    var relative: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.type.emoji)
                .font(.largeTitle)
                .frame(width: 52, height: 52)
                .background(.primary.opacity(0.05), in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                Text(event.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HoldingCardView: View {
    var stock: Stock
    var holding: Holding
    var currentPrice: Double
    var partners: [String]
    var grade: KkangbuGrade?
    var showsQuantity: Bool
    var isMine: Bool
    var onRecommend: (() -> Void)?
    var onPropose: (() -> Void)?
    var onSell: (() -> Void)?
    var onSuspect: (() -> Void)?
    var onVerify: (() -> Void)?

    var body: some View {
        KkanbuCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stock.name)
                            .font(.title2.bold())
                        Text(stock.ticker)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VerificationBadge(state: holding.verificationState)
                }
                ReturnText(value: holding.returnRate(currentPrice: currentPrice))
                HStack {
                    labeled("평단", MoneyFormat.price(holding.averagePrice, market: stock.market))
                    labeled("현재가", MoneyFormat.price(currentPrice, market: stock.market))
                    if showsQuantity, let qty = holding.quantity {
                        labeled("수량", String(format: "%g", qty))
                    }
                }
                if let grade, !partners.isEmpty {
                    Text("\(grade.emoji) \(partners.joined(separator: ", "))와 \(grade.title)")
                        .font(.subheadline.weight(.semibold))
                } else if !partners.isEmpty {
                    Text("🤝 \(partners.joined(separator: ", "))와 깐부")
                        .font(.subheadline.weight(.semibold))
                }
                if holding.status == .sold {
                    Text("매도 완료 · \(MoneyFormat.percent(holding.returnRate(currentPrice: holding.sellPrice ?? currentPrice)))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    if isMine, holding.status == .holding {
                        small("📣 너도 사!", action: onRecommend)
                        small("🤔 이거 어때?", action: onPropose)
                        small("🏃 매도", action: onSell)
                    } else if !isMine, holding.status == .holding {
                        small("🕵️ 구라핑 의심", action: onSuspect)
                    }
                    if isMine, holding.verificationState != .screenshotVerified {
                        small("📸 인증", action: onVerify)
                    }
                }
            }
        }
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func small(_ title: String, action: (() -> Void)?) -> some View {
        if let action {
            Button(title, action: action)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.primary.opacity(0.06), in: Capsule())
        }
    }
}
