//
//  WeatherScene.swift
//  to-you.

import Foundation

enum WeatherType: String, CaseIterable, Identifiable {
    case none = "None"
    case rain = "Rain"
    case snow = "Snow"
    case fog  = "Fog"
    var id: String { rawValue }
}

struct WeatherScene {
    // Three-cloud banner — tiles seamlessly and scrolls horizontally
    private static let cloudArt: [String] = [
        "  .---.   .---------.   .----.  ",
        " (     ) (           ) (      ) ",
        "  `---'   `---------'   `----'  "
    ]

    // Sunshine scene shown when timer finishes
    private static let sunshineArt: [String] = [
        "  *      *    *      *    *     ",
        "     *      *    *      *    *  ",
        "  *    *   \\    |    /   *    * ",
        "    *    \\  \\   |   /  /    *   ",
        "  *    \\  \\  \\  |  /  /  /   *  ",
        " * * *  ( take a break! :) ) * *",
        "  *    /  /  /  |  \\  \\  \\   *  ",
        "    *    /  /   |   \\  \\    *   ",
        "  *    *   /    |    \\   *    * ",
        "     *      *    *      *    *  ",
        "  *      *    *      *    *     ",
    ]

    // MARK: - Public API

    /// Returns `height` newline-joined lines, each exactly `width` chars.
    /// `tick` = Int(Date().timeIntervalSinceReferenceDate) — increments every second.
    static func frame(width: Int, height: Int, tick: Int,
                      weather: WeatherType, finished: Bool,
                      showClouds: Bool = true) -> String {
        if finished {
            return sunshineFrame(width: width, height: height)
        }
        guard weather != .none else {
            return Array(repeating: padded("", to: width), count: height).joined(separator: "\n")
        }
        // Clouds scroll at 1 char/sec — same direction as rain/snow body
        let cloudLen = cloudArt[0].count
        let cloudScroll = tick % max(1, cloudLen)
        let clouds = showClouds ? cloudArt.map { tiledScrolled($0, to: width, offset: cloudScroll) } : []
        let bodyHeight = max(0, height - clouds.count)
        let body: [String]
        switch weather {
        case .rain: body = rainRows(width: width, height: bodyHeight, tick: tick)
        case .snow: body = snowRows(width: width, height: bodyHeight, tick: tick)
        case .fog:  body = fogRows(width: width, height: bodyHeight, tick: tick)
        case .none: body = Array(repeating: padded("", to: width), count: bodyHeight)
        }
        return (clouds + body).joined(separator: "\n")
    }

    // MARK: - Sunshine

    private static func sunshineFrame(width: Int, height: Int) -> String {
        var lines = sunshineArt.map { padded($0, to: width) }
        while lines.count < height { lines.append(padded("", to: width)) }
        return lines.prefix(height).joined(separator: "\n")
    }

    // MARK: - Rain
    //
    // Field approach: show '/' at (r,c) when uMod = (r − tick + phase) mod period < dropLen.
    // u = r − tick is FIXED for a char moving (+1 row, −1 col) per tick, so any visible
    // '/' is guaranteed at (r+1, c−1) the next tick — zero mid-screen despawning.
    // period = height + dropLen ensures each drop lives long enough to cross the screen.

    private static func rainRows(width: Int, height: Int, tick: Int) -> [String] {
        guard height > 0, width > 0 else { return [] }
        var grid = Array(repeating: Array(repeating: Character(" "), count: width), count: height)

        let numDiags = width + height - 1
        for d in 0..<numDiags {
            var rng = SeededRandom(seed: colSeed(d, salt: 77))
            guard rng.nextDouble() < 0.88 else { continue }

            let dropLen = 1 + Int(rng.nextDouble() * 2)   // 1–2 chars
            let period  = height + dropLen                 // guarantees full-screen traversal
            let phase   = Int(rng.nextDouble() * Double(period))

            let rMin = max(0, d - (width - 1))
            let rMax = min(height - 1, d)
            for r in rMin...rMax {
                let uMod = ((r - tick + phase) % period + period) % period
                if uMod < dropLen {
                    grid[r][d - r] = "/"
                }
            }
        }
        return grid.map { String($0) }
    }

