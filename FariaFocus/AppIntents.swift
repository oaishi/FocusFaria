//  AppIntents.swift
//  Two actions that appear in Apple's free Shortcuts app under this app:
//    • "Scrolling App Opened"  → use in an automation: When Instagram is Opened
//    • "Scrolling App Closed"  → use in an automation: When Instagram is Closed
//  They run quietly in the background — the app doesn't pop open.

import AppIntents

struct ScrollingAppOpenedIntent: AppIntent {
    static let title: LocalizedStringResource = "Scrolling App Opened"
    static let description = IntentDescription(
        "Tell the app you opened a scrolling app. It starts tracking the time and schedules your nudge."
    )
    static let openAppWhenRun: Bool = false

    @Parameter(title: "App name", default: "Social apps")
    var appName: String

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$appName) was opened")
    }

    func perform() async throws -> some IntentResult {
        await ScrollTracker.appOpened(appName)
        return .result()
    }
}

struct ScrollingAppClosedIntent: AppIntent {
    static let title: LocalizedStringResource = "Scrolling App Closed"
    static let description = IntentDescription(
        "Tell the app you left a scrolling app. It stops the timer and cancels the waiting nudge."
    )
    static let openAppWhenRun: Bool = false

    @Parameter(title: "App name", default: "Social apps")
    var appName: String

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$appName) was closed")
    }

    func perform() async throws -> some IntentResult {
        await ScrollTracker.appClosed(appName)
        return .result()
    }
}

/// Registers both actions with Shortcuts, so the app shows up in the
/// "Add Action" list right after install, without searching.
struct FocusShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ScrollingAppOpenedIntent(),
                    phrases: ["Scrolling app opened in \(.applicationName)"])
        AppShortcut(intent: ScrollingAppClosedIntent(),
                    phrases: ["Scrolling app closed in \(.applicationName)"])
    }
}
