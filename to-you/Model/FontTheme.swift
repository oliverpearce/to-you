//
//  FontTheme.swift
//  to-you.

import SwiftUI

enum FontTheme: String, CaseIterable, Identifiable {
    case system   = "System"
    case eightBit = "8-Bit"
    case vt323    = "VT323"
    case courier  = "Courier"
    case rounded  = "Rounded"

    var id: String { rawValue }

    func timerFont(size: CGFloat) -> Font {
        switch self {
        case .system:   return .system(size: size, weight: .semibold)
        case .eightBit: return .custom("PressStart2P-Regular", size: size)
        case .vt323:    return .custom("VT323-Regular", size: size)
        case .courier:  return .system(size: size, design: .monospaced)
        case .rounded:  return .system(size: size, design: .rounded)
        }
    }
}
