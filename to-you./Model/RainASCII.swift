//
//  RainASCII.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import Foundation

/// Lightweight ASCII rain generator for monospaced display.
/// Produces a small grid of characters like `|`, `.`, and `'` with mostly spaces for subtlety.
struct RainASCII {
    private static let drops: [Character] = ["|", ".", "'", " "]

    /// Deterministic frame based on a seed (e.g., current seconds left) for smooth updates.
    static func frame(width: Int = 18, height: Int = 6, seed: Int) -> String {
        var rng = SeededRandom(seed: UInt64(bitPattern: Int64(seed)))
        var lines: [String] = []
        for _ in 0..<height {
            var row: [Character] = []
            for _ in 0..<width {
                // Bias towards spaces for subtle effect
                let r = rng.nextDouble()
                let ch: Character
                switch r {
                case 0..<0.08: ch = "|"
                case 0.08..<0.18: ch = "'"
                case 0.18..<0.34: ch = "."
                default: ch = " "
                }
                row.append(ch)
            }
            lines.append(String(row))
        }
        return lines.joined(separator: "\n")
    }
}

// Simple xorshift-style RNG
private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed &* 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        var x = state
        x ^= x >> 12
        x ^= x << 25
        x ^= x >> 27
        state = x
        return x &* 2685821657736338717
    }
    mutating func nextDouble() -> Double { Double(next() >> 11) / Double(1 << 53) }
}
