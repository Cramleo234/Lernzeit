import SwiftUI

extension UserDefaults {
    /// Gemeinsame Suite für App und Widget — eine normale Plist in
    /// ~/Library/Preferences, bewusst KEIN Group Container (keine System-Rückfrage).
    static let lernzeitShared = UserDefaults(suiteName: "com.cramleo.Lernzeit.shared") ?? .standard
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Hell"
        case .dark: "Dunkel"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private struct AppAppearanceModifier: ViewModifier {
    @AppStorage(SettingsKeys.appAppearance) private var appAppearance = AppAppearance.system.rawValue

    func body(content: Content) -> some View {
        content.preferredColorScheme(AppAppearance(rawValue: appAppearance)?.colorScheme)
    }
}

extension View {
    func lernzeitAppearance() -> some View {
        modifier(AppAppearanceModifier())
    }
}

func formatDuration(_ interval: TimeInterval) -> String {
    let totalMinutes = Int(interval) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 { return "\(hours) h \(minutes) min" }
    if totalMinutes > 0 { return "\(minutes) min" }
    return "< 1 min"
}

func clockString(_ interval: TimeInterval, alwaysShowHours: Bool = false) -> String {
    let seconds = max(0, Int(interval.rounded()))
    if alwaysShowHours || seconds >= 3600 {
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
}

/// Weiche Farbverläufe hinter den Glas-Flächen, damit Liquid Glass etwas zu brechen hat.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.035, green: 0.045, blue: 0.075),
                        Color(red: 0.015, green: 0.018, blue: 0.028),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            Circle()
                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.14))
                .frame(width: 440, height: 440)
                .blur(radius: 100)
                .offset(x: -190, y: -170)
            Circle()
                .fill(Color.purple.opacity(colorScheme == .dark ? 0.20 : 0.12))
                .frame(width: 380, height: 380)
                .blur(radius: 100)
                .offset(x: 210, y: 190)
        }
        .ignoresSafeArea()
    }
}
