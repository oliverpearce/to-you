//
//  TimerEngine.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import Foundation
import Combine

/// Monotonic, sleep‑resilient timer based on GCD
final class TimerEngine {
    private var timer: DispatchSourceTimer?
    private var endDate: Date?
    private let subject = PassthroughSubject<Int, Never>()
    var tick: AnyPublisher<Int, Never> { subject.eraseToAnyPublisher() }
    var isRunning: Bool { timer != nil }

    func start(duration seconds: Int) {
        endDate = Date().addingTimeInterval(TimeInterval(seconds))
        timer?.cancel(); timer = nil
        let t = DispatchSource.makeTimerSource(flags: [], queue: .main)
        t.schedule(deadline: .now(), repeating: 1.0, leeway: .milliseconds(50))
        t.setEventHandler { [weak self] in
            guard let self, let end = self.endDate else { return }
            let left = max(0, Int(end.timeIntervalSinceNow.rounded()))
            self.subject.send(left)
            if left == 0 { self.stop() }
        }
        t.resume()
        timer = t
    }

    func stop() {
        timer?.cancel(); timer = nil; endDate = nil
        // Intentionally do not send a final 0 here; callers manage state when stopping/pausing.
    }
}
