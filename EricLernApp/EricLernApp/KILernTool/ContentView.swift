import SwiftUI // immer

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @State private var selectedRoute: AppRoute = .home
    @State private var isSidebarOpen = false
    @State private var feedbackPlan: LernPlan? = nil

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isCompact: Bool { sizeClass == .compact }

    /// First plan whose test date has passed and feedback hasn't been given yet
    private var pendingFeedbackPlan: LernPlan? {
        lernPlanStore.plans.first { plan in
            plan.daysUntilTest < 0 && !FeedbackManager.shared.hasSeen(planId: plan.id)
        }
    }

    var body: some View {
        Group {
            if isCompact {
                iPhoneLayout
            } else {
                iPadLayout
            }
        }
        .preferredColorScheme(themeManager.preferredColorScheme)
        .animation(.easeInOut(duration: 0.28), value: themeManager.isDarkMode)
        .overlay {
            if streakManager.pendingPopup {
                StreakPopupView(streak: streakManager.currentStreak) {
                    streakManager.pendingPopup = false
                }
                .transition(.opacity)
                .zIndex(100)
            }
            if let plan = feedbackPlan {
                TestFeedbackView(plan: plan) {
                    withAnimation { feedbackPlan = nil }
                }
                .transition(.opacity)
                .zIndex(99)
            }
        }
        .onAppear { checkForFeedback() }
        .onChange(of: lernPlanStore.plans) { checkForFeedback() }
    }

    private func checkForFeedback() {
        if feedbackPlan == nil, let plan = pendingFeedbackPlan {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { feedbackPlan = plan }
            }
        }
    }

    // MARK: - iPhone Layout (overlay sidebar)

    private var iPhoneLayout: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                TopBar(title: selectedRoute.rawValue, isSidebarOpen: $isSidebarOpen)
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }
            .ignoresSafeArea(edges: .bottom)

            PhoneSidebarOverlay(selectedRoute: $selectedRoute, isOpen: $isSidebarOpen)
        }
    }

    // MARK: - iPad / Mac Layout (persistent sidebar)

    private var iPadLayout: some View {
        HStack(spacing: 0) {
            Sidebar(
                selectedRoute: $selectedRoute,
                isOpen: $isSidebarOpen,
                isExpanded: isSidebarOpen
            )
            .onHover { hovering in
                withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                    isSidebarOpen = hovering
                }
            }

            VStack(spacing: 0) {
                TopBar(title: selectedRoute.rawValue, isSidebarOpen: $isSidebarOpen)
                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Page switcher

    @ViewBuilder
    private var mainContent: some View {
        switch selectedRoute {
        case .home:
            HomeView(onNavigateToLearn: { selectedRoute = .learn })
        case .learn:
            LearnView()
        case .new:
            NewView()
        case .stats:
            StatsView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .environmentObject(StreakManager.shared)
        .environmentObject(LernSetStore.shared)
        .environmentObject(LernPlanStore.shared)
}
