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

    @Published var hudVisible: Bool = false

    var onTick: ((Int) -> Void)?
    var onFinish: (() -> Void)?

    private let engine = TimerEngine()
    private var bag = Set<AnyCancellable>()

    init() {
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
                    self.isFinished = true
                    self.onFinish?()
                }
            }
            .store(in: &bag)
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
        if h > 0 { return m > 0 ? "\(h)hr \(m)m \(s)s" : "\(h)hr \(s)s" }
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

