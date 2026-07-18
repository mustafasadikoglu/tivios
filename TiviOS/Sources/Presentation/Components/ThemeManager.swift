import SwiftUI

public final class ThemeManager: ObservableObject {
    @Published public var currentThemeType: ThemeType {
        didSet {
            UserDefaults.standard.set(currentThemeType.rawValue, forKey: "app_theme_type")
            currentTheme = Theme.getTheme(for: currentThemeType)
        }
    }
    
    @Published public var currentTheme: Theme
    
    public init() {
        let savedRaw = UserDefaults.standard.string(forKey: "app_theme_type") ?? ""
        let savedType = ThemeType(rawValue: savedRaw) ?? .darkPurple
        self.currentThemeType = savedType
        self.currentTheme = Theme.getTheme(for: savedType)
    }
    
    // Convenience helper to get primary gradient
    public var primaryGradient: LinearGradient {
        let colors = currentTheme.primaryGradient.map { Color(hex: $0) }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // Convenience helper for background gradient
    public var backgroundGradient: LinearGradient {
        let colors = currentTheme.backgroundGradient.map { Color(hex: $0) }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    public var cardBackground: Color {
        return Color(hex: currentTheme.cardBackground).opacity(0.04)
    }
    
    public var cardStroke: Color {
        return Color(hex: currentTheme.textColor).opacity(0.1)
    }
    
    public var accentColor: Color {
        return Color(hex: currentTheme.accentColor)
    }
}
