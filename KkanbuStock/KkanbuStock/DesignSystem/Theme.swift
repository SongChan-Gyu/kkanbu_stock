import SwiftUI

enum KkanbuTheme {
    static let radius: CGFloat = 10
    static let pagePadding: CGFloat = 20

    static let bg = Color(red: 0.965, green: 0.969, blue: 0.973)
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
}

struct KkanbuBackground: View {
    var body: some View {
        KkanbuTheme.bg.ignoresSafeArea()
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
            Color(red: 0.247, green: 0.290, blue: 0.353),
            Color(red: 0.294, green: 0.333, blue: 0.388),
            Color(red: 0.341, green: 0.325, blue: 0.306),
            Color(red: 0.267, green: 0.251, blue: 0.235),
            Color(red: 0.322, green: 0.322, blue: 0.357),
            Color(red: 0.247, green: 0.247, blue: 0.275)
        ]
        let idx = abs(name.hashValue) % palettes.count
        return palettes[idx]
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

struct QuietButton: View {
    var title: String
    var kind: Kind = .primary
    var action: () -> Void

    enum Kind { case primary, secondary, ghost }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(foreground)
                .background(background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.footnote)
                .foregroundStyle(KkanbuTheme.muted)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !actorName.isEmpty {
                InitialsAvatar(name: actorName, size: 32)
            }
            VStack(alignment: .leading, spacing: 4) {
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
}

struct HoldingCardView: View {
    var stock: Stock
    var holding: Holding
    var currentPrice: Double
    var partners: [String]
    var grade: KkangbuGrade?
    var showsQuantity: Bool
    var isMine: Bool
    var ownerName: String? = nil
    var onRecommend: (() -> Void)?
    var onPropose: (() -> Void)?
    var onSell: (() -> Void)?
    var onSuspect: (() -> Void)?
    var onVerify: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
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
            if showsQuantity, let qty = holding.quantity {
                Text("수량 \(String(format: "%g", qty))")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
            }
            if let grade, !partners.isEmpty {
                Text("\(partners.joined(separator: " · "))와 \(grade.title)")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.muted)
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
                    small("같이 사자고 제안", action: onPropose)
                    small("매도", action: onSell)
                } else if !isMine, holding.status == .holding {
                    small("매수가 의심", action: onSuspect)
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
