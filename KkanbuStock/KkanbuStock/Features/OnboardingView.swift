import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var nickname = ""
    @State private var emoji = "🐣"
    @State private var appear = false

    private let emojis = ["🐣", "😎", "🦊", "🐰", "🐼", "🐯", "🐥", "🦄", "🐸", "🐙"]

    var body: some View {
        ZStack {
            KkanbuBackground()
            VStack(alignment: .leading, spacing: 24) {
                Spacer()
                Text("주식 깐부")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(KkanbuTheme.coral)
                Text("오늘 친구들\n주식 어떻게 됐지ㅋㅋ")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 12)
                Text("증권 앱이 아니에요.\n친구끼리 같은 종목을 발견하고, 튀고, 존버하고, 놀리는 게임입니다.")
                    .foregroundStyle(.secondary)
                emojiRow
                TextField("닉네임", text: $nickname)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(.background.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
                DisclaimerBanner()
                PillButton(title: "데모 주식팟으로 시작", systemImage: "party.popper") {
                    store.completeOnboarding(nickname: displayName, emoji: emoji, useDemo: true)
                }
                PillButton(title: "빈 그룹으로 시작", kind: .secondary) {
                    store.completeOnboarding(nickname: displayName, emoji: emoji, useDemo: false)
                }
                Spacer()
            }
            .padding(24)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7)) { appear = true }
        }
    }

    private var displayName: String {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "나" : trimmed
    }

    private var emojiRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(emojis, id: \.self) { item in
                    Button {
                        emoji = item
                    } label: {
                        Text(item)
                            .font(.largeTitle)
                            .padding(8)
                            .background(emoji == item ? KkanbuTheme.coral.opacity(0.2) : .clear, in: Circle())
                    }
                }
            }
        }
    }
}
