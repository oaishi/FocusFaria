//  NudgeScheduler.swift
//  Builds the "<name>, don't waste time scrolling" messages and schedules them
//  as local notifications (free – no paid developer account needed).

import Foundation
import UserNotifications

enum NudgeScheduler {

    /// Original motivational lines — edit or add your own!
    static var quotes: [String] { [
        "Small steps today beat perfect plans tomorrow.",
        "The feed will still be there. Your goals won't wait forever.",
        "You don't need more time — you need this minute.",
        "Future \(name ?? "you") will thank you for what you do right now.",
        "Done is better than perfect. Start with just five minutes.",
        "Put the phone down, pick your dream up.",
        "One finished task feels better than an hour of scrolling.",
        "Your attention is precious — spend it on purpose.",
        "Close the app, open the opportunity.",
        "Great days are built from small, focused minutes.",
        "You are capable of amazing things. Start one now.",
        "Breathe. Stretch. Then do the next small thing.",
        "Scrolling fills time. Doing fills your life.",
        "Be the person your to-do list believes you are.",
        "Five focused minutes > fifty distracted ones."
    ] }

    /// The saved name, or nil if the user skipped it.
    private static var name: String? {
        guard let n = Storage.userName, !n.isEmpty else { return nil }
        return n
    }

    private static let maxPending = 12
    private static let idPrefix = "faria.nudge."

    // MARK: Message

    static func makeContent(minutesUsed: Int?) -> UNMutableNotificationContent {
        let pending = Storage.loadTodos().filter { !$0.isDone }

        let useTodo: Bool
        switch Storage.nudgeStyle {
        case .todosOnly:  useTodo = !pending.isEmpty
        case .quotesOnly: useTodo = false
        case .mix:        useTodo = !pending.isEmpty && Bool.random()
        }

        let content = UNMutableNotificationContent()
        if let m = minutesUsed { content.subtitle = "You've been scrolling for \(m) min" }
        content.sound = .default

        if useTodo, let todo = pending.randomElement() {
            content.title = "\(name ?? "Hey"), don't waste time scrolling 📵"
            content.body = "Have you done this? 👉 \(todo.title)"
        } else {
            content.title = name.map { "\($0), a little motivation ✨" } ?? "A little motivation ✨"
            content.body = quotes.randomElement() ?? "You've got this!"
        }
        return content
    }

    // MARK: Schedule / cancel

    /// Schedules nudges at streakStart + 1×, 2×, 3× … interval (only the ones still in the future).
    static func scheduleNudges(streakStart: Date, now: Date = Date()) async {
        await cancelAll()
        guard Storage.nudgesEnabled else { return }

        let step = TimeInterval(Storage.intervalMinutes * 60)
        let center = UNUserNotificationCenter.current()
        var k = 1
        var scheduled = 0
        while scheduled < maxPending && k <= 48 {
            let fireDate = streakStart.addingTimeInterval(step * Double(k))
            let wait = fireDate.timeIntervalSince(now)
            if wait > 2 {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: wait, repeats: false)
                let request = UNNotificationRequest(
                    identifier: idPrefix + UUID().uuidString,
                    content: makeContent(minutesUsed: k * Storage.intervalMinutes),
                    trigger: trigger
                )
                try? await center.add(request)
                scheduled += 1
            }
            k += 1
        }
    }

    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Nudges you received today (that are still in Notification Center).
    static func nudgesToday() async -> Int {
        await UNUserNotificationCenter.current().deliveredNotifications()
            .filter { $0.request.identifier.hasPrefix(idPrefix) && Calendar.current.isDateInToday($0.date) }
            .count
    }

    static func sendTest() async {
        let request = UNNotificationRequest(
            identifier: "faria.test",
            content: makeContent(minutesUsed: Storage.intervalMinutes),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: Permission

    static func isAllowed() async -> Bool {
        let s = await UNUserNotificationCenter.current().notificationSettings()
        return s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
    }

    @discardableResult
    static func requestPermission() async -> Bool {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
        return await isAllowed()
    }
}
