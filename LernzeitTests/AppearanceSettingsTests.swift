import SwiftUI
import XCTest
@testable import Lernzeit

@MainActor
final class AppearanceSettingsTests: XCTestCase {
    func testLegacyAppearanceLoadsWithStandardThemeByDefault() {
        withIsolatedDefaults { defaults in
            defaults.set(AppAppearance.dark.rawValue, forKey: SettingsKeys.appAppearance)

            let store = AppearanceStore(defaults: defaults)

            XCTAssertEqual(store.appearance, .dark)
            XCTAssertEqual(store.theme, .standard)
        }
    }

    func testAppearanceAndThemePersistIndependently() {
        withIsolatedDefaults { defaults in
            let store = AppearanceStore(defaults: defaults)
            store.appearance = .light
            store.theme = .forest

            XCTAssertEqual(store.appearance, .light)
            XCTAssertEqual(store.theme, .forest)
            XCTAssertEqual(defaults.string(forKey: SettingsKeys.appAppearance), AppAppearance.light.rawValue)
            XCTAssertEqual(defaults.string(forKey: SettingsKeys.appTheme), AppTheme.forest.rawValue)

            store.appearance = .dark

            XCTAssertEqual(store.theme, .forest)
            XCTAssertEqual(AppearanceStore(defaults: defaults).theme, .forest)
            XCTAssertEqual(AppearanceStore(defaults: defaults).appearance, .dark)
        }
    }

    func testAppearanceModesOnlyOverrideTheSystemWhenExplicitlySelected() {
        XCTAssertNil(AppAppearance.system.overrideColorScheme)
        XCTAssertEqual(AppAppearance.light.overrideColorScheme, ColorScheme.light)
        XCTAssertEqual(AppAppearance.dark.overrideColorScheme, ColorScheme.dark)
    }

    func testAllSupportedThemesAreAvailable() {
        XCTAssertEqual(AppTheme.allCases, [.standard, .ocean, .forest, .sunset])
    }

    private func withIsolatedDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "AppearanceSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }
}
