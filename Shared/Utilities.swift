import SwiftUI

enum LernzeitAppGroup {
    static let id = "group.com.cramleo.Lernzeit"
}

extension UserDefaults {
    /// Gemeinsamer Store für App und Widget; fällt ohne App-Group auf Standard zurück.
    static let lernzeitShared = UserDefaults(suiteName: LernzeitAppGroup.id) ?? .standard
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
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.14))
                .frame(width: 440, height: 440)
                .blur(radius: 100)
                .offset(x: -190, y: -170)
            Circle()
                .fill(Color.purple.opacity(0.12))
                .frame(width: 380, height: 380)
                .blur(radius: 100)
                .offset(x: 210, y: 190)
        }
        .ignoresSafeArea()
    }
}
