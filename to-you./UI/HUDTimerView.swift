//
//  HUDTimerView.swift
//  to-you.
//
//  Created by Silver on 10/2/25.
//

import SwiftUI

struct HUDTimerView: View {
    @ObservedObject var model: AppModel

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
        }
        .frame(width: 160, height: 72)
        .onTapGesture {
            if model.isRunning {
                model.pause()
            } else if model.isPaused {
                model.resume()
            } else {
                let minutes = model.totalSeconds / 60
                model.start(minutes: minutes)
            }
        }
    }
}

//import SwiftUI
//
//struct HUDTimerView: View {
//    @ObservedObject var model: AppModel
//
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 14)
//                .fill(.ultraThinMaterial)
//                .shadow(radius: 10)
//            VStack(spacing: 6) {
//                Text(model.formattedTimeLeft)
//                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
//                ProgressView(value: model.progress)
//                    .frame(width: 120)
//            }.padding(12)
//        }
//        .frame(width: 160, height: 72)
//        .onTapGesture { model.toggleStartStop() }
//    }
//}
