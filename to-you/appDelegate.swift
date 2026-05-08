//
//  appDelegate.swift
//  to-you.

import Cocoa
import SwiftUI
import Combine
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    let model = AppModel()
    private let hud = FloatingHUD()
    private let settings = SettingsWindowController()
    private var bag = Set<AnyCancellable>()
    private var alarmSound: NSSound?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menubar status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "umbrella", accessibilityDescription: "to-you timer")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Reactive menubar updates — observe all four together to avoid mid-flight gaps
        Publishers.CombineLatest(
            Publishers.CombineLatest3(model.$secondsLeft, model.$isPaused, model.$isRunning),
            model.$isBreakTimer
        )
        .map { inner, isBreakTimer in (inner.0, inner.1, inner.2, isBreakTimer) }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] secondsLeft, isPaused, isRunning, isBreakTimer in
            guard let self else { return }
            if isRunning || isPaused || isBreakTimer {
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

        NotificationCenter.default.addObserver(
            forName: .showHUD, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.model.hudVisible {
                self.hud.hide()
            } else {
                self.hud.show(model: self.model, onClose: { [weak self] in self?.hud.hide() }, openSettings: { [weak self] in
                    guard let self else { return }
                    if self.model.isRunning { self.model.pause() }
                    self.settings.show()
                })
            }
        }

        // Popover content
        let content = TimerPopoverView(
            model: model,
            openSettings: { [weak self] in
                guard let self else { return }
                if self.model.isRunning { self.model.pause() }
                self.popover.performClose(nil)
                self.settings.show()
            },
            closePopover: { [weak self] in
                self?.popover.performClose(nil)
            },
            toggleHUD: { [weak self] in
                guard let self else { return }
                if self.model.hudVisible {
                    self.hud.hide()
                } else {
                    self.hud.show(model: self.model, onClose: { [weak self] in self?.hud.hide() }, openSettings: { [weak self] in
                        guard let self else { return }
                        if self.model.isRunning { self.model.pause() }
                        self.settings.show()
                    })
                }
            }
        )
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 320, height: 168)
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = FirstMouseHostingView(rootView: content)
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
        statusItem.isVisible = true
        let expanded = UserDefaults.standard.string(forKey: "menuBarStyle") == "expanded"
        button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        button.title = model.formatted(secondsLeft) + (isPaused ? " ⏸" : "")
        if expanded {
            button.image = NSImage(systemSymbolName: "umbrella.fill", accessibilityDescription: "to-you timer")
            button.image?.isTemplate = true
            button.imagePosition = .imageLeft
        } else {
            button.image = nil
            button.imagePosition = .noImage
        }
    }

    private func resetStatusButton() {
        guard let button = statusItem.button else { return }
        statusItem.isVisible = true
        button.font = nil
        button.title = ""
        if let img = NSImage(systemSymbolName: "umbrella", accessibilityDescription: "umbrella") {
            img.isTemplate = true
            img.accessibilityDescription = "to-you timer"
            button.image = img
            button.imagePosition = .imageOnly
        } else {
            button.image = nil
            button.title = "☂"
            button.imagePosition = .noImage
        }
    }

    private func notifyAndReveal() {
        resetStatusButton()
        playAlarm()

        let weatherRaw = UserDefaults.standard.string(forKey: "selectedWeather") ?? "Rain"
        let weatherName = weatherRaw == "None" ? "storm" : weatherRaw.lowercased()
        let title = "The \(weatherName) has cleared."
        let body = BreakMessages.random()

        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        FinishedBanner.show(title: title, body: body)
    }

    private func playAlarm() {
        alarmSound?.stop()
        guard !UserDefaults.standard.bool(forKey: "forceMuteAlarm") else { return }
        let volume = Float(UserDefaults.standard.object(forKey: "alarmVolume") as? Double ?? 0.5)
        guard volume > 0, let sound = NSSound(named: NSSound.Name("Glass")) else { return }
        sound.volume = volume
        sound.play()
        alarmSound = sound
    }
}