    // MARK: - Snow (flakes fall & drift, whole scene scrolls left 1 col/sec)

    private static let snowChars: [Character] = ["*", ".", "'", "+", "*", "·"]

    private static func snowRows(width: Int, height: Int, tick: Int) -> [String] {
        guard height > 0, width > 0 else { return [] }
        var grid = Array(repeating: Array(repeating: Character(" "), count: width), count: height)
        let snowTick = tick / 2       // flakes fall at half speed
        let scroll   = tick % width   // whole scene scrolls left 1 col/sec

        for col in 0..<width {
            var rng = SeededRandom(seed: colSeed(col, salt: 999))
            guard rng.nextDouble() < 0.65 else { continue }

            let period   = 3 + Int(rng.nextDouble() * 4)
            let phase    = Int(rng.nextDouble() * Double(period))
            let ch       = snowChars[Int(rng.nextDouble() * Double(snowChars.count))]
            let driftAmt = Int(rng.nextDouble() * 3) - 1   // −1, 0, or +1

            for row in 0..<height {
                let adj = ((row - snowTick + phase) % period + period) % period
                guard adj == 0 else { continue }
                let drift    = (tick / 3) % 2 == 0 ? driftAmt : 0
                let rawCol   = col + drift - scroll
                let dc       = ((rawCol % width) + width) % width
                grid[row][dc] = ch
            }
        }
        return grid.map { String($0) }
    }

    // MARK: - Fog (horizontal drifting wisps — each row at its own speed)

    private static let fogChars: [Character] = ["~", "~", "-", "·", "~", " ", " "]

    private static func fogRows(width: Int, height: Int, tick: Int) -> [String] {
        guard height > 0, width > 0 else { return [] }
        var lines: [String] = []
        for row in 0..<height {
            let rowSpeed = 1 + (row % 3)
            let shift    = (tick * rowSpeed) % width
            var line     = Array(repeating: Character(" "), count: width)
            var rowRng   = SeededRandom(seed: UInt64(bitPattern: Int64(row &* 31337 &+ 7)))
            let density  = 0.3 + rowRng.nextDouble() * 0.5
            for col in 0..<width {
                let srcCol = (col + shift) % width
                var rng = SeededRandom(seed: colSeed(srcCol, salt: UInt64(row &* 13)))
                if rng.nextDouble() < density {
                    line[col] = fogChars[Int(rng.nextDouble() * Double(fogChars.count))]
                }
            }
            lines.append(String(line))
        }
        return lines
    }

    // MARK: - Helpers

    private static func colSeed(_ col: Int, salt: UInt64) -> UInt64 {
        UInt64(bitPattern: Int64(col &* 2654435761 &+ 1013904223)) &+ salt
    }

    private static func padded(_ s: String, to width: Int) -> String {
        guard s.count < width else { return String(s.prefix(width)) }
        return s + String(repeating: " ", count: width - s.count)
    }

    private static func tiled(_ s: String, to width: Int) -> String {
        guard width > 0, !s.isEmpty else { return String(repeating: " ", count: max(0, width)) }
        var result = ""
        while result.count < width { result += s }
        return String(result.prefix(width))
    }

    /// Like `tiled` but starts at `offset` into the pattern — makes it scroll.
    private static func tiledScrolled(_ s: String, to width: Int, offset: Int) -> String {
        guard width > 0, !s.isEmpty else { return String(repeating: " ", count: max(0, width)) }
        let len   = s.count
        let start = ((offset % len) + len) % len
        var buf   = ""
        buf.reserveCapacity(width)
        var i = start
        while buf.count < width {
            buf.append(s[s.index(s.startIndex, offsetBy: i % len)])
            i += 1
        }
        return buf
    }
}

private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        var x = state; x ^= x >> 12; x ^= x << 25; x ^= x >> 27; state = x
        return x &* 2685821657736338717
    }
    mutating func nextDouble() -> Double { Double(next() >> 11) / Double(1 << 53) }
}
