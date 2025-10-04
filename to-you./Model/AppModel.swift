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
    @Published var hudVisible: Bool = UserDefaults.standard.bool(forKey: "hudVisible")

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
                    self.onFinish?()
                }
            }
            .store(in: &bag)
    }

    func start(minutes: Int) {
        let seconds = max(1, minutes) * 60
        totalSeconds = seconds
        UserDefaults.standard.set(seconds, forKey: "lastDuration")
        secondsLeft = seconds
        isPaused = false
        engine.start(duration: seconds)
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
        secondsLeft = totalSeconds
    }

    /// Re-exposed so external callers can format arbitrary seconds
    func formatted(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var formattedTimeLeft: String {
        formatted(secondsLeft)
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1 - Double(secondsLeft) / Double(totalSeconds)
    }
}

private extension Int {
    func nonZeroOrDefault(_ d: Int) -> Int {
        return (self == 0) ? d : self
    }
}

//import Foundation
//import Combine
//
//final class AppModel: ObservableObject {
//    @Published private(set) var totalSeconds: Int = UserDefaults.standard.integer(forKey: "lastDuration").nonZeroOrDefault(25 * 60)
//    @Published private(set) var secondsLeft: Int = 25 * 60
//    @Published private(set) var isRunning: Bool = false
//    @Published private(set) var isPaused: Bool = false  // new
//    @Published var increaseContrastIcon: Bool = UserDefaults.standard.bool(forKey: "increaseContrastIcon")
//    @Published var hudVisible: Bool = UserDefaults.standard.bool(forKey: "hudVisible")
//
//    // Callbacks for external UI wiring
//    var onTick: ((Int) -> Void)?
//    var onFinish: (() -> Void)?
//
//    private let engine = TimerEngine()
//    private var bag = Set<AnyCancellable>()
//
//    init() {
//        engine.tick
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] left in
//                guard let self = self else { return }
//                self.secondsLeft = max(0, left)
//                // engine.isRunning might be true even when paused (depending on engine design),
//                // so we control our own flags.
//                self.isRunning = self.engine.isRunning && !self.isPaused
//                self.onTick?(left)
//                if left == 0 {
//                    self.isRunning = false
//                    self.isPaused = false
//                    self.onFinish?()
//                }
//            }
//            .store(in: &bag)
//    }
//
//    // MARK: - API used by views
//
//    func start(minutes: Int) {
//        let seconds = max(1, minutes) * 60
//        totalSeconds = seconds
//        UserDefaults.standard.set(seconds, forKey: "lastDuration")
//        secondsLeft = seconds
//        isPaused = false
//        engine.start(duration: seconds)
//        isRunning = true
//    }
//
//    func restart() {
//        // restart with the same duration (fresh)
//        secondsLeft = totalSeconds
//        isPaused = false
//        engine.start(duration: totalSeconds)
//        isRunning = true
//    }
//
//    func pause() {
//        guard isRunning else { return }
//        engine.pause()  // you’ll need to add this in TimerEngine
//        isPaused = true
//        isRunning = false
//    }
//
//    func resume() {
//        guard isPaused else { return }
//        engine.resume()  // you’ll need to add this in TimerEngine
//        isPaused = false
//        isRunning = true
//    }
//
//    func reset() {
//        engine.stop()
//        isPaused = false
//        isRunning = false
//        secondsLeft = totalSeconds
//        // Optionally, if you want reset to “clear” everything, you could reset totalSeconds too,
//        // or reset to default.
//    }
//
//    func formatted(_ seconds: Int) -> String {
//        let m = seconds / 60
//        let s = seconds % 60
//        return String(format: "%02d:%02d", m, s)
//    }
//
//    var formattedTimeLeft: String { formatted(secondsLeft) }
//
//    var progress: Double {
//        guard totalSeconds > 0 else { return 0 }
//        return 1 - Double(secondsLeft) / Double(totalSeconds)
//    }
//}
//
//private extension Int {
//    func nonZeroOrDefault(_ d: Int) -> Int {
//        return (self == 0) ? d : self
//    }
//}
