import SwiftUI

// MARK: - App Colors
// Zentrale Farb-Tokens laut ui-ux-pro-max Skill: Rule "color-semantic"
// Kein Raw-RGB-Wert mehr direkt in Komponenten — immer AppColors verwenden.

struct AppColors {

    // MARK: Brand — KI Lernset / Theo / Allgemein-Lila
    static let brandPurple      = Color(red: 0.38, green: 0.18, blue: 0.90)
    static let brandPurpleLight = Color(red: 0.30, green: 0.52, blue: 0.98)

    // MARK: Brand — Lernplan / Sascha / Blau
    static let brandBlue        = Color(red: 0.10, green: 0.48, blue: 0.92)

    // MARK: Brand — Test Erstellen / Max / Pink-Rot
    static let brandPink        = Color(red: 0.85, green: 0.25, blue: 0.45)
    static let brandPinkDeep    = Color(red: 0.60, green: 0.18, blue: 0.75)

    // MARK: Brand — Scan / Kristin / Petrol
    static let brandTeal        = Color(red: 0.12, green: 0.58, blue: 0.46)
    static let brandTealBright  = Color(red: 0.05, green: 0.68, blue: 0.58)
    static let brandTealLight   = Color(red: 0.20, green: 0.80, blue: 0.60)

    // MARK: Brand — Vokabel / Robert / Orange
    static let brandVokabel     = Color(red: 0.86, green: 0.50, blue: 0.10)
    static let brandVokabelGold = Color(red: 0.98, green: 0.78, blue: 0.08)

    // MARK: Brand — Lern-Modi
    static let brandQuick       = Color(red: 0.95, green: 0.55, blue: 0.10)
    static let brandMemorize    = Color(red: 0.15, green: 0.60, blue: 0.40)
    static let brandTestModus   = Color(red: 0.25, green: 0.25, blue: 0.80)

    // MARK: Semantic — Status
    static let success          = Color(red: 0.15, green: 0.70, blue: 0.40)
    static let error            = Color(red: 0.85, green: 0.22, blue: 0.22)
    static let warning          = Color(red: 0.86, green: 0.50, blue: 0.10)

    // MARK: Stats-Card Gradienten (StatsView overviewRow)
    static let statsKartenStart = Color(red: 0.38, green: 0.18, blue: 0.90) // = brandPurple
    static let statsKartenEnd   = Color(red: 0.30, green: 0.52, blue: 0.98) // = brandPurpleLight
    static let statsSetsStart   = Color(red: 0.10, green: 0.64, blue: 0.54)
    static let statsSetsEnd     = Color(red: 0.20, green: 0.82, blue: 0.66)
    static let statsStreakStart  = Color(red: 0.96, green: 0.42, blue: 0.08)
    static let statsStreakEnd    = Color(red: 1.00, green: 0.62, blue: 0.20)

    // MARK: Surfaces (Dark-Mode-sicher via UIColor — passen sich automatisch an)
    static let surface          = Color(UIColor.systemGroupedBackground)
    static let surfaceSecond    = Color(UIColor.secondarySystemGroupedBackground)
    static let surfaceTertiary  = Color(UIColor.tertiarySystemGroupedBackground)
}

// MARK: - App Gradients
// Fertige LinearGradients für wiederkehrende Farbverläufe.

struct AppGradients {

    static let learn = LinearGradient(
        colors: [AppColors.brandPurple, AppColors.brandBlue],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let test = LinearGradient(
        colors: [AppColors.brandPink, AppColors.brandPinkDeep],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let scan = LinearGradient(
        colors: [AppColors.brandTeal, AppColors.brandTealLight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let vokabel = LinearGradient(
        colors: [AppColors.brandVokabel, AppColors.brandVokabelGold],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let statsKarten = LinearGradient(
        colors: [AppColors.statsKartenStart, AppColors.statsKartenEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let statsSets = LinearGradient(
        colors: [AppColors.statsSetsStart, AppColors.statsSetsEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let statsStreak = LinearGradient(
        colors: [AppColors.statsStreakStart, AppColors.statsStreakEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - App Animation
// Einheitliche Animations-Tokens laut ui-ux-pro-max Skill: Rule "motion-consistency"
// Alle .spring()-Aufrufe im Code sollen auf diese Konstanten referenzieren.

struct AppAnimation {
    /// Micro-Interaktionen: Button-Press, Toggle, kleine UI-Reaktionen (≤200ms)
    static let micro      = Animation.spring(response: 0.20, dampingFraction: 0.80)
    /// Standard: Cards, Banner, Overlays (≈300ms)
    static let standard   = Animation.spring(response: 0.35, dampingFraction: 0.75)
    /// Emphasized: Komplexe Übergänge, Sheet-Enters (≈450ms)
    static let emphasized = Animation.spring(response: 0.50, dampingFraction: 0.70)

    /// Enter-Dauer für .easeOut / .easeIn Animationen (Skill: duration-timing ≤300ms)
    static let enterDuration: Double = 0.30
    /// Exit-Dauer = 66% von Enter (Skill: exit-faster-than-enter)
    static let exitDuration:  Double = 0.20
}

// MARK: - Press Scale Button Style
// Laut ui-ux-pro-max Skill: "scale-feedback" — 0.97 scale on press for all tappable cards.
// Verwende .buttonStyle(PressScaleButtonStyle()) statt .buttonStyle(.plain) für Card-Buttons.

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppAnimation.micro, value: configuration.isPressed)
    }
}
