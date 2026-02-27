//
//  PersistenceStore.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import Foundation

struct AppStateSnapshot: Codable, Sendable {
    var preferences: Preferences
    var manualSimulateActivity: Bool
}

final class PersistenceStore: Sendable {
    static let shared = PersistenceStore()

    private let fileURL: URL

    private init() {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let appSupport = baseURL?.appendingPathComponent("JiggerMan", isDirectory: true)
        if let appSupport {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        fileURL = (appSupport ?? baseURL ?? URL(fileURLWithPath: "/tmp"))
            .appendingPathComponent("state.json")
    }

    func load() -> AppStateSnapshot? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(AppStateSnapshot.self, from: data)
        } catch {
            NSLog("JiggerMan: Failed to load state: \(error.localizedDescription)")
            return nil
        }
    }

    func save(snapshot: AppStateSnapshot) {
        let url = fileURL
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: [.atomic])
            } catch {
                NSLog("JiggerMan: Failed to save state: \(error.localizedDescription)")
            }
        }
    }
}
