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
            let data = try Data(contentsOf: fileURL)
            entries = try JSONDecoder().decode([LogEntry].self, from: data)
        } catch {
            entries = []
            NSLog("JiggerMan: Failed to load logs: \(error.localizedDescription)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            NSLog("JiggerMan: Failed to save logs: \(error.localizedDescription)")
        }
    }
}
