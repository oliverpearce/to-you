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
            HStack {
                Text("to-you. <3").font(.headline)
                Spacer()
                Button(action: { model.isRunning ? model.stop() : model.restart() }) {
                    Text(model.isRunning ? "Stop" : "Start")
                }
                .keyboardShortcut(.space, modifiers: [])
            }

            HStack(spacing: 8) {
                TextField("Minutes", value: $minutesInput, formatter: NumberFormatter())
                    .frame(width: 70)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { model.start(minutes: minutesInput) }
//                Button("Start") { model.start(minutes: minutesInput) }
            }

            HStack {
                ForEach([5, 15, 25, 50, 90, 120], id: \.self) { m in
                    Button("\(m)") { minutesInput = m; model.start(minutes: m) }
                        .buttonStyle(.bordered)
                }
            }

            if model.isRunning {
                ProgressView(value: model.progress)
                Text(model.formattedTimeLeft)
                    .font(.system(.title3, design: .monospaced))
            }

            Divider().padding(.vertical, 2)

            // Settings row
            HStack {
                Toggle("Floating Display", isOn: Binding(
                    get: { model.hudVisible },
                    set: { newVal in
                        model.hudVisible = newVal
                        UserDefaults.standard.set(newVal, forKey: "hudVisible")
                        newVal ? showHUD() : hideHUD()
                    })
                )
//                Spacer()
//                Toggle("Increase icon contrast", isOn: Binding(
//                    get: { model.increaseContrastIcon },
//                    set: { newVal in
//                        model.increaseContrastIcon = newVal
//                        UserDefaults.standard.set(newVal, forKey: "increaseContrastIcon")
//                    })
//                )
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            minutesInput = max(1, UserDefaults.standard.integer(forKey: "lastDuration") / 60)
            if model.hudVisible { showHUD() }
        }
    }
}
