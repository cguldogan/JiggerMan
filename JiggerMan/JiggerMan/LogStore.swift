//
//  LogStore.swift
//  JiggerMan
//
//  Created by Can GULDOGAN on 23/12/2025.
//

import Combine
import Foundation

final class LogStore: ObservableObject {
    static let shared = LogStore()

    @Published private(set) var entries: [LogEntry] = []

    private let fileURL: URL

    private init() {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let appSupport = baseURL?.appendingPathComponent("JiggerMan", isDirectory: true)
        if let appSupport {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }
        fileURL = (appSupport ?? baseURL ?? URL(fileURLWithPath: "/tmp"))
            .appendingPathComponent("logs.json")
        load()
    }

    func append(_ entry: LogEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func clear() {
        entries.removeAll()
        save()
    }

    func prune(olderThanDays days: Int) {
        guard days > 0 else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        entries.removeAll { $0.date < cutoff }
        save()
    }

    func exportText() -> String {
        let formatter = ISO8601DateFormatter()
        return entries.map { entry in
            return "[\(formatter.string(from: entry.date))] \(entry.action) - \(entry.reason)"
        }.joined(separator: "\n")
    }

    private func load() {
        do {
            // Check file size to avoid hanging on massive log files (e.g. > 10MB)
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? UInt64, fileSize > 10_000_000 {
                NSLog("JiggerMan: Log file is too large (\(fileSize) bytes), clearing it.")
                try FileManager.default.removeItem(at: fileURL)
                entries = []
                return
            }
            
            let data = try Data(contentsOf: fileURL)
            var loadedEntries = try JSONDecoder().decode([LogEntry].self, from: data)
            
            // Filter out the spammy "Mouse Jiggle" logs from previous versions
            loadedEntries.removeAll { $0.reason == "Mouse Jiggle" }
            entries = loadedEntries
        } catch {
            entries = []
            NSLog("JiggerMan: Failed to load logs: \(error.localizedDescription)")
        }
    }

    private func save() {
        let entriesToSave = entries
        let url = fileURL
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(entriesToSave)
                try data.write(to: url, options: [.atomic])
            } catch {
                NSLog("JiggerMan: Failed to save logs: \(error.localizedDescription)")
            }
        }
    }
}
