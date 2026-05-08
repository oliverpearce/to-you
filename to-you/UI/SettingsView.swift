//
//  SettingsView.swift
//  to-you.

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("preset1")              private var preset1: Int = 25
    @AppStorage("preset2")              private var preset2: Int = 30
    @AppStorage("preset3")              private var preset3: Int = 45
    @AppStorage("selectedPresetSlot")   private var selectedPresetSlot: Int = 1
    @AppStorage("breakPreset1")         private var breakPreset1: Int = 5
    @AppStorage("breakPreset2")         private var breakPreset2: Int = 15
    @AppStorage("breakPreset3")         private var breakPreset3: Int = 30
    @AppStorage("selectedBreakSlot")    private var selectedBreakSlot: Int = 1
    @AppStorage("pomodoroEnabled")      private var pomodoroEnabled: Bool = true
    @AppStorage("pomodoroCycles")       private var pomodoroCycles: Int = 3
    @AppStorage("alarmVolume")          private var alarmVolume: Double = 0.5
    @AppStorage("menuBarStyle")         private var menuBarStyle: String = "compact"
    @AppStorage("selectedFont")         private var fontTheme: FontTheme = .system
    @AppStorage("selectedWeather")      private var weather: WeatherType = .rain
    @AppStorage("hudSize")              private var hudSize: HUDSize = .compact
    @AppStorage("timeFormat")           private var timeFormat: TimeFormat = .clock
    @AppStorage("showSeconds")          private var showSeconds: Bool = true
    @AppStorage("liquidGlass")          private var liquidGlass: Bool = true
    @AppStorage("flashOnInterval")      private var flashOnInterval: Bool = true
    @AppStorage("forceMuteAlarm")       private var forceMuteAlarm: Bool = false
    @AppStorage("goldNotification")     private var goldNotification: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("launchAtLogin")        private var launchAtLogin: Bool = false

    @State private var applyFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // — Timers —
            section {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("timer presets:").foregroundStyle(.secondary)
                            InfoTipButton("Quick-select work timer durations. Single-click to select, double-click to edit. Max: 10 hours (600 min).")
                        }
                        HStack(spacing: 6) {
                            SettingsPresetPill(value: $preset1, isSelected: selectedPresetSlot == 1, range: 1...600) { selectedPresetSlot = 1 }
                            SettingsPresetPill(value: $preset2, isSelected: selectedPresetSlot == 2, range: 1...600) { selectedPresetSlot = 2 }
                            SettingsPresetPill(value: $preset3, isSelected: selectedPresetSlot == 3, range: 1...600) { selectedPresetSlot = 3 }
                        }
                        HStack(spacing: 4) {
                            Toggle("pomodoro", isOn: $pomodoroEnabled)
                            InfoTipButton("Automatically cycles between work and break sessions.")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .padding(.horizontal, 10)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("break length:").foregroundStyle(.secondary)
                            InfoTipButton("Break timer durations for pomodoro mode. Single-click to select, double-click to edit. Max: 10 hours (600 min).")
                        }
                        HStack(spacing: 6) {
                            SettingsPresetPill(value: $breakPreset1, isSelected: selectedBreakSlot == 1, range: 1...600) { selectedBreakSlot = 1 }
                            SettingsPresetPill(value: $breakPreset2, isSelected: selectedBreakSlot == 2, range: 1...600) { selectedBreakSlot = 2 }
                            SettingsPresetPill(value: $breakPreset3, isSelected: selectedBreakSlot == 3, range: 1...600) { selectedBreakSlot = 3 }
                        }
                        HStack(spacing: 4) {
                            Text("cycles:").foregroundStyle(.secondary)
                            HoverStepper(value: $pomodoroCycles, range: 1...5)
                            InfoTipButton("Work+break cycles before stopping. Max 5.")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(pomodoroEnabled ? 1.0 : 0.35)
                    .allowsHitTesting(pomodoroEnabled)
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
                HStack(spacing: 12) {
                    Button("Test Alarm") {
                        NotificationCenter.default.post(name: .testAlarm, object: nil)
                    }
                    .buttonStyle(.bordered)
                    Toggle("force mute", isOn: $forceMuteAlarm)
                }
                HStack(spacing: 4) {
                    Toggle("gold notification", isOn: $goldNotification)
                    InfoTipButton("Makes the timer-finished banner gold with a lustrous metallic finish.")
                }
            }

            Divider()

            // — Display —
            section {
                Text("display:").foregroundStyle(.secondary)
                HStack {
                    Text("font").foregroundStyle(.secondary)
                    Picker("", selection: $fontTheme) {
                        ForEach(FontTheme.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                HStack {
                    Text("time format").foregroundStyle(.secondary)
                    Picker("", selection: $timeFormat) {
                        ForEach(TimeFormat.allCases) { f in Text(f.rawValue).tag(f) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    InfoTipButton("hh:mm:ss — colon-separated (e.g. '25:00').\nhrs m s — wordy style (e.g. '25m 0s').")
                }
                HStack(spacing: 4) {
                    Toggle("show seconds", isOn: $showSeconds)
                    InfoTipButton("Shows seconds in the timer. On: '25:00' or '25m 0s' style. Off: shows only minutes ('25' or '25m').")
                }
                Button {
                    NotificationCenter.default.post(name: .showHUD, object: nil)
                } label: {
                    Label("floating display", systemImage: "macwindow")
                }
                .buttonStyle(.bordered)
            }

            Divider()

            // — Appearance —
            section {
                Text("appearance:").foregroundStyle(.secondary)
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
                    Toggle("liquid glass", isOn: $liquidGlass)
                    InfoTipButton("Frosted glass background on the floating display.")
                }
                HStack(spacing: 4) {
                    Toggle("flash timer", isOn: $flashOnInterval)
                    InfoTipButton("Briefly flashes the timer at each minute boundary.")
                }
            }

            Divider()

            // — Footer —
            section {
                HStack {
                    HStack(spacing: 4) {
                        Toggle("launch at login", isOn: $launchAtLogin)
                            .onChange(of: launchAtLogin) { _, enabled in
                                do {
                                    if enabled {
                                        try SMAppService.mainApp.register()
                                    } else {
                                        try SMAppService.mainApp.unregister()
                                    }
                                } catch {
                                    launchAtLogin = !enabled
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
        .frame(width: 400)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<C: View>(@ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
}

// MARK: - Editable preset pill (tap to edit, drag to change, highlights when selected)

private struct SettingsPresetPill: View {
    @Binding var value: Int
    let isSelected: Bool
    let range: ClosedRange<Int>
    let onSelect: () -> Void

    @State private var isEditing = false
    @State private var editText = ""
    @State private var dragStart: Int? = nil
    @FocusState private var focused: Bool

    private var label: String {
        guard value >= 60 else { return "\(value)m" }
        let h = value / 60, m = value % 60
        return m == 0 ? "\(h)hr" : "\(h)h\(m)m"
    }

    var body: some View {
        ZStack {
            if isEditing {
                TextField("min", text: $editText)
                    .focused($focused)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .onSubmit { commit() }
                    .onExitCommand { isEditing = false }
                    .frame(width: 44)
            } else {
                Text(label)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
                    )
                    .onTapGesture(count: 2) {
                        onSelect()
                        beginEdit()
                    }
                    .onTapGesture(count: 1) {
                        onSelect()
                    }
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
    }

    private func beginEdit() {
        editText = "\(value)"
        isEditing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
    }

    private func commit() {
        if let v = Int(editText.trimmingCharacters(in: .whitespaces)), v > 0 {
            value = min(range.upperBound, max(range.lowerBound, v))
        }
        isEditing = false
    }
}

// MARK: - Scrub field (tap to type, drag up/down to change)

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
