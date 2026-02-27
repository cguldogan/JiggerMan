//
//  Models.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import Foundation

struct Preferences: Codable, Equatable, Sendable {
    var launchAtLogin: Bool
    var notifyOnStartStop: Bool
    var logRetentionDays: Int
    var restorePreviousState: Bool
    var jiggleDistance: Double
    var jiggleInterval: Double
    var showInDock: Bool
    var showMenuBarIcon: Bool

    static let `default` = Preferences(
        launchAtLogin: false,
        notifyOnStartStop: true,
        logRetentionDays: 30,
        restorePreviousState: true,
        jiggleDistance: 50.0,
        jiggleInterval: 5.0,
        showInDock: false,
        showMenuBarIcon: true
    )

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        launchAtLogin = try container.decode(Bool.self, forKey: .launchAtLogin)
        notifyOnStartStop = try container.decode(Bool.self, forKey: .notifyOnStartStop)
        logRetentionDays = try container.decode(Int.self, forKey: .logRetentionDays)
        restorePreviousState = try container.decode(Bool.self, forKey: .restorePreviousState)
        jiggleDistance = try container.decode(Double.self, forKey: .jiggleDistance)
        jiggleInterval = try container.decode(Double.self, forKey: .jiggleInterval)
        showInDock = try container.decode(Bool.self, forKey: .showInDock)
        showMenuBarIcon = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? true
    }

    init(launchAtLogin: Bool, notifyOnStartStop: Bool, logRetentionDays: Int,
         restorePreviousState: Bool, jiggleDistance: Double, jiggleInterval: Double,
         showInDock: Bool, showMenuBarIcon: Bool = true) {
        self.launchAtLogin = launchAtLogin
        self.notifyOnStartStop = notifyOnStartStop
        self.logRetentionDays = logRetentionDays
        self.restorePreviousState = restorePreviousState
        self.jiggleDistance = jiggleDistance
        self.jiggleInterval = jiggleInterval
        self.showInDock = showInDock
        self.showMenuBarIcon = showMenuBarIcon
    }

    // Explicitly implement Encodable to avoid compiler inferring MainActor isolation
    // from the synthesized conformance.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(notifyOnStartStop, forKey: .notifyOnStartStop)
        try container.encode(logRetentionDays, forKey: .logRetentionDays)
        try container.encode(restorePreviousState, forKey: .restorePreviousState)
        try container.encode(jiggleDistance, forKey: .jiggleDistance)
        try container.encode(jiggleInterval, forKey: .jiggleInterval)
        try container.encode(showInDock, forKey: .showInDock)
        try container.encode(showMenuBarIcon, forKey: .showMenuBarIcon)
    }

    enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case notifyOnStartStop
        case logRetentionDays
        case restorePreviousState
        case jiggleDistance
        case jiggleInterval
        case showInDock
        case showMenuBarIcon
    }
}

struct LogEntry: Identifiable, Codable, Sendable {
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

    // Explicitly implement Encodable to avoid compiler inferring MainActor isolation
    // from the synthesized conformance.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(action, forKey: .action)
        try container.encode(reason, forKey: .reason)
    }
}
