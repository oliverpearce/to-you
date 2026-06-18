//
//  FloatingHUD.swift
//  to-you.

import AppKit
import SwiftUI

extension Notification.Name {
    static let hudSettingsDidChange = Notification.Name("to-you.hudSettingsDidChange")
    static let testAlarm            = Notification.Name("to-you.testAlarm")
    static let showHUD              = Notification.Name("to-you.showHUD")
}

final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class FloatingHUD {
    private var window: NSPanel?
    private weak var model: AppModel?
    private var observer: NSObjectProtocol?
    private var screenObserver: NSObjectProtocol?

    func show(model: AppModel, onClose: @escaping () -> Void, openSettings: @escaping () -> Void) {
        self.model = model
        model.hudVisible = true

        if window == nil {
            createWindow(model: model, onClose: onClose, openSettings: openSettings)
        }
        window?.orderFrontRegardless()

        if observer == nil {
            observer = NotificationCenter.default.addObserver(
                forName: .hudSettingsDidChange, object: nil, queue: .main
            ) { [weak self] _ in self?.applySize() }
        }

        if screenObserver == nil {
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
            ) { [weak self] _ in self?.repositionIfOffScreen() }
        }
    }

    func hide() {
        model?.hudVisible = false
        window?.orderOut(nil)
    }

    // MARK: - Private

    private func currentSize() -> HUDSize {
        let key = UserDefaults.standard.string(forKey: "hudSize") ?? HUDSize.compact.rawValue
        if key == "Compact" { return .compact }  // migrate old stored value
        return HUDSize(rawValue: key) ?? .compact
    }

    private func createWindow(model: AppModel, onClose: @escaping () -> Void, openSettings: @escaping () -> Void) {
        let size = currentSize()
        let pw = size.panelSize.width
        let ph = size.panelSize.height

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: pw, height: ph),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = FirstMouseHostingView(rootView: HUDTimerView(model: model, onClose: onClose, openSettings: openSettings))

        if let screen = NSScreen.main {
            let vf = screen.visibleFrame
            let margin: CGFloat = 16
            let ox = vf.maxX - pw - margin
            let oy = vf.maxY - ph - margin
            panel.setFrameOrigin(NSPoint(x: ox, y: oy))
        }
        window = panel
    }

    private func repositionIfOffScreen() {
        guard let window else { return }
        let onScreen = NSScreen.screens.contains { $0.frame.intersects(window.frame) }
        guard !onScreen, let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        let margin: CGFloat = 16
        window.setFrameOrigin(NSPoint(
            x: vf.maxX - window.frame.width - margin,
            y: vf.maxY - window.frame.height - margin
        ))
    }

    private func applySize() {
        let size = currentSize()
        guard let window else { return }
        let newSize = size.panelSize
        var frame = window.frame
        frame.origin.y += frame.height - newSize.height  // keep top-left fixed
        frame.size = newSize
        window.setFrame(frame, display: true, animate: true)
    }
}
