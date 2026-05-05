//
//  FontTheme.swift
//  to-you.

import SwiftUI

enum FontTheme: String, CaseIterable, Identifiable {
    case system  = "System"
    case courier = "Courier"
    case rounded = "Rounded"

    var id: String { rawValue }

    func timerFont(size: CGFloat) -> Font {
        switch self {
        case .system:  return .system(size: size, weight: .semibold)
        case .courier: return .system(size: size, design: .monospaced)
        case .rounded: return .system(size: size, design: .rounded)
        }
    }
}
