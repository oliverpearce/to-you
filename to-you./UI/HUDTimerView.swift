//
//  HUDTimerView.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import SwiftUI

struct HUDTimerView: View {
    @ObservedObject var model: AppModel

    @State private var overlayState: Int = 0
    @State private var overlayOpacity: Double = 0.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .shadow(radius: 10)

            VStack(spacing: 6) {
                Text(model.formattedTimeLeft)
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                ProgressView(value: model.progress)
                    .frame(width: 120)
            }
            .padding(12)

            if overlayState != 0 {
                Color.black
                    .opacity(overlayOpacity * 0.5)
                    .cornerRadius(14)

                Group {
                    if overlayState == 3 {
                        Text("Break Time!")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: overlayState == 1 ? "pause.fill" : "play.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                }
                .opacity(overlayOpacity)
            }
        }
        .frame(width: 160, height: 72)
        .onTapGesture {
            handleTap()
        }
        .onChange(of: model.secondsLeft) { newLeft in
            if newLeft == 0 {
                showBreakOverlay()
            }
        }
        .onChange(of: overlayState) { new in
            switch new {
            case 1:
                overlayOpacity = 0.0
                withAnimation(.linear(duration: 0.15)) {
                    overlayOpacity = 1.0
                }
            case 2:
                overlayOpacity = 1.0
                withAnimation(.linear(duration: 0.2).delay(0.05)) {
                    overlayOpacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    overlayState = 0
                }
            case 3:
                overlayOpacity = 0.0
                withAnimation(.linear(duration: 0.15)) {
                    overlayOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.linear(duration: 0.4)) {
                        overlayOpacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        overlayState = 0
                    }
                }
            default:
                break
            }
        }
        .animation(.linear(duration: 0.15), value: overlayOpacity)
    }

    private func handleTap() {
        if model.isRunning {
            model.pause()
            overlayState = 1
        } else if model.isPaused {
            overlayState = 2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                model.resume()
            }
        } else {
            model.start(minutes: model.totalSeconds / 60)
        }
    }

    private func showBreakOverlay() {
        overlayState = 3
    }
}

//
//import SwiftUI
//
//struct HUDTimerView: View {
//    @ObservedObject var model: AppModel
//
//    @State private var overlayState: Int = 0
//    @State private var overlayOpacity: Double = 0.0
//
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 14)
//                .fill(.ultraThinMaterial)
//                .shadow(radius: 10)
//
//            VStack(spacing: 6) {
//                Text(model.formattedTimeLeft)
//                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
//                ProgressView(value: model.progress)
//                    .frame(width: 120)
//            }
//            .padding(12)
//
//            if overlayState != 0 {
//                Color.black
//                    .opacity(overlayOpacity * 0.5)
//                    .cornerRadius(14)
//                    .animation(nil, value: overlayState)
//
//                Image(systemName: overlayState == 1 ? "pause.fill" : "play.fill")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 30, height: 30)
//                    .foregroundColor(.white)
//                    .opacity(overlayOpacity)
//                    .animation(nil, value: overlayState)
//            }
//        }
//        .frame(width: 160, height: 72)
//        .onTapGesture {
//            handleTap()
//        }
//        .onChange(of: overlayState) { new in
//            switch new {
//            case 1:
//                overlayOpacity = 0.0
//                withAnimation(.linear(duration: 0.15)) {
//                    overlayOpacity = 1.0
//                }
//            case 2:
//                overlayOpacity = 1.0
//                withAnimation(.linear(duration: 0.2).delay(0.05)) {
//                    overlayOpacity = 0.0
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                    overlayState = 0
//                }
//            default:
//                break
//            }
//        }
//        .animation(.linear(duration: 0.15), value: overlayOpacity)
//    }
//
//    private func handleTap() {
//        if model.isRunning {
//            model.pause()
//            overlayState = 1
//        } else if model.isPaused {
//            overlayState = 2
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
//                model.resume()
//            }
//        } else {
//            model.start(minutes: model.totalSeconds / 60)
//        }
//    }
//}
