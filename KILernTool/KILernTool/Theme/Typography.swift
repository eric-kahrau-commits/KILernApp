import SwiftUI

// MARK: - App Typography
// Semantisches Font-System laut ui-ux-pro-max Skill: Rules "text-styles-system", "dynamic-type"
// Verwendet iOS Dynamic Type-Stile, damit die App Schriftgrößen-Einstellungen des Nutzers respektiert.
// Feste Größen (.fixed / .fixedRounded) nur für UI-Elemente, die nicht skalieren dürfen (z.B. Chart-Labels).

struct AppTypography {

    // MARK: Display — Große Überschriften (Startseiten, Hero-Bereiche)
    static let displayLarge = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let display      = Font.system(.title, design: .rounded).weight(.bold)
    static let displaySmall = Font.system(.title2, design: .rounded).weight(.bold)

    // MARK: Headline — Abschnittsüberschriften, Card-Titel
    static let headline     = Font.system(.headline, design: .rounded)
    static let headlineBold = Font.system(.headline, design: .rounded).weight(.bold)

    // MARK: Subheadline / Label — Beschriftungen, Badge-Text
    static let subheadline      = Font.system(.subheadline)
    static let subheadlineMedium = Font.system(.subheadline).weight(.medium)
    static let subheadlineBold  = Font.system(.subheadline).weight(.semibold)

    // MARK: Body — Fließtext, Aufgabenbeschreibungen
    static let body         = Font.system(.body)
    static let bodyMedium   = Font.system(.body).weight(.medium)
    static let bodySemibold = Font.system(.body).weight(.semibold)

    // MARK: Callout — Sekundärer Body-Text
    static let callout      = Font.system(.callout)
    static let calloutMedium = Font.system(.callout).weight(.medium)

    // MARK: Footnote / Caption — Kleine Hinweistexte, Zeitstempel
    static let footnote     = Font.system(.footnote)
    static let footnoteMedium = Font.system(.footnote).weight(.medium)
    static let caption      = Font.system(.caption)
    static let captionBold  = Font.system(.caption).weight(.semibold)
    static let caption2     = Font.system(.caption2)

    // MARK: Feste Größen (nicht dynamisch skalierend)
    // Nur verwenden wenn Dynamic Type das Layout kaputt machen würde (z.B. Chart-Achsenbeschriftungen).

    static func fixed(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func fixedRounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
