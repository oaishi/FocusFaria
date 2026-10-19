//  ScrollTracker.swift
//  Receives "app opened" / "app closed" signals from your Shortcuts automations,
//  records how long you spend in each app, and (re)schedules the nudges.
//
//  Smart bits:
//  • Hopping between apps (Instagram → TikTok) keeps ONE running timer, so the
//    10 minutes add up across apps instead of starting over.
//  • iOS may send "TikTok opened" a split second BEFORE "Instagram closed".
//    We ignore a "closed" signal that arrives right after an "opened" one,
//    so the switch doesn't cancel your timer by mistake.

import Foundation

enum ScrollTracker {

    /// If you come back to a scrolling app within this time, the timer continues.
    static let continueWindow: TimeInterval = 90
    /// A "closed" signal this soon after an "opened" signal belongs to the previous app.
    static let switchWindow: TimeInterval = 3

    static func appOpened(_ rawName: String, now: Date = Date()) async {
        let app = clean(rawName)
        Storage.setLastSignal("\(app) opened")

        // 1. Tracking — close whatever was open, start a new session.
        var sessions = Storage.loadSessions()
        if let i = sessions.lastIndex(where: { $0.end == nil }) {
            if sessions[i].app == app && now.timeIntervalSince(sessions[i].start) < UsageSession.maxLength {
                // Same app reported twice — keep the existing session.
            } else {
                sessions[i].end = min(now, sessions[i].effectiveEnd(now: now))
                sessions.append(UsageSession(app: app, start: now))
            }
        } else {
            sessions.append(UsageSession(app: app, start: now))
        }
        Storage.saveSessions(sessions)

        // 2. Timer — continue the streak if you were scrolling a moment ago.
        let continuing: Bool
        if let start = Storage.streakStart {
            if let stop = Storage.lastStop {
                continuing = now.timeIntervalSince(stop) <= continueWindow
            } else {
                // Still "open" (no closed signal yet) — a switch between apps.
                continuing = now.timeIntervalSince(start) < UsageSession.maxLength
            }
        } else {
            continuing = false
        }
        let streakStart = continuing ? (Storage.streakStart ?? now) : now

        Storage.streakStart = streakStart
        Storage.lastStart = now
        Storage.lastStop = nil
        Storage.activeApp = app

        await NudgeScheduler.scheduleNudges(streakStart: streakStart, now: now)
    }

    static func appClosed(_ rawName: String, now: Date = Date()) async {
        let app = clean(rawName)

        // A different app is already active, or this "closed" belongs to a quick switch → ignore.
        if let active = Storage.activeApp, active != app {
            Storage.setLastSignal("\(app) closed (already switched to \(active))")
            closeSession(for: app, now: now)
            return
        }
        if let started = Storage.lastStart, now.timeIntervalSince(started) < switchWindow {
            Storage.setLastSignal("\(app) closed (ignored: app switch)")
            return
        }

        Storage.setLastSignal("\(app) closed")
        closeSession(for: app, now: now)
        Storage.lastStop = now
        Storage.activeApp = nil
        await NudgeScheduler.cancelAll()
    }

    // MARK: Helpers

    private static func closeSession(for app: String, now: Date) {
        var sessions = Storage.loadSessions()
        if let i = sessions.lastIndex(where: { $0.end == nil && $0.app == app }) {
            sessions[i].end = min(now, sessions[i].effectiveEnd(now: now))
            Storage.saveSessions(sessions)
        }
    }

    private static func clean(_ name: String) -> String {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Social apps" : t
    }

    /// Used when nudges are switched off / on in the app.
    static func refreshSchedule() async {
        if Storage.nudgesEnabled, Storage.activeApp != nil, let start = Storage.streakStart {
            await NudgeScheduler.scheduleNudges(streakStart: start)
        } else {
            await NudgeScheduler.cancelAll()
        }
    }
}
