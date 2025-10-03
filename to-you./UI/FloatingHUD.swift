//
//  FloatingHUD.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import AppKit
import SwiftUI

/// Floating HUD panel that does **not** try to become key (avoids makeKeyWindow warning)
/// and simply orders itself frontmost. Clicks still work; it just won’t steal focus.
final class FloatingHUD {
    private var window: NSPanel?

    func show(with root: some View) {
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 260, height: 160),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered, defer: false)
            panel.level = .floating
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            panel.contentView = NSHostingView(rootView: AnyView(root))
            window = panel
        }
        // Important: `nonactivatingPanel` cannot become key; do NOT call makeKeyAndOrderFront.
        window?.orderFrontRegardless()
    }

    func hide() { window?.orderOut(nil) }
}

// If you prefer a focusable HUD that **can** become key (e.g., for text input),
// use this subclass and remove `.nonactivatingPanel` from the style mask above:
final class KeyableHUDPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
