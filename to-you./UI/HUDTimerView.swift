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
        // HUD has no rain (per request); clean ASCII box
        let hudText = AsciiUI.hud(
            time: model.formattedTimeLeft,
            progress: model.progress,
            rain: "",
            width: 34
        )

        return Text(hudText)
            .font(.system(size: 11, design: .monospaced))
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 10)
            )
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture { model.toggleStartStop() }
    }
}
