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
        " * * *  ( take a break! c: ) * *",
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
    // Each row was generated at tick (t − row) and has fallen straight down since.
    // Row 0 is always fresh (genTick == tick). Row r shows what row 0 looked like
    // r ticks ago. Nothing moves horizontally — drops fall vertically.
    // Characters: | for body drops, ' for lighter ones.

    private static let rainChars: [Character] = ["|", ",", "|", "'", "!"]

    private static func rainRows(width: Int, height: Int, tick: Int) -> [String] {
        guard height > 0, width > 0 else { return [] }
        var grid = Array(repeating: Array(repeating: Character(" "), count: width), count: height)
        let density = 0.25
        for row in 0..<height {
            let genTick = tick - row
            for col in 0..<width {
                let r = noise(genTick, col)
                guard r < density else { continue }
                grid[row][col] = rainChars[Int(r / density * Double(rainChars.count))]
            }
        }
        return grid.map { String($0) }
    }

    // MARK: - Snow

    private static let snowChars: [Character] = ["*", ".", "'", "+", "*", "·"]

    private static func snowRows(width: Int, height: Int, tick: Int) -> [String] {
        guard height > 0, width > 0 else { return [] }
        var grid = Array(repeating: Array(repeating: Character(" "), count: width), count: height)
        let density = 0.15
        for row in 0..<height {
            let genTick = tick - row
            for col in 0..<width {
                let r = noise(genTick, col)
                guard r < density else { continue }
                grid[row][col] = snowChars[Int(r / density * Double(snowChars.count))]
            }
        }
        return grid.map { String($0) }
    }

    // MARK: - Fog (horizontal drift)
    //
    // Each row gets its own noise-seeded character pattern (generated once from
    // the row index), then tiledScrolled shifts it right by one column every 2
    // ticks — same helper the cloud banner uses, so scrolling is guaranteed visible.

    private static let fogChars: [Character] = ["~", "~", "-", " ", " "]

    private static func fogRows(width: Int, height: Int, tick: Int) -> [String] {
        guard height > 0, width > 0 else { return [] }
        let patternLen = width + 16
        let drift = tick / 2
        return (0..<height).map { row in
            var pattern = ""
            pattern.reserveCapacity(patternLen)
            for i in 0..<patternLen {
                let r = noise(i, row)
                pattern.append(r < 0.50
                    ? fogChars[Int(r / 0.50 * Double(fogChars.count))]
                    : " ")
            }
            return tiledScrolled(pattern, to: width, offset: -drift)
        }
    }

    // MARK: - Helpers

    // Returns a stable value in [0, 1) for a given (tick, position) pair.
    // Same inputs always give the same output — this keeps the animation stable.
    // Swift has no built-in seedable random, so a small hash function is unavoidable here.
    private static func noise(_ tick: Int, _ pos: Int) -> Double {
        var z = UInt64(bitPattern: Int64(tick)) &* 0x9e3779b97f4a7c15
                ^ UInt64(pos) &* 0x6c62272e07bb0142
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
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
