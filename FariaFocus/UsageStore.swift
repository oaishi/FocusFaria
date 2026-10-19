//  UsageStore.swift
//  Turns the recorded sessions into totals for the "Tracked Time" tab.

import Foundation
import Combine

struct AppTotal: Identifiable {
    var id: String { app }
    let app: String
    let duration: TimeInterval
    let sessions: Int
}

@MainActor
final class UsageStore: ObservableObject {
    @Published private(set) var sessions: [UsageSession] = []
    @Published private(set) var now = Date()

    init() { reload() }

    func reload() {
        sessions = Storage.loadSessions()
        now = Date()
    }

    func clearAll() {
        Storage.saveSessions([])
        reload()
    }

    /// Current open session (if a "closed" signal hasn't arrived yet).
    var liveSession: UsageSession? {
        guard let s = sessions.last(where: { $0.end == nil }),
              now.timeIntervalSince(s.start) < UsageSession.maxLength else { return nil }
        return s
    }

    /// The part of each session that falls inside `day`.
    private func pieces(on day: Date) -> [(app: String, start: Date, end: Date)] {
        guard let interval = Calendar.current.dateInterval(of: .day, for: day) else { return [] }
        return sessions.compactMap { s in
            let start = max(s.start, interval.start)
            let end = min(s.effectiveEnd(now: now), interval.end)
            return end > start ? (s.app, start, end) : nil
        }
    }

    func total(on day: Date) -> TimeInterval {
        pieces(on: day).reduce(0) { $0 + $1.end.timeIntervalSince($1.start) }
    }

    func perApp(on day: Date) -> [AppTotal] {
        var dur: [String: TimeInterval] = [:]
        var count: [String: Int] = [:]
        for p in pieces(on: day) {
            dur[p.app, default: 0] += p.end.timeIntervalSince(p.start)
            count[p.app, default: 0] += 1
        }
        return dur.map { AppTotal(app: $0.key, duration: $0.value, sessions: count[$0.key] ?? 0) }
            .sorted { $0.duration > $1.duration }
    }

    func hourly(on day: Date) -> [TimeInterval] {
        var hours = Array(repeating: 0.0, count: 24)
        let cal = Calendar.current
        for p in pieces(on: day) {
            var cursor = p.start
            while cursor < p.end {
                let hour = cal.component(.hour, from: cursor)
                let nextHour = cal.dateInterval(of: .hour, for: cursor)?.end ?? p.end
                let sliceEnd = min(nextHour, p.end)
                hours[hour] += sliceEnd.timeIntervalSince(cursor)
                cursor = sliceEnd
            }
        }
        return hours
    }

    func longestSession(on day: Date) -> TimeInterval {
        pieces(on: day).map { $0.end.timeIntervalSince($0.start) }.max() ?? 0
    }
}

enum TimeText {
    static func format(_ t: TimeInterval) -> String {
        if t < 60 { return t < 1 ? "0m" : "<1m" }
        let f = DateComponentsFormatter()
        f.allowedUnits = t >= 3600 ? [.hour, .minute] : [.minute]
        f.unitsStyle = .abbreviated
        f.zeroFormattingBehavior = .dropAll
        return f.string(from: t) ?? "0m"
    }
}
