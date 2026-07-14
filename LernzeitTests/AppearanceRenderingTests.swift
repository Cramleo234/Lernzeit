import AppKit
import SwiftUI
import XCTest
@testable import Lernzeit

@MainActor
final class AppearanceRenderingTests: XCTestCase {
    func testSystemModeTracksAChangedParentColorSchemeWithoutRestart() {
        withIsolatedStore { store in
            store.appearance = .system
            let source = ColorSchemeSource(.light)
            let recorder = ColorSchemeRecorder()
            let root = ColorSchemeHarness(store: store, source: source, recorder: recorder)
            let hostingView = makeHostingView(root)

            waitForRendering()
            XCTAssertEqual(recorder.lastValue, .light)

            source.value = .dark
            hostingView.layoutSubtreeIfNeeded()
            waitForRendering()

            XCTAssertEqual(recorder.lastValue, .dark)
        }
    }

    func testEveryThemeRendersInLightAndDarkAppearance() throws {
        for appearance in [AppAppearance.light, .dark] {
            for theme in AppTheme.allCases {
                try withIsolatedStore { store in
                    store.appearance = appearance
                    store.theme = theme
                    let colorScheme: ColorScheme = appearance == .light ? .light : .dark
                    let root = ThemeVerificationView()
                        .lernzeitAppearance(store)
                        .environment(\.colorScheme, colorScheme)
                        .environment(store)
                    let hostingView = makeHostingView(root, size: NSSize(width: 640, height: 400))

                    waitForRendering()
                    let image = try XCTUnwrap(snapshot(of: hostingView))
                    XCTAssertEqual(image.size.width, 640, accuracy: 1)
                    XCTAssertEqual(image.size.height, 400, accuracy: 1)
                    addSnapshotAttachment(image, name: "\(theme.rawValue)-\(appearance.rawValue)")
                }
            }
        }
    }

    private func makeHostingView<Content: View>(
        _ root: Content,
        size: NSSize = NSSize(width: 320, height: 180)
    ) -> NSHostingView<Content> {
        let hostingView = NSHostingView(rootView: root)
        hostingView.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.layoutIfNeeded()
        hostingView.layoutSubtreeIfNeeded()
        return hostingView
    }

    private func snapshot(of view: NSView) -> NSImage? {
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let image = NSImage(size: view.bounds.size)
        image.addRepresentation(bitmap)
        return image
    }

    private func addSnapshotAttachment(_ image: NSImage, name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForRendering() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }

    private func withIsolatedStore(_ body: (AppearanceStore) throws -> Void) rethrows {
        let suiteName = "AppearanceRenderingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        try body(AppearanceStore(defaults: defaults))
    }
}

@MainActor
@Observable
private final class ColorSchemeSource {
    var value: ColorScheme

    init(_ value: ColorScheme) {
        self.value = value
    }
}

@MainActor
private final class ColorSchemeRecorder {
    var lastValue: ColorScheme?
}

private struct ColorSchemeHarness: View {
    let store: AppearanceStore
    let source: ColorSchemeSource
    let recorder: ColorSchemeRecorder

    var body: some View {
        ColorSchemeProbe(recorder: recorder)
            .lernzeitAppearance(store)
            .environment(\.colorScheme, source.value)
            .environment(store)
    }
}

private struct ColorSchemeProbe: View {
    @Environment(\.colorScheme) private var colorScheme
    let recorder: ColorSchemeRecorder

    var body: some View {
        Text(colorScheme == .dark ? "Dark" : "Light")
            .onAppear { recorder.lastValue = colorScheme }
            .onChange(of: colorScheme) { _, newValue in
                recorder.lastValue = newValue
            }
    }
}

private struct ThemeVerificationView: View {
    var body: some View {
        VStack(spacing: 20) {
            Label("Theme verification", systemImage: "graduationcap.fill")
                .font(.title2.bold())
            ProgressView(value: 0.68)
                .frame(width: 300)
            HStack {
                Button("Primary action") {}
                    .buttonStyle(.borderedProminent)
                Button("Secondary action") {}
                    .buttonStyle(.bordered)
            }
            Text("Readable primary and secondary content")
            Text("Status and controls stay recognizable")
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { AppBackground() }
    }
}
