import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var nickname = ""

    var body: some View {
        ZStack {
            KkanbuBackground()
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                Text("주식 깐부")
                    .font(.title2.weight(.semibold))
                Text("친구와 같은 종목을 보유하면 깐부가 됩니다.")
                    .font(.subheadline)
                    .foregroundStyle(KkanbuTheme.muted)
                TextField("닉네임", text: $nickname)
                    .textInputAutocapitalization(.never)
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                DisclaimerBanner()
                QuietButton(title: "데모 그룹으로 시작") {
                    store.completeOnboarding(nickname: displayName, emoji: "·", useDemo: true)
                }
                QuietButton(title: "빈 그룹으로 시작", kind: .secondary) {
                    store.completeOnboarding(nickname: displayName, emoji: "·", useDemo: false)
                }
                Spacer()
            }
            .padding(KkanbuTheme.pagePadding)
        }
    }

    private var displayName: String {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "나" : trimmed
    }
}
