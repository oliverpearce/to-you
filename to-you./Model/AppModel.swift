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
    @Published private(set) var secondsLeft: Int = 25 * 60
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false

    @Published var increaseContrastIcon: Bool = UserDefaults.standard.bool(forKey: "increaseContrastIcon")
    @Published var hudVisible: Bool = UserDefaults.standard.bool(forKey: "hudVisible")
    @Published var showRainInPopover: Bool = UserDefaults.standard.bool(forKey: "showRainInPopover")

    // ASCII rain published each tick (used only in popover if enabled)
    @Published private(set) var asciiRain: String = ""

    // Callbacks for AppDelegate wiring
    var onTick: ((Int) -> Void)?
    var onFinish: (() -> Void)?

    private let engine = TimerEngine()
    private var bag = Set<AnyCancellable>()

    init() {
        engine.tick
            .receive(on: DispatchQueue.main)
            .sink { [weak self] left in
                guard let self else { return }
                self.secondsLeft = max(0, left)
                self.isRunning = self.engine.isRunning
                if self.isRunning { self.isPaused = false }
                self.asciiRain = RainASCII.frame(width: 26, height: 5, seed: left)
                self.onTick?(left)
                if left == 0 {
                    self.isRunning = false
                    self.isPaused = false
                    self.onFinish?()
                }
            }.store(in: &bag)
    }

    // MARK: API
    func start(minutes: Int) {
        let seconds = max(1, minutes) * 60
        totalSeconds = seconds
        UserDefaults.standard.set(seconds, forKey: "lastDuration")
        asciiRain = RainASCII.frame(width: 26, height: 5, seed: seconds)
        isPaused = false
        engine.start(duration: seconds)
    }

    func resume() {
        guard isPaused, secondsLeft > 0 else { return }
        isPaused = false
        engine.start(duration: secondsLeft)
    }

    func pause() {
        guard isRunning else { return }
        engine.stop()
        isRunning = false
        isPaused = true
    }

    func stop() {
        engine.stop()
        isRunning = false
        isPaused = false
        secondsLeft = 0
    }

    func reset() {
        engine.stop()
        isRunning = false
        isPaused = false
        secondsLeft = totalSeconds
        asciiRain = RainASCII.frame(width: 26, height: 5, seed: secondsLeft)
    }

    func restart() {
        isPaused = false
        engine.start(duration: totalSeconds)
    }

    func toggleStartStop() { isRunning ? pause() : resume() }

    func formatted(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var formattedTimeLeft: String { formatted(secondsLeft) }
    var progress: Double { guard totalSeconds > 0 else { return 0 }; return 1 - Double(secondsLeft) / Double(totalSeconds) }
}

private extension Int {
    func nonZeroOrDefault(_ d: Int) -> Int { self == 0 ? d : self }
}
