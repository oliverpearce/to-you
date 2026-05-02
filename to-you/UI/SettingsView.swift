//
//  SettingsView.swift
//  to-you.

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("preset1")              private var preset1: Int = 25
    @AppStorage("preset2")              private var preset2: Int = 30
    @AppStorage("preset3")              private var preset3: Int = 45
    @AppStorage("alarmVolume")          private var alarmVolume: Double = 0.5
    @AppStorage("autoMuteAlarm")        private var autoMuteAlarm: Bool = false
    @AppStorage("autoMuteDuration")     private var autoMuteDuration: Int = 5
    @AppStorage("menuBarStyle")         private var menuBarStyle: String = "compact"
    @AppStorage("selectedFont")         private var fontTheme: FontTheme = .system
    @AppStorage("selectedWeather")      private var weather: WeatherType = .rain
    @AppStorage("hudSize")              private var hudSize: HUDSize = .compact
    @AppStorage("shortTimeFormat")      private var shortTimeFormat: Bool = false
    @AppStorage("liquidGlass")          private var liquidGlass: Bool = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("launchAtLogin")        private var launchAtLogin: Bool = false

    @State private var applyFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // — Timer presets —
            section {
                HStack(spacing: 4) {
                    Text("timer presets (min):").foregroundStyle(.secondary)
                    InfoTipButton("Quick-select durations shown as buttons in the popover.")
                }
                HStack(spacing: 20) {
                    HoverStepper(value: $preset1, range: 1...180)
                    HoverStepper(value: $preset2, range: 1...180)
                    HoverStepper(value: $preset3, range: 1...180)
                }
            }

            Divider()

            // — Alarm volume —
            section {
                HStack(spacing: 4) {
                    Text("alarm volume:").foregroundStyle(.secondary)
                    InfoTipButton("Volume of the chime played when the timer finishes.")
                }
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                    Slider(value: $alarmVolume, in: 0...1)
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                }
                Button("Test Alarm") {
                    NotificationCenter.default.post(name: .testAlarm, object: nil)
                }
                .buttonStyle(.bordered)
                HStack(spacing: 6) {
                    Toggle("auto-mute after", isOn: $autoMuteAlarm)
                    HoverStepper(value: $autoMuteDuration, range: 1...60)
                    Text("sec")
                    InfoTipButton("Silences the alarm after the set number of seconds (1–60).")
                }
            }

            Divider()

            // — Appearance —
            section {
                Text("appearance:").foregroundStyle(.secondary)
                HStack {
                    Text("font").foregroundStyle(.secondary)
                    Picker("", selection: $fontTheme) {
                        ForEach(FontTheme.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                HStack {
                    Text("weather").foregroundStyle(.secondary)
                    Picker("", selection: $weather) {
                        ForEach(WeatherType.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                HStack {
                    HStack(spacing: 4) {
                        Text("hud size").foregroundStyle(.secondary)
                        InfoTipButton("Minimal: just the timer.\nDefault: timer with weather animation.")
                    }
                    Picker("", selection: $hudSize) {
                        ForEach(HUDSize.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                HStack(spacing: 4) {
                    Toggle("show umbrella in menu bar", isOn: Binding(
                        get: { menuBarStyle == "expanded" },
                        set: { menuBarStyle = $0 ? "expanded" : "compact" }
                    ))
                    InfoTipButton("Shows the umbrella ☂ icon next to the countdown in the menu bar.")
                }
                HStack(spacing: 4) {
                    Toggle("short time labels", isOn: $shortTimeFormat)
                    InfoTipButton("Off: shows '25:00' and '1:30:00'.\nOn: shows '25m' and '1hr 30m', updating by the minute.")
                }
                HStack(spacing: 4) {
                    Toggle("liquid glass", isOn: $liquidGlass)
                    InfoTipButton("Frosted glass background on the floating display.")
                }
            }

            Divider()

            // — Footer —
            section {
                HStack {
                    HStack(spacing: 4) {
                        Toggle("launch at login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { _, enabled in
                                if enabled {
                                    try? SMAppService.mainApp.register()
                                } else {
                                    try? SMAppService.mainApp.unregister()
                                }
                            }
                        InfoTipButton("Starts to-you. automatically when you log in.")
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Toggle("notifications", isOn: $notificationsEnabled)
                        InfoTipButton("Shows a system notification when the timer finishes.")
                    }
                }
                HStack {
                    Spacer()
                    Button(applyFeedback ? "✓ Applied" : "Apply Changes") {
                        NotificationCenter.default.post(name: .hudSettingsDidChange, object: nil)
                        applyFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            applyFeedback = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(applyFeedback)
                }
            }
        }
        .font(.system(.body, design: .monospaced))
        .frame(width: 380)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<C: View>(@ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
}

// MARK: - Scrub field (tap to type, drag up/down to change — mirrors the popover timer)

private struct HoverStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    @State private var isEditing = false
    @State private var editText  = ""
    @State private var dragStart: Int? = nil
    @State private var hovering  = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            if isEditing {
                TextField("", text: $editText)
                    .focused($focused)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .onSubmit { commit() }
                    .onExitCommand { isEditing = false }
                    .onChange(of: editText) { _, text in
                        if let v = Int(text.trimmingCharacters(in: .whitespaces)) {
                            value = min(range.upperBound, max(range.lowerBound, v))
                        }
                    }
            } else {
                Text("\(value)")
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(hovering ? 0.1 : 0))
                    )
                    .animation(.easeInOut(duration: 0.1), value: hovering)
                    .onHover { hovering = $0 }
                    .onTapGesture { beginEdit() }
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { val in
                                if dragStart == nil { dragStart = value }
                                let delta = Int(-(val.translation.height) / 3.0)
                                value = min(range.upperBound, max(range.lowerBound, (dragStart ?? value) + delta))
                            }
                            .onEnded { _ in dragStart = nil }
                    )
            }
        }
        .frame(width: 48)
    }

    private func beginEdit() {
        editText  = "\(value)"
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
    }

    private func commit() {
        if let v = Int(editText.trimmingCharacters(in: .whitespaces)) {
            value = min(range.upperBound, max(range.lowerBound, v))
        }
        editText  = "\(value)"
        isEditing = false
    }
}

// MARK: - Info tip button (click to show popover)

private struct InfoTipButton: View {
    let text: String
    @State private var showing = false

    init(_ text: String) { self.text = text }

    var body: some View {
        Button { showing.toggle() } label: {
            Image(systemName: "questionmark.circle")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showing, arrowEdge: .bottom) {
            Text(text)
                .font(.callout)
                .multilineTextAlignment(.leading)
                .padding(12)
                .frame(width: 200, alignment: .leading)
        }
    }
}
