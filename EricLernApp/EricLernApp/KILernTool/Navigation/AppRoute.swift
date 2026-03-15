import Foundation

enum AppRoute: String, CaseIterable, Identifiable {
    case home       = "Start"
    case learn      = "Lernen"
    case new        = "Neu"
    case stats      = "Statistiken"
    case settings   = "Einstellungen"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .learn:    return "books.vertical.fill"
        case .new:      return "plus.circle.fill"
        case .stats:    return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
