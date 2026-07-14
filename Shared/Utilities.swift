import Foundation
import SwiftUI

func localized(_ key: String, _ arguments: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    guard !arguments.isEmpty else { return format }
    return String(format: format, locale: Locale.current, arguments: arguments)
}

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

func formatDuration(_ interval: TimeInterval) -> String {
    let totalMinutes = Int(interval) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 { return localized("duration.hours_minutes", hours, minutes) }
    if totalMinutes > 0 { return localized("duration.minutes", totalMinutes) }
    return localized("duration.less_than_minute")
}

func clockString(_ interval: TimeInterval, alwaysShowHours: Bool = false) -> String {
    let seconds = max(0, Int(interval.rounded()))
    if alwaysShowHours || seconds >= 3600 {
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
}
