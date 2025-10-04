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

    @State private var editMode: Bool = false
    @State private var editString: String = ""
    @FocusState private var isTextFieldFocused: Bool

    let defaultSeconds: Int = 15 * 60  // default is 15 minutes

    private func parseTime(_ s: String) -> Int? {
        let parts = s.split(separator: ":").map(String.init)
        switch parts.count {
        case 1:
            if let ss = Int(parts[0]), ss >= 0 {
                return ss
            }
        case 2:
            if let mm = Int(parts[0]), let ss = Int(parts[1]),
               mm >= 0, ss >= 0, ss < 60 {
                return mm * 60 + ss
            }
        case 3:
            if let hh = Int(parts[0]), let mm = Int(parts[1]), let ss = Int(parts[2]),
               hh >= 0, mm >= 0, mm < 60, ss >= 0, ss < 60 {
                return hh * 3600 + mm * 60 + ss
            }
        default:
            return nil
        }
        return nil
    }

    private func formatTime(_ tot: Int) -> String {
        let h = tot / 3600
        let m = (tot % 3600) / 60
        let s = tot % 60
        if h > 0 {
            return String(format: "%02d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    var body: some View {
        VStack(spacing: 14) {
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
                    .padding(.leading, 6)
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
                    .padding(.leading, 6)
                } else {
                    Button("Start") {
                        withAnimation {
                            let secs: Int
                            if editMode {
                                secs = parseTime(editString) ?? defaultSeconds
                            } else {
                                secs = defaultSeconds
                            }
                            model.start(seconds: secs)
                        }
                    }
                    .keyboardShortcut(.space, modifiers: [])
                }
            }

            ZStack {
                if editMode && !model.isRunning && !model.isPaused {
                    TextField("HH:MM:SS", text: $editString)
                        .focused($isTextFieldFocused)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            editMode = false
                        }
                        .frame(width: 120)
                } else {
                    let display = (model.isRunning || model.isPaused)
                        ? formatTime(model.secondsLeft)
                        : formatTime(defaultSeconds)
                    Text(display)
                        .font(.system(.title2, design: .monospaced))
                        .onTapGesture {
                            if !model.isRunning && !model.isPaused {
                                editString = display
                                editMode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isTextFieldFocused = true
                                }
                            }
                        }
                }
                // No pause overlay in popover
            }
            .frame(height: 40)

            if model.isRunning || model.isPaused {
                ProgressView(value: model.progress)
                    .transition(.opacity)
            }

            Divider().padding(.vertical, 2)

            HStack {
                Toggle("Floating Display", isOn: Binding(
                    get: { model.hudVisible },
                    set: { new in
                        model.hudVisible = new
                        UserDefaults.standard.set(new, forKey: "hudVisible")
                        new ? showHUD() : hideHUD()
                    })
                )
            }
        }
        .padding()
        .frame(width: 300)
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
//    @State private var editMode: Bool = false
//    @State private var editString: String = ""
//    @FocusState private var isTextFieldFocused: Bool
//
//    // Default seconds = 15 minutes
//    let defaultSeconds: Int = 15 * 60
//
//    private func parseTime(_ s: String) -> Int? {
//        let parts = s.split(separator: ":").map(String.init)
//        switch parts.count {
//        case 1:
//            if let ss = Int(parts[0]), ss >= 0 {
//                return ss
//            }
//        case 2:
//            if let mm = Int(parts[0]), let ss = Int(parts[1]),
//               mm >= 0, ss >= 0, ss < 60 {
//                return mm * 60 + ss
//            }
//        case 3:
//            if let hh = Int(parts[0]), let mm = Int(parts[1]), let ss = Int(parts[2]),
//               hh >= 0, mm >= 0, mm < 60, ss >= 0, ss < 60 {
//                return hh * 3600 + mm * 60 + ss
//            }
//        default:
//            return nil
//        }
//        return nil
//    }
//
//    private func formatTime(_ tot: Int) -> String {
//        let h = tot / 3600
//        let m = (tot % 3600) / 60
//        let s = tot % 60
//        if h > 0 {
//            return String(format: "%02d:%02d:%02d", h, m, s)
//        } else {
//            return String(format: "%02d:%02d", m, s)
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 14) {
//            HStack {
//                Text("to-you. <3")
//                    .font(.headline)
//                Spacer()
//                if model.isRunning {
//                    Button("Pause") {
//                        withAnimation {
//                            model.pause()
//                        }
//                    }
//                    .keyboardShortcut(.space, modifiers: [])
//
//                    Button("Reset") {
//                        withAnimation {
//                            model.reset()
//                        }
//                    }
//                    .padding(.leading, 6)
//                } else if model.isPaused {
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
//                    .padding(.leading, 6)
//                } else {
//                    Button("Start") {
//                        withAnimation {
//                            let secs: Int
//                            if editMode {
//                                secs = parseTime(editString) ?? defaultSeconds
//                            } else {
//                                secs = defaultSeconds
//                            }
//                            model.start(seconds: secs)
//                        }
//                    }
//                    .keyboardShortcut(.space, modifiers: [])
//                }
//            }
//
//            ZStack {
//                if editMode && !model.isRunning && !model.isPaused {
//                    TextField("HH:MM:SS", text: $editString)
//                        .focused($isTextFieldFocused)
//                        .multilineTextAlignment(.center)
//                        .textFieldStyle(.roundedBorder)
//                        .onSubmit {
//                            editMode = false
//                        }
//                        .frame(width: 120)
//                } else {
//                    let display = (model.isRunning || model.isPaused)
//                        ? formatTime(model.secondsLeft)
//                        : formatTime(defaultSeconds)
//                    Text(display)
//                        .font(.system(.title2, design: .monospaced))
//                        .onTapGesture {
//                            if !model.isRunning && !model.isPaused {
//                                editString = display
//                                editMode = true
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                    isTextFieldFocused = true
//                                }
//                            }
//                        }
//                }
//
//                // <— Note: we removed any pause overlay here (popout UI has no overlay)
//            }
//            .frame(height: 40)
//
//            if model.isRunning || model.isPaused {
//                ProgressView(value: model.progress)
//                    .transition(.opacity)
//            }
//
//            Divider().padding(.vertical, 2)
//
//            HStack {
//                Toggle("Floating Display", isOn: Binding(
//                    get: { model.hudVisible },
//                    set: { new in
//                        model.hudVisible = new
//                        UserDefaults.standard.set(new, forKey: "hudVisible")
//                        new ? showHUD() : hideHUD()
//                    })
//                )
//            }
//        }
//        .padding()
//        .frame(width: 300)
//        .animation(.easeInOut, value: model.isRunning)
//        .animation(.easeInOut, value: model.isPaused)
//    }
//}
