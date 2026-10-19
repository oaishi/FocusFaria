//  Storage.swift
//  Everything the app saves on the phone (to-dos, settings, tracked sessions).
//  Uses plain UserDefaults – no paid-account features needed.

import Foundation

// MARK: - App info

enum AppInfo {
    /// The name shown under the app icon (set in project.yml / build settings).
    static var name: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "the app"
    }
}

// MARK: - Models

struct TodoItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var isDone = false
    var createdAt = Date()
}

enum NudgeStyle: String, Codable, CaseIterable, Identifiable {
    case mix
    case todosOnly
    case quotesOnly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mix:        return "To-dos + quotes"
        case .todosOnly:  return "Only my to-dos"
        case .quotesOnly: return "Only quotes"
        }
    }
}

/// One stretch of time inside a "scrolling" app (Instagram, TikTok, …).
struct UsageSession: Codable, Identifiable, Equatable {
    var id = UUID()
    var app: String
    var start: Date
    var end: Date?

    /// Sessions that never got a "closed" signal are capped so one missed
    /// signal can't add a whole day of fake screen time.
    static let maxLength: TimeInterval = 3 * 60 * 60

    func duration(now: Date = Date()) -> TimeInterval {
        let finish = end ?? now
        return max(0, min(finish.timeIntervalSince(start), Self.maxLength))
    }

    func effectiveEnd(now: Date = Date()) -> Date {
        start.addingTimeInterval(duration(now: now))
    }
}

// MARK: - Storage

enum Storage {
    private static let d = UserDefaults.standard

    private enum Key {
        static let userName = "user.name"
        static let todos = "todos.v1"
        static let sessions = "sessions.v1"
        static let nudgesEnabled = "nudges.enabled"
        static let intervalMinutes = "nudges.intervalMinutes"
        static let style = "nudges.style"
        static let streakStart = "streak.start"
        static let lastStart = "signal.lastStart"
        static let lastStop = "signal.lastStop"
        static let activeApp = "signal.activeApp"
        static let lastSignalText = "signal.lastText"
        static let lastSignalDate = "signal.lastDate"
    }

    // MARK: User

    /// The name used in nudges ("Sam, don't waste time scrolling").
    /// nil = never asked yet (shows the welcome screen); "" = skipped.
    static var userName: String? {
        get { d.string(forKey: Key.userName) }
        set { d.set(newValue?.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.userName) }
    }

    // MARK: To-dos

    static func loadTodos() -> [TodoItem] {
        decode([TodoItem].self, Key.todos) ?? []
    }

    static func saveTodos(_ items: [TodoItem]) {
        encode(items, Key.todos)
    }

    // MARK: Sessions

    static func loadSessions() -> [UsageSession] {
        decode([UsageSession].self, Key.sessions) ?? []
    }

    static func saveSessions(_ sessions: [UsageSession]) {
        // Keep the last 14 days only.
        let cutoff = Date().addingTimeInterval(-14 * 24 * 60 * 60)
        encode(sessions.filter { $0.start >= cutoff }, Key.sessions)
    }

    // MARK: Settings

    /// Nudges are ON by default so the app works right after setup.
    static var nudgesEnabled: Bool {
        get { d.object(forKey: Key.nudgesEnabled) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.nudgesEnabled) }
    }

    static var intervalMinutes: Int {
        get { let v = d.integer(forKey: Key.intervalMinutes); return v > 0 ? v : 10 }
        set { d.set(newValue, forKey: Key.intervalMinutes) }
    }

    static var nudgeStyle: NudgeStyle {
        get { NudgeStyle(rawValue: d.string(forKey: Key.style) ?? "") ?? .mix }
        set { d.set(newValue.rawValue, forKey: Key.style) }
    }

    // MARK: Signals from the Shortcuts automations

    static var streakStart: Date? {
        get { d.object(forKey: Key.streakStart) as? Date }
        set { d.set(newValue, forKey: Key.streakStart) }
    }

    static var lastStart: Date? {
        get { d.object(forKey: Key.lastStart) as? Date }
        set { d.set(newValue, forKey: Key.lastStart) }
    }

    static var lastStop: Date? {
        get { d.object(forKey: Key.lastStop) as? Date }
        set { d.set(newValue, forKey: Key.lastStop) }
    }

    static var activeApp: String? {
        get { d.string(forKey: Key.activeApp) }
        set { d.set(newValue, forKey: Key.activeApp) }
    }

    /// Shown in the app so you can check the automations are working.
    static var lastSignal: (text: String, date: Date)? {
        guard let t = d.string(forKey: Key.lastSignalText),
              let date = d.object(forKey: Key.lastSignalDate) as? Date else { return nil }
        return (t, date)
    }

    static func setLastSignal(_ text: String) {
        d.set(text, forKey: Key.lastSignalText)
        d.set(Date(), forKey: Key.lastSignalDate)
    }

    // MARK: Helpers

    private static func decode<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = d.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func encode<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) { d.set(data, forKey: key) }
    }
}
