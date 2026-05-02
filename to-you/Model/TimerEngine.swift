//
//  TimerEngine.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import Foundation
import Combine

final class TimerEngine {
    private var timer: DispatchSourceTimer?
    private var endDate: Date?
    private var remainingSeconds: Int?

    private let subject = PassthroughSubject<Int, Never>()
    var tick: AnyPublisher<Int, Never> { subject.eraseToAnyPublisher() }

    var isRunning: Bool {
        timer != nil
    }

    func start(duration seconds: Int) {
        remainingSeconds = nil
        scheduleTimer(withRemaining: seconds)
    }

    func pause() {
        guard isRunning else { return }
        if let end = endDate {
            let left = max(0, Int(end.timeIntervalSinceNow.rounded()))
            remainingSeconds = left
            subject.send(left)
        }
        timer?.cancel()
        timer = nil
        endDate = nil
    }

    func resume() {
        guard timer == nil, let rem = remainingSeconds else { return }
        scheduleTimer(withRemaining: rem)
        remainingSeconds = nil
    }

    func stop() {
        timer?.cancel()
        timer = nil
        endDate = nil
        remainingSeconds = nil
        subject.send(0)
    }

    private func scheduleTimer(withRemaining seconds: Int) {
        endDate = Date().addingTimeInterval(TimeInterval(seconds))
        timer?.cancel()
        timer = nil

        let t = DispatchSource.makeTimerSource(flags: [], queue: .main)
        t.schedule(deadline: .now(), repeating: 1.0, leeway: .milliseconds(50))
        t.setEventHandler { [weak self] in
            guard let self = self, let end = self.endDate else { return }
            let left = max(0, Int(end.timeIntervalSinceNow.rounded()))
            self.subject.send(left)
            if left == 0 {
                self.stop()
            }
        }
        t.resume()
        timer = t
    }
}

