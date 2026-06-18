//
//  TimerPopoverView.swift
//  to-you.

import AppKit
import SwiftUI

struct TimerPopoverView: View {
    @ObservedObject var model: AppModel
    let openSettings: () -> Void
    let closePopover: () -> Void
    let toggleHUD: () -> Void

    @AppStorage("preset1") private var preset1: Int = 25
    @AppStorage("preset2") private var preset2: Int = 30
    @AppStorage("preset3") private var preset3: Int = 45
    @AppStorage("selectedFont")       private var fontTheme: FontTheme = .system
    @AppStorage("timeFormat")          private var timeFormat: TimeFormat = .clock
    @AppStorage("showSeconds")        private var showSeconds: Bool = true
    @AppStorage("flashOnInterval")    private var flashOnInterval: Bool = true
    @AppStorage("pomodoroEnabled")    private var pomodoroEnabled: Bool = true
    @AppStorage("pomodoroCycles")     private var pomodoroCycles: Int = 3
    @AppStorage("breakPreset1")       private var breakPreset1: Int = 5
    @AppStorage("breakPreset2")       private var breakPreset2: Int = 15
    @AppStorage("breakPreset3")       private var breakPreset3: Int = 30
    @AppStorage("selectedBreakSlot")  private var selectedBreakSlot: Int = 1
    @AppStorage("selectedPresetSlot") private var selectedPresetSlot: Int = 1

    @State private var sliderMinutes: Double = 25
    @State private var dragStartMinutes: Double? = nil
    @State private var isEditingTime = false
    @State private var flashOpacity: Double = 1.0
    @State private var editString = ""
    @State private var lastClickedSlot: Int = 1
    @FocusState private var timeFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            scrubberRow
                .padding(.horizontal, 14)
                .padding(.top, 10)

