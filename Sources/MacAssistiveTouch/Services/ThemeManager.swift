import SwiftUI

public enum AppTheme: String, CaseIterable, Sendable {
    case dark = "dark"
    case light = "light"

    public var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .light: return .light
        }
    }
}

@MainActor
public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()

    private let themeKey = "AppThemePreference"

    @Published public var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
        }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: saved) {
            self.currentTheme = theme
        } else {
            // Varsayılan LIGHT mode
            self.currentTheme = .light
        }
    }

    public func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentTheme = (currentTheme == .dark) ? .light : .dark
        }
    }
}
