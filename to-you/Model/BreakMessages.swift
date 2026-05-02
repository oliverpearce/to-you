//
//  BreakMessages.swift
//  to-you.

enum BreakMessages {
    static let all: [String] = [
        "enjoy your break now!",
        "take a quick break!",
        "take some deep breaths…",
        "maybe a short scroll…",
        "time to just exist…",
        "relax for a bit!",
        "go get some water!",
        "maybe a little stretching...",
        "blink and look away...",
        "stand up for a sec!",
        "your brain says thanks!",
    ]

    static func random() -> String {
        all.randomElement() ?? all[0]
    }
}
