//
//  AsciiUI.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import Foundation

struct AsciiUI {
    static func center(_ text: String, width: Int) -> String {
        let len = text.count
        if len >= width { return String(text.prefix(width)) }
        let left = (width - len) / 2
        let right = width - len - left
        return String(repeating: " ", count: left) + text + String(repeating: " ", count: right)
    }

    static func progressBar(width: Int, progress: Double) -> String {
        let p = max(0, min(1, progress))
        let fill = Int(round(p * Double(width)))
        let bar = String(repeating: "#", count: max(0, fill)) + String(repeating: ".", count: max(0, width - fill))
        let pct = Int(round(p * 100))
        return "[" + bar + "] " + String(format: "%3d%%", pct)
    }

    static func boxed(lines: [String], width: Int) -> String {
        let inner = max(width - 2, 0)
        let top = "+" + String(repeating: "-", count: inner) + "+"
        let bottom = top
        let body = lines.map { line -> String in
            let trimmed = String(line.prefix(inner))
            let pad = max(inner - trimmed.count, 0)
            return "|" + trimmed + String(repeating: " ", count: pad) + "|"
        }
        return ([top] + body + [bottom]).joined(separator: "\n")
    }

    static func hud(time: String, progress: Double, rain: String, width: Int = 34) -> String {
        let inner = max(width - 2, 0)
        let prog = progressBar(width: max(inner - 10, 8), progress: progress)
        let rainLines: [String] = rain.isEmpty ? [] : rain.split(separator: "\n").map(String.init)
        var lines: [String] = []
        lines.append(center("time " + time, width: inner))
        lines.append(prog)
        lines.append(contentsOf: rainLines)
        return boxed(lines: lines, width: width)
    }

    static func panel(title: String, time: String, progress: Double, rain: String, width: Int = 44) -> String {
        let inner = max(width - 2, 0)
        let prog = progressBar(width: max(inner - 12, 12), progress: progress)
        var lines: [String] = []
        lines.append(center(":: " + title + " ::", width: inner))
        lines.append(center("remaining " + time, width: inner))
        lines.append(prog)
        let rainLines: [String] = rain.isEmpty ? [] : rain.split(separator: "\n").map(String.init)
        lines.append(contentsOf: rainLines)
        return boxed(lines: lines, width: width)
    }
}
