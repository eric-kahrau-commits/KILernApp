import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    
    @Published var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "isDarkMode") {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    var preferredColorScheme: ColorScheme? {
        isDarkMode ? .dark : .light
    }
}