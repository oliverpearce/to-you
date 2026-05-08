//
//  HUDTimerView.swift
//  to-you.

import SwiftUI

struct HUDTimerView: View {
    @ObservedObject var model: AppModel
    let onClose: () -> Void
    let openSettings: () -> Void

    @AppStorage("selectedFont")     private var fontTheme: FontTheme = .system
    @AppStorage("selectedWeather")  private var weather: WeatherType = .rain
    @AppStorage("timeFormat")       private var timeFormat: TimeFormat = .clock
    @AppStorage("showSeconds")      private var showSeconds: Bool = true
    @State private var isHovering = false

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
                    let tick = model.totalSeconds - model.secondsLeft
                    let art = WeatherScene.frame(width: cols, height: rows, tick: tick,
                                                weather: weather, finished: model.isFinished,
                                                showClouds: showClouds)
                    if model.isFinished {
                        TimelineView(.animation) { tl in
                            let t = tl.date.timeIntervalSinceReferenceDate / 3.0
                            let hue = t.truncatingRemainder(dividingBy: 1.0)
                            Text(art)
                                .font(.system(size: 9, design: .monospaced))
                                .lineSpacing(0)
                                .foregroundStyle(LinearGradient(colors: [
                                    Color(hue: hue,                                          saturation: 0.85, brightness: 1.0),
                                    Color(hue: (hue + 0.25).truncatingRemainder(dividingBy: 1), saturation: 0.85, brightness: 1.0),
                                    Color(hue: (hue + 0.50).truncatingRemainder(dividingBy: 1), saturation: 0.85, brightness: 1.0),
                                    Color(hue: (hue + 0.75).truncatingRemainder(dividingBy: 1), saturation: 0.85, brightness: 1.0),
                                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    } else {
                        Text(art)
                            .font(.system(size: 9, design: .monospaced))
                            .lineSpacing(0)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .allowsHitTesting(false)
                    }
                }

                // LAYER 1: Timer — always visible
                let hudLabel: String = {
                    switch (timeFormat, showSeconds) {
                    case (.clock, true):  return model.formattedTimeLeft
                    case (.clock, false): return model.formattedNoSeconds(model.secondsLeft)
                    case (.wordy, true):  return model.shortFormattedWithSeconds(model.secondsLeft)
                    case (.wordy, false): return model.shortFormatted(model.secondsLeft)
                    }
                }()
                Text(hudLabel)
                    .font(fontTheme.timerFont(size: timerSize))
                    .fontWeight(model.isBreakTimer ? .bold : nil)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .shadow(color: .black.opacity(isMinimal ? 0 : 0.4), radius: 3, x: 0, y: 1)
                    .foregroundStyle(model.isBreakTimer ? Color.lavender : Color.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                // Hover controls in an overlay so they never affect the timer text layout
                if isHovering {
                    ZStack {
                        VStack {
                            HStack {
                                circleButton(icon: "xmark", label: "Close") { onClose() }
                                Spacer()
                                circleButton(icon: "arrow.counterclockwise", label: "Restart") { model.start(seconds: model.totalSeconds) }
                            }
                            Spacer()
                            HStack {
                                circleButton(icon: "gearshape", label: "Settings") { openSettings() }
                                Spacer()
                            }
                        }
                        .padding(6)

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
                            .accessibilityLabel(model.isPaused ? "Resume" : (model.isRunning ? "Pause" : "Start"))
                        }
                    }
                }
            }
        }
        .liquidGlassBackground()
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onHover { isHovering = $0 }
    }

    private func circleButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
