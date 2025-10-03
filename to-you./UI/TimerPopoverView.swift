//
//  TimerPopoverView.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import SwiftUI

struct TimerPopoverView: View {
    @ObservedObject var model: AppModel
    let showHUD: () -> Void
    let hideHUD: () -> Void

    @State private var minutesInput: Int = 25

    var body: some View {
        VStack(spacing: 14) {
            // Header with title (left) and HUD on/off toggle (right)
            HStack(spacing: 10) {
                Text("to-you timer").font(.headline)
                Spacer()
                Toggle("HUD", isOn: Binding(
                    get: { model.hudVisible },
                    set: { v in
                        model.hudVisible = v
                        UserDefaults.standard.set(v, forKey: "hudVisible")
                        v ? showHUD() : hideHUD()
                    })
                )
                .labelsHidden()
            }

            // ASCII panel (no rain in popover)
            let panelText = AsciiUI.panel(
                title: model.isPaused ? "paused" : (model.isRunning ? "running" : "ready"),
                time: model.formattedTimeLeft,
                progress: model.progress,
                rain: "",
                width: 48
            )
            Text(panelText)
                .font(.system(size: 11, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.windowBackgroundColor).opacity(0.35))
                )

            // Minimal input controls: type minutes + presets. No sliders, nothing else.
            if !model.isRunning && !model.isPaused {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Minutes", value: $minutesInput, formatter: NumberFormatter())
                            .frame(width: 70)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { if model.hudVisible { showHUD() }; model.start(minutes: minutesInput) }
                        Button("Start") { if model.hudVisible { showHUD() }; model.start(minutes: minutesInput) }
                            .keyboardShortcut(.return, modifiers: [])
                    }
                    HStack {
                        ForEach([5, 15, 25, 50, 90, 120], id: \.self) { m in
                            Button("\(m)m") { minutesInput = m; if model.hudVisible { showHUD() }; model.start(minutes: m) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }

            // Controls row (restored): Pause/Resume, Stop, Reset
            HStack(spacing: 8) {
                if model.isRunning {
                    Button("Pause") { model.pause() }
                    Button("Stop") { hideHUD(); model.stop() }
                    Button("Reset") { model.reset() }
                } else if model.isPaused {
                    Button("Resume") { model.resume() }
                    Button("Stop") { hideHUD(); model.stop() }
                    Button("Reset") { model.reset() }
                } else {
                    // When idle, controls sit out of the way (no duplicate Start)
                    EmptyView()
                }
                Spacer()
            }
        }
        .padding()
        .frame(width: 420)
        .onAppear {
            minutesInput = max(1, UserDefaults.standard.integer(forKey: "lastDuration") / 60)
            if model.hudVisible { showHUD() } // default ON per register(defaults:)
        }
    }
}
