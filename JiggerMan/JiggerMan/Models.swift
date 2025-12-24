//
//  Models.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import Foundation

struct Preferences: Codable {
    var launchAtLogin: Bool
    var notifyOnStartStop: Bool
    var logRetentionDays: Int
    var restorePreviousState: Bool
    var jiggleDistance: Double
    var showInDock: Bool

    static let `default` = Preferences(
        launchAtLogin: false,
        notifyOnStartStop: true,
        logRetentionDays: 30,
        restorePreviousState: true,
        jiggleDistance: 50.0,
        showInDock: false
    )
}

struct LogEntry: Identifiable, Codable {
    var id: UUID
    var date: Date
    var action: String
    var reason: String

    init(date: Date = Date(), action: String, reason: String) {
        self.id = UUID()
        self.date = date
        self.action = action
        self.reason = reason
    }
}
