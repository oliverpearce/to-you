//
//  appDelegate.swift
//  to-you.

import Cocoa
import SwiftUI
import Combine
import CoreText
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    let model = AppModel()
    private let hud = FloatingHUD()
    private var bag = Set<AnyCancellable>()
    private var alarmSound: NSSound?
    private var muteWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerBundledFonts()

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // Menubar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "umbrella", accessibilityDescription: "umbrella")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Reactive menubar updates — all three together so we never read isRunning mid-flight
        Publishers.CombineLatest3(model.$secondsLeft, model.$isPaused, model.$isRunning)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] secondsLeft, isPaused, isRunning in
                guard let self else { return }
                if isRunning || isPaused {
                    self.updateStatusButton(secondsLeft: secondsLeft, isPaused: isPaused)
                } else {
                    self.resetStatusButton()
                }
            }
            .store(in: &bag)

        model.onFinish = { [weak self] in self?.notifyAndReveal() }

        NotificationCenter.default.addObserver(
            forName: .testAlarm, object: nil, queue: .main
        ) { [weak self] _ in self?.notifyAndReveal() }

        // Popover content
        let content = TimerPopoverView(
            model: model,
            openSettings: {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            },
            closePopover: { [weak self] in
                self?.popover.performClose(nil)
            },
            toggleHUD: { [weak self] in
                guard let self else { return }
                if self.model.hudVisible {
                    self.hud.hide()
                } else {
                    self.hud.show(model: self.model, onClose: { [weak self] in self?.hud.hide() })
                }
            }
        )
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 310, height: 148)
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: content)

    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func updateStatusButton(secondsLeft: Int, isPaused: Bool) {
        guard let button = statusItem.button else { return }
        let expanded = UserDefaults.standard.string(forKey: "menuBarStyle") == "expanded"
        button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        button.title = model.formatted(secondsLeft) + (isPaused ? " ⏸" : "")
        if expanded {
            button.image = NSImage(systemSymbolName: "umbrella.fill", accessibilityDescription: nil)
            button.image?.isTemplate = true
            button.imagePosition = .imageLeft
        } else {
            button.image = nil
            button.imagePosition = .noImage
        }
    }

    private func resetStatusButton() {
        guard let button = statusItem.button else { return }
        button.title = ""
        button.image = NSImage(systemSymbolName: "umbrella", accessibilityDescription: "umbrella")
        button.image?.isTemplate = true
        button.imagePosition = .imageOnly
        button.font = nil
    }

    private func notifyAndReveal() {
        resetStatusButton()
        playAlarm()

        let weatherRaw = UserDefaults.standard.string(forKey: "selectedWeather") ?? "Rain"
        let weatherName = weatherRaw == "None" ? "storm" : weatherRaw.lowercased()
        let title = "The \(weatherName) has cleared."
        let body = BreakMessages.random()

        // Always-visible custom banner — no permission required
        FinishedBanner.show(title: title, body: body)

        // Also fire a system notification if the user has enabled them
        let enabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        guard enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = nil
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil),
            withCompletionHandler: nil)
    }

    private func playAlarm() {
        alarmSound?.stop()
        muteWorkItem?.cancel()

        let volume = Float(UserDefaults.standard.object(forKey: "alarmVolume") as? Double ?? 0.5)
        guard volume > 0, let sound = NSSound(named: NSSound.Name("Glass")) else { return }
        sound.volume = volume
        sound.play()
        alarmSound = sound

        let autoMute = UserDefaults.standard.object(forKey: "autoMuteAlarm") as? Bool ?? false
        if autoMute {
            let raw  = UserDefaults.standard.integer(forKey: "autoMuteDuration")
            let secs = Double(min(60, max(1, raw == 0 ? 5 : raw)))
            let item = DispatchWorkItem { [weak self] in self?.alarmSound?.stop() }
            muteWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + secs, execute: item)
        }
    }

    // Show banner even while app is active (menubar apps are always "active")
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }

    private func registerBundledFonts() {
        let names = ["PressStart2P-Regular.ttf", "VT323-Regular.ttf"]
        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "Fonts") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}
