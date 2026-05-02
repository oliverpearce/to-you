//
//  HUDSize.swift
//  to-you.

import CoreGraphics

enum HUDSize: String, CaseIterable, Identifiable {
    case minimal = "Minimal"  // 130×50 — timer only
    case compact = "Default"  // 175×88 — timer + weather body

    var id: String { rawValue }

    var panelSize: CGSize {
        switch self {
        case .minimal: return CGSize(width: 130, height: 50)
        case .compact: return CGSize(width: 175, height: 88)
        }
    }
}
