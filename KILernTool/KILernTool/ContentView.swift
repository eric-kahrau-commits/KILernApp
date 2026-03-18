import SwiftUI // immer
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var streakManager: StreakManager
    @EnvironmentObject var lernPlanStore: LernPlanStore
    @EnvironmentObject var store: LernSetStore
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var notifManager = NotificationManager.shared

    @State private var selectedRoute: AppRoute = .home
    @State private var isSidebarOpen = false
    @State private var feedbackPlan: LernPlan? = nil
    @State private var showNotifSheet = false
    // Counts plan additions so we can trigger the prompt after first plan save
    @State private var lastPlanCount = 0
    // Pre-login onboarding shown once
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "ol_hasSeenOnboarding")

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
            if authManager.isLoggedIn {
                mainAppView
            } else if showOnboarding {
                OnboardingView(onComplete: { showOnboarding = false })
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.42), value: showOnboarding)
        .animation(AppAnimation.standard, value: authManager.isLoggedIn)
        .preferredColorScheme(themeManager.preferredColorScheme)
        .animation(.easeInOut(duration: 0.28), value: themeManager.isDarkMode)
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .onChange(of: authManager.currentUser?.uid) { _, uid in
            guard uid != nil else { return }
            // Sync all cloud data after login
            Task {
                await store.syncFromCloud()
                await lernPlanStore.syncFromCloud()
                await streakManager.syncFromCloud()
                // Also push any local-only data that may exist on this device
                await store.uploadAllToCloud()
                await lernPlanStore.uploadAllToCloud()
            }
            // Start in-app tutorial for first-time users
            TutorialManager.shared.start()
        }
    }

    // MARK: - Deep Link Handling (Widget / Notification taps)

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "openlearn" else { return }
        switch url.host {
        case "home":
            selectedRoute = .home
        case "learn":
            selectedRoute = .learn
        case "new":
            selectedRoute = .new
        case "stats":
            selectedRoute = .stats
        case "settings":
            selectedRoute = .settings
        case "plan":
            // openlearn://plan?id=<uuid> — navigate to learn tab
            // (LernPlanDetail could be pushed from LearnView; for now switch to learn)
            selectedRoute = .learn
        default:
            break
        }
        // Close sidebar if open
        isSidebarOpen = false
    }

    private var mainAppView: some View {
        Group {
            if isCompact {
                iPhoneLayout
            } else {
                iPadLayout
            }
        }
        .overlay {
            // In-app tutorial overlay (below streak popup)
            TutorialOverlayView(
                manager: TutorialManager.shared,
                onHamburgerTap: {
                    withAnimation(AppAnimation.standard) { isSidebarOpen = true }
                },
                onNeuTap: {
                    withAnimation(AppAnimation.micro) {
                        selectedRoute = .new
                        isSidebarOpen = false
                    }
                }
            )
            .zIndex(150)

            if streakManager.pendingPopup {
                StreakPopupView(streak: streakManager.currentStreak) {
                    streakManager.pendingPopup = false
                }
                .transition(.opacity)
                .zIndex(200)
            }
            if let plan = feedbackPlan {
                TestFeedbackView(plan: plan) {
                    withAnimation { feedbackPlan = nil }
                }
                .transition(.opacity)
                .zIndex(199)
            }
        }
        .sheet(isPresented: $showNotifSheet) {
            NotificationPermissionSheet {
                // User tapped "Einschalten"
                showNotifSheet = false
                Task {
                    let granted = await notifManager.requestPermission()
                    if granted {
                        await notifManager.scheduleAll(
                            streak: streakManager.currentStreak,
                            plans:  lernPlanStore.plans,
                            sets:   store.lernSets
                        )
                    }
                }
            } onDismiss: {
                notifManager.markPromptShown()
                showNotifSheet = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            checkForFeedback()
            checkNotifPrompt(delay: 2.0)
            lastPlanCount = lernPlanStore.plans.count
        }
        .onChange(of: lernPlanStore.plans) { _, plans in
            checkForFeedback()
            // Trigger prompt when the user saves their first learning plan
            if plans.count > lastPlanCount {
                lastPlanCount = plans.count
                checkNotifPrompt(delay: 1.0)
            }
        }
    }

    private func checkNotifPrompt(delay: Double) {
        Task {
            await notifManager.refreshStatus()
            let show = notifManager.shouldShowFirstLaunchPrompt
                    || notifManager.shouldShowWeeklyPrompt
            if show {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                showNotifSheet = true
            }
        }
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
        .environmentObject(AuthManager.shared)
}
