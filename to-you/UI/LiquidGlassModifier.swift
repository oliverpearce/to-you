//
//  LiquidGlassModifier.swift
//  to-you.

import AppKit
import SwiftUI

// Forces NSVisualEffectView.state = .active so the material never shifts appearance
// based on key-window state (the HUD panel is .nonactivatingPanel and never becomes key).
private struct ActiveVisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct LiquidGlassModifier: ViewModifier {
    @AppStorage("liquidGlass") private var liquidGlass: Bool = true

    func body(content: Content) -> some View {
        if liquidGlass {
            content
                .background {
                    ActiveVisualEffectBackground()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
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
