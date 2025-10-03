//
//  appDelegate.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import Cocoa
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()

    // Shared state
    let model = AppModel()

    // Floating HUD
    private let hud = FloatingHUD()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register default: HUD visible ON by default
        UserDefaults.standard.register(defaults: ["hudVisible": true])

        // Notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // Status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "umbrella", accessibilityDescription: "umbrella")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Ticks update the menubar title/icon
        model.onTick = { [weak self] left in
            guard let self, let button = self.statusItem.button else { return }
            if self.model.isRunning {
                button.image = nil
                button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
                button.title = self.model.formatted(left)
            } else {
                button.title = ""
                button.image = NSImage(systemSymbolName: "umbrella", accessibilityDescription: "umbrella")
            }
        }
        model.onFinish = { [weak self] in self?.notifyAndReveal() }

        // Popover content
        let content = TimerPopoverView(
            model: model,
            showHUD: { [weak self] in self?.showHUD() },
            hideHUD: { [weak self] in self?.hud.hide() }
        )
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 420, height: 260)
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: content)

        // Show HUD on launch if enabled by default
        if model.hudVisible { showHUD() }
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown { popover.performClose(sender) }
        else { popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY) }
    }

    private func showHUD() {
        let view = HUDTimerView(model: model)
        hud.show(with: view)
    }

    private func notifyAndReveal() {
        let content = UNMutableNotificationContent()
        content.title = "The rain has stopped, and the fog lifted."
        content.body = "Please take a short break!"
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil),
            withCompletionHandler: nil
        )

        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
//        SoundManager.shared.playNamed("SoftChime") // no‑op if not bundled
    }
}