            HStack(spacing: 14) {
                HStack(spacing: 14) {
                    presetButton(preset1, slot: 1)
                    presetButton(preset2, slot: 2)
                    presetButton(preset3, slot: 3)
                    pomoToggleButton
                }
                .opacity(model.isBreakTimer && (model.isRunning || model.isPaused) ? 0.25 : 1.0)
                .allowsHitTesting(!(model.isBreakTimer && (model.isRunning || model.isPaused)))
                Spacer()
                HStack(spacing: 4) {
                    Button { toggleHUD() } label: {
                        Image(systemName: "macwindow")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .hoverHighlight()
                    .help("Toggle floating display")
                    .accessibilityLabel("Toggle floating display")
                    Button { openSettings() } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .hoverHighlight()
                    .help("Open settings")
                    .accessibilityLabel("Open settings")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 4)

            if !model.isRunning && !model.isPaused && pomodoroEnabled {
                HStack(spacing: 6) {
                    Text("break:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    breakPresetButton(breakPreset1, slot: 1)
                    breakPresetButton(breakPreset2, slot: 2)
                    breakPresetButton(breakPreset3, slot: 3)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 2)
            }

            Spacer()

            VStack(spacing: 0) {
                if pomodoroEnabled {
                    HStack {
                        dotsMenu
                            .padding(.leading, 8)
                            .help("More options")
                        if model.isBreakTimer && (model.isRunning || model.isPaused) {
                            let remaining = pomodoroCycles - model.cyclesCompleted
                            Text("\(remaining) \(remaining == 1 ? "cycle" : "cycles") left")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                }

                HStack(alignment: .firstTextBaseline) {
                    if !pomodoroEnabled {
                        dotsMenu
                            .help("More options")
                    }
                    controlButton
                        .buttonStyle(.plain)
                        .hoverHighlight()
                    if model.isRunning || model.isPaused {
                        Button("reset") { resetToPreset() }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .hoverHighlight()
                    } else if pomodoroEnabled {
                        Text("\(pomodoroCycles) \(pomodoroCycles == 1 ? "cycle" : "cycles")")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.bottom, 14)
            }
            .overlay(alignment: .bottomTrailing) {
                timeDisplay
                    .opacity(flashOpacity)
                    .animation(.easeInOut(duration: 0.15), value: flashOpacity)
                    .padding(.trailing, 14)
                    .padding(.bottom, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .font(fontTheme.timerFont(size: 14))
        .onAppear { syncSlider() }
        .onChange(of: model.totalSeconds) { _, _ in
            guard !model.isRunning && !model.isPaused else { return }
            syncSlider()
        }
        .onChange(of: model.secondsLeft) { _, secs in
            guard model.isRunning, flashOnInterval else { return }
            guard secs > 0, secs % 60 == 0 else { return }
            flashOpacity = 0.1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { flashOpacity = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) { flashOpacity = 0.1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { flashOpacity = 1.0 }
        }
    }

    // MARK: - Time display

    @ViewBuilder
    private var timeDisplay: some View {
        if isEditingTime {
            TextField("min", text: $editString)
                .focused($timeFieldFocused)
                .font(fontTheme.timerFont(size: 44))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.plain)
                .frame(minWidth: 80)
                .onSubmit { commitTimeEdit() }
                .onExitCommand { isEditingTime = false }
        } else if model.isRunning || model.isPaused {
            let label: String = {
                switch (timeFormat, showSeconds) {
                case (.clock, true):  return model.formattedTimeLeft
                case (.clock, false): return model.formattedNoSeconds(model.secondsLeft)
                case (.wordy, true):  return model.shortFormattedWithSeconds(model.secondsLeft)
                case (.wordy, false): return model.shortFormatted(model.secondsLeft)
                }
            }()
            Text(label)
                .font(timeFont(for: label))
                .fontWeight(model.isBreakTimer ? .bold : .regular)
                .monospacedDigit()
                .foregroundStyle(model.isBreakTimer ? Color.lavender : Color.primary)
                .gesture(timeDragGesture)
                .hoverHighlight(cornerRadius: 8)
        } else {
            Text(idleTimeLabel)
                .font(timeFont(for: idleTimeLabel))
                .foregroundStyle(.primary.opacity(0.6))
                .monospacedDigit()
                .onTapGesture { beginTimeEdit() }
                .gesture(timeDragGesture)
                .hoverHighlight(cornerRadius: 8)
        }
    }

    private var idleTimeLabel: String {
        let secs = model.isFinished ? model.secondsLeft : model.totalSeconds
        switch (timeFormat, showSeconds) {
        case (.clock, true):  return model.formatted(secs)
        case (.clock, false): return model.formattedNoSeconds(secs)
        case (.wordy, true):  return model.shortFormattedWithSeconds(secs)
        case (.wordy, false): return model.shortFormatted(secs)
        }
    }

    private func beginTimeEdit() {
        editString = "\(model.totalSeconds / 60)"
        isEditingTime = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { timeFieldFocused = true }
    }

    private func commitTimeEdit() {
        isEditingTime = false
        timeFieldFocused = false
        guard let mins = Int(editString.trimmingCharacters(in: .whitespaces)), mins > 0 else { return }
        let capped = min(600, mins)
        sliderMinutes = Double(capped)
        switch lastClickedSlot {
        case 1: preset1 = capped
        case 2: preset2 = capped
        case 3: preset3 = capped
        default: break
        }
        model.setDuration(seconds: capped * 60)
    }

    private func timeFont(for text: String) -> Font {
        let n = text.count
        let size: CGFloat = n <= 5 ? 44 : n <= 8 ? 36 : 28
        return fontTheme.timerFont(size: size)
    }

    // MARK: - Drag on time to scrub

    private var timeDragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { val in
                guard !model.isRunning && !model.isPaused else { return }
                if dragStartMinutes == nil { dragStartMinutes = sliderMinutes }
                let delta = -(val.translation.height) / 4.0
                let newMins = ((dragStartMinutes ?? sliderMinutes) + delta).rounded().clamped(to: 1...600)
                if newMins != sliderMinutes {
                    sliderMinutes = newMins
                    model.setDuration(seconds: Int(newMins) * 60)
                }
            }
            .onEnded { _ in dragStartMinutes = nil }
    }

    // MARK: - Scrubber

    @ViewBuilder
    private var scrubberRow: some View {
        if model.isRunning || model.isPaused {
            ScrubberView(fraction: model.progress, interactive: false, onFraction: nil)
        } else {
            let fraction = (sliderMinutes - 1) / 599
            ScrubberView(fraction: fraction, interactive: true) { f in
                sliderMinutes = (1 + f * 599).rounded()
                model.setDuration(seconds: Int(sliderMinutes) * 60)
            }
        }
    }

    // MARK: - Control button

    @ViewBuilder
    private var controlButton: some View {
        if model.isRunning {
            Button("pause") { model.pause() }
        } else if model.isPaused {
            Button("resume") { model.resume() }
        } else {
            Button("start") {
                isEditingTime = false
                model.start(seconds: Int(sliderMinutes) * 60)
            }
        }
    }

    // MARK: - Pomodoro toggle

    private var pomoToggleButton: some View {
        Button {
            guard !model.isRunning && !model.isPaused else { return }
            pomodoroEnabled.toggle()
        } label: {
            Image(systemName: pomodoroEnabled ? "repeat.circle.fill" : "repeat.circle")
                .font(.system(size: 14))
                .foregroundStyle(pomodoroEnabled ? .primary : .secondary)
        }
        .buttonStyle(.plain)
        .opacity(model.isRunning || model.isPaused ? 0.4 : 1.0)
        .help("Toggle pomodoro")
    }

    // MARK: - Preset buttons

    private func presetLabel(_ minutes: Int) -> String {
        guard minutes >= 60 else { return "\(minutes)m" }
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h)hr" : "\(h)h\(m)m"
    }

    private func presetButton(_ minutes: Int, slot: Int) -> some View {
        let isSelected = !model.isBreakTimer && selectedPresetSlot == slot
        return Button(presetLabel(minutes)) {
            // Always update the selected slot so the reset target is correct
            // even when the user picks a pill while the timer is running.
            selectedPresetSlot = slot
            lastClickedSlot = slot
            // Only change the live timer duration when idle.
            guard !model.isRunning && !model.isPaused else { return }
            sliderMinutes = Double(minutes)
            model.setDuration(seconds: minutes * 60)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
        )
    }

    private func breakPresetButton(_ minutes: Int, slot: Int) -> some View {
        let isSelected = selectedBreakSlot == slot
        return Button(presetLabel(minutes)) {
            selectedBreakSlot = slot
        }
        .buttonStyle(.plain)
        .font(.caption)
        .foregroundStyle(isSelected ? .secondary : .tertiary)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.primary.opacity(0.08) : Color.clear)
        )
    }

    // MARK: - Dots menu

    private var dotsMenu: some View {
        Menu {
            Toggle("Pomodoro", isOn: $pomodoroEnabled)
                .disabled(model.isRunning || model.isPaused)
            Divider()
            if model.isRunning || model.isPaused || model.isFinished {
                Button("Reset Timer") { resetToPreset() }
                Divider()
            }
            Button("Settings...") { openSettings() }
            Divider()
            Button(model.hudVisible ? "Hide Floating Display" : "Show Floating Display") {
                toggleHUD()
            }
            Divider()
            Button("About to-you.") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.orderFrontStandardAboutPanel(nil)
            }
            Button("Quit") { NSApp.terminate(nil) }
        } label: {
            Text("···").foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    // MARK: - Helpers

    /// Reset the timer and snap duration to the currently highlighted preset pill.
    /// Reads directly from UserDefaults (not @AppStorage) to guarantee fresh values —
    /// @AppStorage in a non-visible hosting view may lag behind UserDefaults.
    private func resetToPreset() {
        let slot = UserDefaults.standard.integer(forKey: "selectedPresetSlot")
        let resolvedSlot = slot == 0 ? 1 : slot
        let key: String
        switch resolvedSlot {
        case 2: key = "preset2"
        case 3: key = "preset3"
        default: key = "preset1"
        }
        let raw = UserDefaults.standard.integer(forKey: key)
        let mins = raw > 0 ? raw : 25
        sliderMinutes = Double(mins)
        model.resetTo(seconds: mins * 60)
    }

    private func syncSlider() {
        sliderMinutes = min(600, Double(model.totalSeconds / 60))
    }
}

// MARK: - Hover highlight

private struct HoverHighlight: ViewModifier {
    @State private var hovering = false
    var cornerRadius: CGFloat = 6
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.primary.opacity(hovering ? 0.1 : 0)))
            .onHover { hovering = $0 }
            .animation(.easeInOut(duration: 0.1), value: hovering)
    }
}

private extension View {
    func hoverHighlight(cornerRadius: CGFloat = 6) -> some View {
        modifier(HoverHighlight(cornerRadius: cornerRadius))
    }
}

// MARK: - Ruler scrubber

private struct ScrubberView: View {
    let fraction: Double
    let interactive: Bool
    let onFraction: ((Double) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let f = (fraction.isNaN ? 0.0 : fraction).clamped(to: 0...1)

            Canvas { ctx, size in
                // Uniform tick marks across full width
                let spacing: CGFloat = 4.0
                let tH: CGFloat = 9
                let count = Int(size.width / spacing) + 1
                for i in 0..<count {
                    let x = CGFloat(i) * spacing
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: (size.height - tH) / 2))
                    p.addLine(to: CGPoint(x: x, y: (size.height + tH) / 2))
                    ctx.stroke(p, with: .color(.primary.opacity(0.2)), lineWidth: 1)
                }

                // Progress fill when running/paused
                if !interactive && f > 0 {
                    let fillRect = CGRect(x: 0, y: size.height * 0.3,
                                         width: f * size.width, height: size.height * 0.4)
                    ctx.fill(Path(fillRect), with: .color(.primary.opacity(0.22)))
                }

                // Position indicator — tall, bright
                let ix = f * size.width
                var ind = Path()
                ind.move(to: CGPoint(x: ix, y: 0))
                ind.addLine(to: CGPoint(x: ix, y: size.height))
                ctx.stroke(ind, with: .color(.primary.opacity(0.85)), lineWidth: 2)
            }
            .contentShape(Rectangle())
            .gesture(interactive ? DragGesture(minimumDistance: 0).onChanged { v in
                onFraction?((v.location.x / w).clamped(to: 0...1))
            } : nil)
        }
        .frame(height: 30)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
