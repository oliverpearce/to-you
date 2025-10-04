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
            // Top bar
            HStack {
                Text("to-you. <3")
                    .font(.headline)
                Spacer()
                if model.isRunning {
                    Button("Pause") {
                        withAnimation {
                            model.pause()
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])

                    Button("Reset") {
                        withAnimation {
                            model.reset()
                        }
                    }
                    .padding(.leading, 4)
                } else if model.isPaused {
                    Button("Resume") {
                        withAnimation {
                            model.resume()
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])

                    Button("Reset") {
                        withAnimation {
                            model.reset()
                        }
                    }
                    .padding(.leading, 4)
                } else {
                    Button("Start") {
                        withAnimation {
                            model.start(minutes: minutesInput)
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])
                }
            }

            // Input / presets — only when not started
            if !model.isRunning && !model.isPaused {
                VStack(spacing: 8) {
                    HStack {
                        TextField("Minutes", value: $minutesInput, formatter: NumberFormatter())
                            .frame(width: 70)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                withAnimation {
                                    model.start(minutes: minutesInput)
                                }
                            }
                    }
                    HStack {
                        ForEach([5, 15, 25, 50, 90, 120], id: \.self) { m in
                            Button("\(m)") {
                                minutesInput = m
                                withAnimation {
                                    model.start(minutes: m)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }

            // Timer / progress view when running or paused
            if model.isRunning || model.isPaused {
                VStack(spacing: 6) {
                    ProgressView(value: model.progress)
                    Text(model.formattedTimeLeft)
                        .font(.system(.title3, design: .monospaced))
                }
                .transition(.opacity)
            }

            Divider().padding(.vertical, 2)

            // Settings toggle
            HStack {
                Toggle("Floating Display", isOn: Binding(
                    get: { model.hudVisible },
                    set: { newVal in
                        model.hudVisible = newVal
                        UserDefaults.standard.set(newVal, forKey: "hudVisible")
                        newVal ? showHUD() : hideHUD()
                    })
                )
            }

        }
        .padding()
        .frame(width: 300)
        .onAppear {
            minutesInput = max(1, UserDefaults.standard.integer(forKey: "lastDuration") / 60)
            if model.hudVisible {
                showHUD()
            }
        }
        .animation(.easeInOut, value: model.isRunning)
        .animation(.easeInOut, value: model.isPaused)
    }
}

//
//import SwiftUI
//
//struct TimerPopoverView: View {
//    @ObservedObject var model: AppModel
//    let showHUD: () -> Void
//    let hideHUD: () -> Void
//
//    @State private var minutesInput: Int = 25
//
//    var body: some View {
//        VStack(spacing: 14) {
//            // Top control bar
//            HStack {
//                Text("to-you. <3")
//                    .font(.headline)
//                Spacer()
//
//                if model.isRunning {
//                    // If running (not paused), show Pause + Reset
//                    Button(action: {
//                        withAnimation {
//                            model.pause()
//                        }
//                    }) {
//                        Text("Pause")
//                    }
//                    .keyboardShortcut(.space, modifiers: [])
//
//                    Button("Reset") {
//                        withAnimation {
//                            model.reset()
//                        }
//                    }
//                    .padding(.leading, 4)
//                } else if model.isPaused {
//                    // If paused, “Resume” + “Reset”
//                    Button("Resume") {
//                        withAnimation {
//                            model.resume()
//                        }
//                    }
//                    .keyboardShortcut(.space, modifiers: [])
//
//                    Button("Reset") {
//                        withAnimation {
//                            model.reset()
//                        }
//                    }
//                    .padding(.leading, 4)
//                } else {
//                    // Neither running nor paused → show Start
//                    Button("Start") {
//                        withAnimation {
//                            model.start(minutes: minutesInput)
//                        }
//                    }
//                    .keyboardShortcut(.space, modifiers: [])
//                }
//            }
//
//            // Inputs / presets only when not running & not paused
//            if !model.isRunning && !model.isPaused {
//                VStack(spacing: 8) {
//                    HStack(spacing: 8) {
//                        TextField("Minutes", value: $minutesInput, formatter: NumberFormatter())
//                            .frame(width: 70)
//                            .textFieldStyle(.roundedBorder)
//                            .onSubmit {
//                                withAnimation {
//                                    model.start(minutes: minutesInput)
//                                }
//                            }
//                    }
//                    HStack {
//                        ForEach([5, 15, 25, 50, 90, 120], id: \.self) { m in
//                            Button("\(m)") {
//                                minutesInput = m
//                                withAnimation {
//                                    model.start(minutes: m)
//                                }
//                            }
//                            .buttonStyle(.bordered)
//                        }
//                    }
//                }
//                .transition(.asymmetric(
//                    insertion: .move(edge: .top).combined(with: .opacity),
//                    removal: .move(edge: .top).combined(with: .opacity)
//                ))
//            }
//
//            // Timer / progress display when running or paused
//            if model.isRunning || model.isPaused {
//                VStack(spacing: 6) {
//                    ProgressView(value: model.progress)
//                    Text(model.formattedTimeLeft)
//                        .font(.system(.title3, design: .monospaced))
//                }
//                .transition(.opacity)
//            }
//
//            Divider().padding(.vertical, 2)
//
//            // Settings row
//            HStack {
//                Toggle("Floating Display", isOn: Binding(
//                    get: { model.hudVisible },
//                    set: { newVal in
//                        model.hudVisible = newVal
//                        UserDefaults.standard.set(newVal, forKey: "hudVisible")
//                        newVal ? showHUD() : hideHUD()
//                    })
//                )
//            }
//        }
//        .padding()
//        .frame(width: 300)
//        .onAppear {
//            minutesInput = max(1, UserDefaults.standard.integer(forKey: "lastDuration") / 60)
//            if model.hudVisible { showHUD() }
//        }
//        .animation(.easeInOut, value: model.isRunning)
//        .animation(.easeInOut, value: model.isPaused)
//    }
//}
