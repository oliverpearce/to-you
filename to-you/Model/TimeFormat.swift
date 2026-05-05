//
//  TimeFormat.swift
//  to-you.

import Foundation

enum TimeFormat: String, CaseIterable, Identifiable {
    case clock = "hh:mm:ss"
    case wordy = "hrs m s"

    var id: String { rawValue }
}
