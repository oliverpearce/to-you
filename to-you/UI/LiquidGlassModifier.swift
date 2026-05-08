//
//  LiquidGlassModifier.swift
//  to-you.

import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    @AppStorage("liquidGlass") private var liquidGlass: Bool = true

    func body(content: Content) -> some View {
        if liquidGlass {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        } else {
            content
                .background(Color(nsColor: .windowBackgroundColor),
                            in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

extension View {
    func liquidGlassBackground() -> some View {
        modifier(LiquidGlassModifier())
    }
}

extension Color {
    static let lavender = Color(hue: 0.75, saturation: 0.45, brightness: 1.0)
}
