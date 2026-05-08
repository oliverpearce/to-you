//
//  AppModel.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import Foundation
import Combine

final class AppModel: ObservableObject {
    @Published private(set) var totalSeconds: Int = UserDefaults.standard.integer(forKey: "lastDuration").nonZeroOrDefault(25 * 60)
    @Published private(set) var secondsLeft: Int = UserDefaults.standard.integer(forKey: "lastDuration").nonZeroOrDefault(25 * 60)
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var isBreakTimer: Bool = false
    @Published private(set) var cyclesCompleted: Int = 0

    @Published var hudVisible: Bool = false

    var onTick: ((Int) -> Void)?
    var onFinish: (() -> Void)?

    private let engine = TimerEngine()
    private var bag = Set<AnyCancellable>()
    private var workDuration: Int = 0

    init() {
        UserDefaults.standard.register(defaults: [
            "pomodoroEnabled": true,
            "pomodoroCycles": 3,
            "breakPreset1": 5,
            "breakPreset2": 15,
            "breakPreset3": 30,
            "selectedBreakSlot": 1,
            "selectedPresetSlot": 1
        ])

        engine.tick
            .receive(on: DispatchQueue.main)
            .sink { [weak self] left in
                guard let self = self else { return }
                self.secondsLeft = max(0, left)
                self.isRunning = self.engine.isRunning && !self.isPaused
                self.onTick?(left)
                if left == 0 {
                    self.isRunning = false
                    self.isPaused = false
                    self.onFinish?()
                    self.advancePomodoroIfNeeded()
                }
            }
            .store(in: &bag)
    }

    private func advancePomodoroIfNeeded() {
        let enabled = UserDefaults.standard.bool(forKey: "pomodoroEnabled")
        let maxCycles = UserDefaults.standard.integer(forKey: "pomodoroCycles").nonZeroOrDefault(3)
        let breakSlot = UserDefaults.standard.integer(forKey: "selectedBreakSlot").nonZeroOrDefault(1)
        let breakMins: Int
        switch breakSlot {
        case 2:  breakMins = UserDefaults.standard.integer(forKey: "breakPreset2").nonZeroOrDefault(15)
        case 3:  breakMins = UserDefaults.standard.integer(forKey: "breakPreset3").nonZeroOrDefault(30)
        default: breakMins = UserDefaults.standard.integer(forKey: "breakPreset1").nonZeroOrDefault(5)
        }

        guard enabled else {
            isBreakTimer = false
            cyclesCompleted = 0
            isFinished = true
            return
        }

        if !isBreakTimer {
            // Work timer just finished
            if cyclesCompleted < maxCycles {
                cyclesCompleted += 1
                isBreakTimer = true
                let bd = breakMins * 60
                totalSeconds = bd
                secondsLeft = bd
                engine.start(duration: bd)
                isRunning = true
                isFinished = false
                return
            }
        } else {
            // Break timer just finished
            if cyclesCompleted < maxCycles {
                isBreakTimer = false
                let wd = workDuration
                totalSeconds = wd
                secondsLeft = wd
                engine.start(duration: wd)
                isRunning = true
                isFinished = false
                return
            }
        }

        // All cycles done — full stop
        isBreakTimer = false
        cyclesCompleted = 0
        isFinished = true
    }

    func setDuration(seconds: Int) {
        guard !isRunning && !isPaused else { return }
        let s = max(1, seconds)
        totalSeconds = s
        secondsLeft = s
        isFinished = false
        UserDefaults.standard.set(s, forKey: "lastDuration")
    }

    func start(minutes: Int) {
        let secs = max(1, minutes) * 60
        start(seconds: secs)
    }

    func start(seconds: Int) {
        let nonZero = max(1, seconds)
        workDuration = nonZero
        isBreakTimer = false
        cyclesCompleted = 0
        totalSeconds = nonZero
        UserDefaults.standard.set(nonZero, forKey: "lastDuration")
        secondsLeft = nonZero
        isPaused = false
        isFinished = false
        engine.start(duration: nonZero)
        isRunning = true
    }

    func pause() {
        guard isRunning else { return }
        engine.pause()
        isPaused = true
        isRunning = false
    }

    func resume() {
        guard isPaused else { return }
        engine.resume()
        isPaused = false
        isRunning = true
    }

    func reset() {
        engine.stop()
        isPaused = false
        isRunning = false
        isFinished = false
        if isBreakTimer && workDuration > 0 {
            totalSeconds = workDuration
            UserDefaults.standard.set(workDuration, forKey: "lastDuration")
        }
        isBreakTimer = false
        cyclesCompleted = 0
        secondsLeft = totalSeconds
    }

    func formatted(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    var formattedTimeLeft: String {
        formatted(secondsLeft)
    }

    func shortFormatted(_ seconds: Int) -> String {
        if seconds >= 3600 {
            let hrs = seconds / 3600
            let mins = (seconds % 3600) / 60
            return mins > 0 ? "\(hrs)hr \(mins)m" : "\(hrs)hr"
        }
        return "\(seconds / 60)m"
    }

    func formattedNoSeconds(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h > 0 { return String(format: "%d:%02d", h, m) }
        return "\(m)"
    }

    func shortFormattedWithSeconds(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return "\(h)hr \(m)m \(s)s" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0.0 }
        return 1.0 - Double(secondsLeft) / Double(totalSeconds)
    }
}

private extension Int {
    func nonZeroOrDefault(_ d: Int) -> Int {
        (self == 0) ? d : self
    }
}

