import SwiftUI

// MARK: - Sidebar

struct Sidebar: View {
    @Binding var selectedRoute: AppRoute
    @Binding var isOpen: Bool
    var isExpanded: Bool = true
    var autoCloseOnSelect: Bool = false

    @EnvironmentObject var streakManager: StreakManager
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            sidebarNavItems
            Spacer()
            sidebarStreakBadge
            sidebarFooter
        }
        .frame(width: isExpanded ? 252 : 64)
        .frame(maxHeight: .infinity)
        .background(sidebarBackground)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.primary.opacity(0.07))
                .frame(width: 0.5)
        }
        .animation(AppAnimation.standard, value: isExpanded)
    }

    // MARK: Header
    private var sidebarHeader: some View {
        HStack(spacing: 10) {
            // Mini app-icon badge — matches home-screen icon
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.49, green: 0.23, blue: 0.93),
                                Color(red: 0.18, green: 0.06, blue: 0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                MascotView(color: .white, mood: .idle, size: 26)
            }
            .shadow(color: Color(red: 0.49, green: 0.23, blue: 0.93).opacity(0.40),
                    radius: 6, x: 0, y: 3)

            if isExpanded {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Open Learn")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Deine Lernplattform")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: Nav Items
    private var sidebarNavItems: some View {
        VStack(spacing: 2) {
            ForEach(AppRoute.allCases) { route in
                SidebarNavItem(
                    route: route,
                    isSelected: selectedRoute == route,
                    isExpanded: isExpanded
                ) {
                    withAnimation(AppAnimation.micro) {
                        selectedRoute = route
                        if autoCloseOnSelect || !isExpanded {
                            isOpen = false
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
    }

    // MARK: Streak Badge

    private var sidebarStreakBadge: some View {
        let orange = Color(red: 0.96, green: 0.52, blue: 0.08)
        return Group {
            if isExpanded {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(orange.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(orange)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(streakManager.currentStreak) \(streakManager.currentStreak == 1 ? "Tag" : "Tage")")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Streak")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .leading)))
            } else {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(orange)
                        .frame(width: 36, height: 36)
                    if streakManager.currentStreak > 0 {
                        Text("\(streakManager.currentStreak)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(orange))
                            .offset(x: 4, y: -2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 6)
        .animation(AppAnimation.standard, value: isExpanded)
    }

    // MARK: Footer
    private var sidebarFooter: some View {
        Group {
            if isExpanded {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Open Learn v1.0")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
                .transition(.opacity)
            } else {
                Color.clear.frame(height: 24)
            }
        }
    }

    // MARK: Background
    private var sidebarBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(Color(uiColor: .systemBackground).opacity(0.5))
        }
        .ignoresSafeArea()
    }
}

// MARK: - Sidebar Nav Item

struct SidebarNavItem: View {
    let route: AppRoute
    let isSelected: Bool
    let isExpanded: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var accentColor: Color {
        Color(red: 0.38, green: 0.28, blue: 0.90)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                // Icon container
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 9)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.18), accentColor.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                    }
                    Image(systemName: route.icon)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? accentColor : Color.secondary)
                        .frame(width: 36, height: 36)
                }

                // Label
                if isExpanded {
                    Text(route.rawValue)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .transition(.opacity.combined(with: .move(edge: .leading)))

                    Spacer()

                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 6, height: 6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .background(
            Group {
                if route == .new {
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            TutorialManager.shared.reportFrame(
                                geo.frame(in: .global), for: .neuSidebarItem
                            )
                        }
                    }
                }
            }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.08)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(AppAnimation.micro) { isPressed = false }
                }
        )
    }
}

// MARK: - iPhone Overlay Sidebar Wrapper

struct PhoneSidebarOverlay: View {
    @Binding var selectedRoute: AppRoute
    @Binding var isOpen: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if isOpen {
                // Backdrop
                Color.black.opacity(0.32)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(AppAnimation.standard) {
                            isOpen = false
                        }
                    }
                    .zIndex(1)

                // Sidebar panel
                Sidebar(
                    selectedRoute: $selectedRoute,
                    isOpen: $isOpen,
                    isExpanded: true,
                    autoCloseOnSelect: true
                )
                    .transition(.move(edge: .leading))
                    .zIndex(2)
            }
        }
        .animation(AppAnimation.standard, value: isOpen)
    }
}
