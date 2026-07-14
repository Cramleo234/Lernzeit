import Foundation
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: localized("appearance.system")
        case .light: localized("appearance.light")
        case .dark: localized("appearance.dark")
        }
    }

    var overrideColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case standard
    case ocean
    case forest
    case sunset

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: localized("theme.standard")
        case .ocean: localized("theme.ocean")
        case .forest: localized("theme.forest")
        case .sunset: localized("theme.sunset")
        }
    }

    func palette(for colorScheme: ColorScheme) -> ThemePalette {
        switch (self, colorScheme) {
        case (.standard, .light):
            return ThemePalette(
                backgroundStart: .clear,
                backgroundEnd: .clear,
                accent: .accentColor,
                secondary: .purple
            )
        case (.standard, .dark):
            return ThemePalette(
                backgroundStart: Color(red: 0.035, green: 0.045, blue: 0.075),
                backgroundEnd: Color(red: 0.015, green: 0.018, blue: 0.028),
                accent: .accentColor,
                secondary: .purple
            )
        case (.ocean, .light):
            return ThemePalette(
                backgroundStart: Color(red: 0.93, green: 0.98, blue: 1.00),
                backgroundEnd: Color(red: 0.87, green: 0.94, blue: 0.98),
                accent: Color(red: 0.00, green: 0.42, blue: 0.72),
                secondary: Color(red: 0.00, green: 0.65, blue: 0.72)
            )
        case (.ocean, .dark):
            return ThemePalette(
                backgroundStart: Color(red: 0.02, green: 0.08, blue: 0.12),
                backgroundEnd: Color(red: 0.01, green: 0.03, blue: 0.06),
                accent: Color(red: 0.25, green: 0.72, blue: 0.95),
                secondary: Color(red: 0.12, green: 0.50, blue: 0.68)
            )
        case (.forest, .light):
            return ThemePalette(
                backgroundStart: Color(red: 0.94, green: 0.98, blue: 0.94),
                backgroundEnd: Color(red: 0.89, green: 0.95, blue: 0.90),
                accent: Color(red: 0.14, green: 0.48, blue: 0.28),
                secondary: Color(red: 0.44, green: 0.62, blue: 0.22)
            )
        case (.forest, .dark):
            return ThemePalette(
                backgroundStart: Color(red: 0.03, green: 0.08, blue: 0.05),
                backgroundEnd: Color(red: 0.015, green: 0.035, blue: 0.025),
                accent: Color(red: 0.35, green: 0.72, blue: 0.43),
                secondary: Color(red: 0.63, green: 0.72, blue: 0.29)
            )
        case (.sunset, .light):
            return ThemePalette(
                backgroundStart: Color(red: 1.00, green: 0.96, blue: 0.93),
                backgroundEnd: Color(red: 0.99, green: 0.90, blue: 0.91),
                accent: Color(red: 0.84, green: 0.32, blue: 0.18),
                secondary: Color(red: 0.72, green: 0.24, blue: 0.48)
            )
        case (.sunset, .dark):
            return ThemePalette(
                backgroundStart: Color(red: 0.11, green: 0.045, blue: 0.04),
                backgroundEnd: Color(red: 0.045, green: 0.02, blue: 0.035),
                accent: Color(red: 1.00, green: 0.55, blue: 0.32),
                secondary: Color(red: 0.90, green: 0.35, blue: 0.58)
            )
        @unknown default:
            return palette(for: .light)
        }
    }
}

struct ThemePalette {
    let backgroundStart: Color
    let backgroundEnd: Color
    let accent: Color
    let secondary: Color
}

@MainActor
@Observable
final class AppearanceStore {
    private let defaults: UserDefaults

    var appearance: AppAppearance {
        didSet {
            defaults.set(appearance.rawValue, forKey: SettingsKeys.appAppearance)
        }
    }

    var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: SettingsKeys.appTheme)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = defaults.string(forKey: SettingsKeys.appAppearance)
            .flatMap(AppAppearance.init(rawValue:)) ?? .system
        theme = defaults.string(forKey: SettingsKeys.appTheme)
            .flatMap(AppTheme.init(rawValue:)) ?? .standard
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.standard
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

private struct AppAppearanceModifier: ViewModifier {
    let appearanceStore: AppearanceStore

    @ViewBuilder
    func body(content: Content) -> some View {
        switch appearanceStore.appearance {
        case .system:
            themed(content)
        case .light:
            themed(content).preferredColorScheme(.light)
        case .dark:
            themed(content).preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private func themed(_ content: Content) -> some View {
        content.modifier(AppThemeModifier(theme: appearanceStore.theme))
    }
}

private struct AppThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let theme: AppTheme

    @ViewBuilder
    func body(content: Content) -> some View {
        if theme == .standard {
            content.environment(\.appTheme, theme)
        } else {
            content
                .environment(\.appTheme, theme)
                .tint(theme.palette(for: colorScheme).accent)
        }
    }
}

extension View {
    func lernzeitAppearance(_ appearanceStore: AppearanceStore) -> some View {
        modifier(AppAppearanceModifier(appearanceStore: appearanceStore))
    }
}

/// Soft gradients behind the glass surfaces keep each theme recognizable without reducing readability.
struct AppBackground: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = theme.palette(for: colorScheme)

        ZStack {
            if theme != .standard || colorScheme == .dark {
                LinearGradient(
                    colors: [palette.backgroundStart, palette.backgroundEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            Circle()
                .fill(palette.accent.opacity(colorScheme == .dark ? 0.22 : 0.14))
                .frame(width: 440, height: 440)
                .blur(radius: 100)
                .offset(x: -190, y: -170)
            Circle()
                .fill(palette.secondary.opacity(colorScheme == .dark ? 0.20 : 0.12))
                .frame(width: 380, height: 380)
                .blur(radius: 100)
                .offset(x: 210, y: 190)
        }
        .ignoresSafeArea()
    }
}
