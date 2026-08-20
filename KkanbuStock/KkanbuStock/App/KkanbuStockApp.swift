import SwiftUI

@main
struct KkanbuStockApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.state.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .overlay(alignment: .top) {
            if let toast = store.toast {
                Text(toast)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(duration: 0.4), value: store.toast)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                            store.toast = nil
                        }
                    }
            }
        }
        .alert("잠깐", isPresented: Binding(
            get: { store.lastError != nil },
            set: { if !$0 { store.lastError = nil } }
        )) {
            Button("확인", role: .cancel) { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.tickMarket(delta: 0)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(12))
                store.tickMarket()
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
                TabView {
            GroupHomeContainer()
                .tabItem { Label("그룹", systemImage: "person.3.fill") }
            HoldingsView()
                .tabItem { Label("내 주식", systemImage: "sparkles") }
            ActivityView()
                .tabItem { Label("활동", systemImage: "bolt.heart.fill") }
                .badge(store.inboxItems(for: store.state.currentUserId).count)
            ProfileView()
                .tabItem { Label("프로필", systemImage: "face.smiling") }
        }
        .tint(KkanbuTheme.coral)
    }
}
