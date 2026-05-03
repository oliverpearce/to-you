//
//  HUDTimerView.swift
//  to-you.

import SwiftUI

struct HUDTimerView: View {
    @ObservedObject var model: AppModel
    let onClose: () -> Void

    @AppStorage("selectedFont")    private var fontTheme: FontTheme = .system
    @AppStorage("selectedWeather") private var weather: WeatherType = .rain
    @State private var isHovering = false
    @State private var frozenTick: Int? = Int(Date().timeIntervalSinceReferenceDate)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let isMinimal = w < 150
            let isCompact = !isMinimal && w < 210
            let showClouds = !isMinimal && !isCompact
            let cols = max(10, Int(w / 5.4))
            let rows = max(5,  Int(h / 10.8))
            let timerSize: CGFloat = isMinimal ? 30 : (isCompact ? 28 : 34)
            let showScene = !isMinimal && (weather != .none || model.isFinished)

            ZStack(alignment: .topLeading) {

                // LAYER 0: Weather scene
                if showScene {
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        let rawTick = Int(context.date.timeIntervalSinceReferenceDate)
                        let tick = frozenTick ?? rawTick
                        Text(WeatherScene.frame(width: cols, height: rows, tick: tick,
                                               weather: weather, finished: model.isFinished,
                                               showClouds: showClouds))
                            .font(.system(size: 9, design: .monospaced))
                            .lineSpacing(0)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .allowsHitTesting(false)
                }

                // LAYER 1: Timer — always visible
                Text(model.formattedTimeLeft)
                    .font(fontTheme.timerFont(size: timerSize))
                    .shadow(color: .black.opacity(isMinimal ? 0 : 0.4), radius: 3, x: 0, y: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)

                // LAYER 2: Hover controls (no dark overlay)
                if isHovering {
                    ZStack {
                        // Corner buttons
                        VStack {
                            HStack {
                                circleButton(icon: "xmark") { onClose() }
                                Spacer()
                                circleButton(icon: "arrow.counterclockwise") { model.start(seconds: model.totalSeconds) }
                            }
                            Spacer()
                        }
                        .padding(6)

                        // Centre: play / pause / resume (hidden when finished)
                        if !model.isFinished {
                            let icon = model.isPaused ? "play.fill" : (model.isRunning ? "pause.fill" : "play.fill")
                            let sz: CGFloat = isMinimal ? 22 : 34
                            let iconSz: CGFloat = isMinimal ? 11 : 16
                            let r: CGFloat = isMinimal ? 6 : 10
                            Button {
                                if model.isPaused       { model.resume() }
                                else if model.isRunning { model.pause() }
                                else                    { model.start(seconds: model.totalSeconds) }
                            } label: {
                                Image(systemName: icon)
                                    .font(.system(size: iconSz, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: sz, height: sz)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: r))
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .liquidGlassBackground()
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onHover { isHovering = $0 }
        .onChange(of: model.isRunning) { _, running in
            if running {
                frozenTick = nil
            } else {
                frozenTick = Int(Date().timeIntervalSinceReferenceDate)
            }
        }
    }

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }
}
