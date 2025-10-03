//
//  FloatingHUD.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import AppKit
import SwiftUI

final class FloatingHUD {
    private var window: NSPanel?

    func show(with root: some View) {
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 160, height: 72),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered, defer: false)
            panel.level = .floating
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hidesOnDeactivate = false
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: AnyView(root))
            window = panel
        }
        window?.makeKeyAndOrderFront(nil)
    }

    func hide() { window?.orderOut(nil) }
}
