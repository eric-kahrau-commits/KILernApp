import SwiftUI

struct Subject: Identifiable, Hashable {
    static func == (lhs: Subject, rhs: Subject) -> Bool { lhs.name == rhs.name }
    func hash(into hasher: inout Hasher) { hasher.combine(name) }
    let id = UUID()
    let name: String
    let icon: String
    let color: Color

    static let all: [Subject] = [
        Subject(name: "Mathe",       icon: "function",              color: Color(red: 0.20, green: 0.40, blue: 0.90)),
        Subject(name: "Deutsch",     icon: "text.book.closed.fill", color: Color(red: 0.90, green: 0.50, blue: 0.10)),
        Subject(name: "Englisch",    icon: "globe",                 color: Color(red: 0.18, green: 0.68, blue: 0.40)),
        Subject(name: "Französisch", icon: "flag.fill",             color: Color(red: 0.50, green: 0.20, blue: 0.82)),
        Subject(name: "Spanisch",    icon: "sun.max.fill",          color: Color(red: 0.90, green: 0.30, blue: 0.22)),
        Subject(name: "Latein",      icon: "building.columns.fill", color: Color(red: 0.60, green: 0.44, blue: 0.28)),
        Subject(name: "Chemie",      icon: "atom",                  color: Color(red: 0.10, green: 0.64, blue: 0.64)),
        Subject(name: "Bio",         icon: "leaf.fill",             color: Color(red: 0.24, green: 0.66, blue: 0.30)),
        Subject(name: "Physik",      icon: "bolt.fill",             color: Color(red: 0.36, green: 0.28, blue: 0.82)),
    ]
}
