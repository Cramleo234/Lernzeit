import AppKit
import SwiftData
import SwiftUI
import XCTest
@testable import Lernzeit

@MainActor
final class SettingsLayoutTests: XCTestCase {
    func testLongSettingsFormScrollsInsideWindowSizedHost() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Subject.self,
            StudySession.self,
            TimerPreset.self,
            configurations: configuration
        )
        let suiteName = "SettingsLayoutTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let root = SettingsView()
            .modelContainer(container)
            .environment(AppearanceStore(defaults: defaults))
        let hostingView = NSHostingView(rootView: root)
        let contentSize = NSSize(width: 640, height: 600)
        hostingView.frame = NSRect(origin: .zero, size: contentSize)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.layoutIfNeeded()
        hostingView.layoutSubtreeIfNeeded()

        let scrollViews = descendants(of: NSScrollView.self, in: hostingView)
        let formScrollView = try XCTUnwrap(
            scrollViews.first { scrollView in
                guard let documentView = scrollView.documentView else { return false }
                return documentView.frame.height > scrollView.contentView.bounds.height + 1
            },
            "Die lange Einstellungsform muss innerhalb des Fensters scrollbar sein."
        )

        XCTAssertEqual(hostingView.frame.height, contentSize.height, accuracy: 1)
        XCTAssertTrue(formScrollView.hasVerticalScroller)
        XCTAssertGreaterThan(
            formScrollView.documentView?.frame.height ?? 0,
            formScrollView.contentView.bounds.height
        )
    }

    private func descendants<T: NSView>(of type: T.Type, in root: NSView) -> [T] {
        root.subviews.flatMap { child in
            (child as? T).map { [$0] } ?? [] + descendants(of: type, in: child)
        }
    }
}
