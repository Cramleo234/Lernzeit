import AppKit
import SwiftUI

/// Randloses Overlay-Fenster, das eine Fortschrittslinie um die Notch legt.
/// Auf Macs ohne Notch passiert hier schlicht nichts — dort übernimmt der
/// Ring im Menüleisten-Icon.
@MainActor
final class NotchOverlayController {
    private var panel: NSPanel?

    func show(engine: TimerEngine) {
        guard panel == nil else { return }
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) else { return }

        let topInset = screen.safeAreaInsets.top
        let leftWidth = screen.auxiliaryTopLeftArea?.width ?? 0
        let rightWidth = screen.auxiliaryTopRightArea?.width ?? 0
        let notchWidth = screen.frame.width - leftWidth - rightWidth
        guard notchWidth > 40, notchWidth < screen.frame.width / 2 else { return }

        let margin: CGFloat = 30
        let size = CGSize(width: notchWidth + margin * 2, height: topInset + 14)
        let origin = CGPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.maxY - size.height
        )

        let newPanel = NSPanel(
            contentRect: CGRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        newPanel.ignoresMouseEvents = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        newPanel.contentView = NSHostingView(
            rootView: NotchLineView(engine: engine, notchWidth: notchWidth, topInset: topInset, margin: margin)
        )
        newPanel.orderFrontRegardless()
        panel = newPanel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }
}

struct NotchLineView: View {
    let engine: TimerEngine
    let notchWidth: CGFloat
    let topInset: CGFloat
    let margin: CGFloat
    @State private var pulsing = false

    private var isBreak: Bool {
        engine.mode == .pomodoro && engine.phase == .pause
    }

    /// Pausen laufen in hellem, pulsierendem Grün ab, der eigentliche Timer in Rot.
    private var lineColor: Color {
        isBreak ? Color(red: 0.3, green: 1.0, blue: 0.55) : Color(red: 1.0, green: 0.23, blue: 0.19)
    }

    var body: some View {
        let shape = NotchOutlineShape(notchWidth: notchWidth, topInset: topInset, margin: margin)
        ZStack {
            shape
                .stroke(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            shape
                .trim(from: 0, to: max(0.003, engine.ambientProgress))
                .stroke(lineColor, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                .shadow(color: lineColor.opacity(0.8), radius: 5)
                .animation(.linear(duration: 0.5), value: engine.ambientProgress)
                .opacity(isBreak ? (pulsing ? 1 : 0.35) : 1)
        }
        .opacity(engine.isPaused ? 0.35 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
    }
}

/// Zeichnet die Kontur UM die Notch herum: knapp außerhalb der schwarzen
/// Fläche, damit die Linie vollständig sichtbar bleibt — links hinunter,
/// unten entlang, rechts wieder hinauf.
struct NotchOutlineShape: Shape {
    let notchWidth: CGFloat
    let topInset: CGFloat
    let margin: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gap: CGFloat = 3
        let left = margin - gap
        let right = margin + notchWidth + gap
        let bottom = topInset + gap
        let radius: CGFloat = 11

        path.move(to: CGPoint(x: left, y: 0))
        path.addLine(to: CGPoint(x: left, y: bottom - radius))
        path.addQuadCurve(
            to: CGPoint(x: left + radius, y: bottom),
            control: CGPoint(x: left, y: bottom)
        )
        path.addLine(to: CGPoint(x: right - radius, y: bottom))
        path.addQuadCurve(
            to: CGPoint(x: right, y: bottom - radius),
            control: CGPoint(x: right, y: bottom)
        )
        path.addLine(to: CGPoint(x: right, y: 0))
        return path
    }
}

/// Template-Ring für das Menüleisten-Icon; die Menüleiste tönt ihn automatisch passend.
@MainActor
func menuBarRingImage(progress: Double) -> NSImage {
    let dimension: CGFloat = 16
    let lineWidth: CGFloat = 2
    let image = NSImage(size: NSSize(width: dimension, height: dimension), flipped: false) { _ in
        let center = NSPoint(x: dimension / 2, y: dimension / 2)
        let radius = (dimension - lineWidth) / 2

        let track = NSBezierPath()
        track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        track.lineWidth = lineWidth
        NSColor.black.withAlphaComponent(0.25).setStroke()
        track.stroke()

        let clamped = min(1, max(0, progress))
        if clamped > 0.01 {
            let arc = NSBezierPath()
            arc.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 90,
                endAngle: 90 - 360 * clamped,
                clockwise: true
            )
            arc.lineWidth = lineWidth
            arc.lineCapStyle = .round
            NSColor.black.setStroke()
            arc.stroke()
        }
        return true
    }
    image.isTemplate = true
    return image
}
