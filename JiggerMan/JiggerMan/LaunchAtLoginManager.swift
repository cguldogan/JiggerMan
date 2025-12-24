//
//  LaunchAtLoginManager.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import Foundation
import ServiceManagement

final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private init() {}

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Ignore failures; this can fail outside /Applications.
        }
    }
}
