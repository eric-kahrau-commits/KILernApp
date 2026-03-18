import CoreGraphics

// MARK: - App Spacing
// 4pt/8dp Spacing-Scale laut ui-ux-pro-max Skill: Rule "spacing-scale" (Material Design 4pt grid)
// Alle padding(), spacing:, frame()-Werte sollen auf diese Konstanten referenzieren.

struct AppSpacing {

    // MARK: Basis-Skala (4pt-Raster)
    static let xs:   CGFloat = 4    // Sehr enger Abstand: Badges, Icon-Labels
    static let sm:   CGFloat = 8    // Kleiner Abstand: zwischen zusammengehörigen Elementen
    static let md:   CGFloat = 16   // Standard-Padding: Card-Inhalt, Formfelder
    static let lg:   CGFloat = 20   // Abstand zwischen Sektionen
    static let xl:   CGFloat = 24   // Großer Abstand: Header-Abstände
    static let xxl:  CGFloat = 32   // Sehr großer Abstand: Hero-Bereiche
    static let xxxl: CGFloat = 48   // Bottom-Padding / Safe-Area-Puffer

    // MARK: Semantische Helfer
    static let cardPadding:     CGFloat = 16   // Standard-Innenabstand einer Card
    static let cardRadius:      CGFloat = 16   // Standard corner radius für Cards
    static let buttonRadius:    CGFloat = 12   // Corner radius für Buttons
    static let chipRadius:      CGFloat = 8    // Corner radius für Chips / Badges
    static let sectionSpacing:  CGFloat = 20   // Abstand zwischen Haupt-Sektionen
    static let screenPadding:   CGFloat = 18   // Horizontaler Außenabstand zum Screen-Rand
    static let itemSpacing:     CGFloat = 12   // Abstand zwischen Listeneinträgen
    static let tinySpacing:     CGFloat = 6    // Feinabstimmung: Label zu Icon etc.

    // MARK: Touch Targets (ui-ux-pro-max Skill: "touch-target-size" — min 44×44pt Apple HIG)
    static let minTouchTarget:  CGFloat = 44
}
