import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @State private var nickname = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            KkanbuBackground()
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 24)
                BrandMark(size: 78)
                    .padding(.bottom, 22)
                Text("주식 깐부")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.6)
                Text("같은 종목을 사면 깐부가 됩니다.")
                    .font(.body)
                    .foregroundStyle(KkanbuTheme.muted)
                    .padding(.top, 8)
                    .padding(.bottom, 36)
                Text("닉네임")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(KkanbuTheme.muted)
                TextField("이름", text: $nickname)
                    .textInputAutocapitalization(.never)
                    .font(.title3.weight(.semibold))
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) { KkanbuTheme.line.frame(height: 1) }
                Spacer(minLength: 24)
                QuietButton(title: "데모 그룹으로 시작") {
                    store.completeOnboarding(nickname: displayName, emoji: "·", useDemo: true)
                }
                .padding(.bottom, 8)
                QuietButton(title: "빈 그룹으로 시작", kind: .secondary) {
                    store.completeOnboarding(nickname: displayName, emoji: "·", useDemo: false)
                }
                Text("직접 입력한 보유 정보는 증권 계좌로 검증되지 않습니다. 투자 자문이 아닙니다.")
                    .font(.caption)
                    .foregroundStyle(KkanbuTheme.faint)
                    .padding(.top, 16)
            }
            .padding(KkanbuTheme.pagePadding)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) { appeared = true }
        }
    }

    private var displayName: String {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "나" : trimmed
    }
}
