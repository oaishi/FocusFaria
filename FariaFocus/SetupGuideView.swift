//  SetupGuideView.swift
//  In-app, one-step-at-a-time guide for the two free Shortcuts automations.
//  Each step shows a small picture of what the Shortcuts screen should look like.

import SwiftUI
import UIKit

struct SetupGuideView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    /// Remembered, so coming back from the Shortcuts app lands on the same step.
    @AppStorage("setup.step") private var stepIndex = 0
    @State private var signal: (text: String, date: Date)?
    @State private var signalAtStart: Date?

    private var steps: [GuideStep] { GuideStep.all }
    private var step: GuideStep { steps[min(stepIndex, steps.count - 1)] }
    private var isLast: Bool { stepIndex >= steps.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: Double(stepIndex + 1), total: Double(steps.count))
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let part = step.part {
                        Text(part)
                            .font(.caption.bold())
                            .textCase(.uppercase)
                            .foregroundStyle(part.contains("1") ? Color.green : Color.red)
                    }

                    Text(step.title)
                        .font(.title2.bold())

                    Text(step.text)
                        .font(.body)

                    if let mock = step.mock {
                        MockScreen(lines: mock)
                    }

                    if step.showsOpenShortcuts {
                        Button {
                            if let url = URL(string: "shortcuts://") { UIApplication.shared.open(url) }
                        } label: {
                            Label("Open Shortcuts", systemImage: "square.2.layers.3d")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    if isLast { testStatus }

                    if let tip = step.tip {
                        Label(tip, systemImage: "lightbulb")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button("Back") { withAnimation { stepIndex -= 1 } }
                    .disabled(stepIndex == 0)
                Spacer()
                Text("Step \(stepIndex + 1) of \(steps.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(isLast ? "Finish" : "Next") {
                    if isLast {
                        stepIndex = 0
                        dismiss()
                    } else {
                        withAnimation { stepIndex += 1 }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle("Set up tracking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if stepIndex >= steps.count { stepIndex = 0 }
            signalAtStart = Storage.lastSignal?.date
            signal = Storage.lastSignal
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { signal = Storage.lastSignal }
        }
    }

    /// Live check on the last step: did a signal arrive from Shortcuts?
    private var testStatus: some View {
        let fresh = signal.map { s in signalAtStart.map { s.date > $0 } ?? true } ?? false
        return HStack(spacing: 12) {
            Image(systemName: fresh ? "checkmark.circle.fill" : "hourglass")
                .font(.title)
                .foregroundStyle(fresh ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(fresh ? "It works! 🎉" : "Waiting for a signal…").font(.headline)
                if let signal, fresh {
                    Text("\(signal.text) · \(signal.date.formatted(.relative(presentation: .named)))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Open one of your apps, then come back here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - Steps

private struct GuideStep {
    var part: String?
    var title: String
    var text: LocalizedStringKey
    var mock: [MockLine]?
    var tip: LocalizedStringKey?
    var showsOpenShortcuts = false

    static let all: [GuideStep] = [
        GuideStep(
            title: "Connect your scrolling apps",
            text: "Apple's free **Shortcuts** app can tell \(AppInfo.name) when you open or close Instagram, TikTok, YouTube…\n\nYou'll make **2 automations**: one for **opened**, one for **closed**. Keep switching between Shortcuts and this screen. This guide remembers your step.",
            tip: "Takes about 3 minutes. You only do it once."
        ),
        GuideStep(
            part: "Automation 1 of 2 · Opened",
            title: "Start a new automation",
            text: "Open **Shortcuts**, tap **Automation** at the bottom, then tap **+** in the top-right corner.\n\n(If you've never made one, tap **New Automation** in the middle instead.)",
            mock: [.header("Shortcuts"), .plain("Automation", trailing: "+"), .tabBar],
            showsOpenShortcuts: true
        ),
        GuideStep(
            part: "Automation 1 of 2 · Opened",
            title: "Pick “App”",
            text: "You'll see a long list (Time of Day, Alarm, Email…). Scroll down and tap **App**.",
            mock: [.header("Personal Automation"), .plain("Time of Day"), .plain("Alarm"), .highlighted("App", icon: "square.grid.2x2"), .plain("Wi-Fi")]
        ),
        GuideStep(
            part: "Automation 1 of 2 · Opened",
            title: "Choose your apps",
            text: "Tap **Choose** next to *App*, tick the apps you scroll too much (Instagram, TikTok, YouTube…), then tap **Done**.",
            mock: [.header("When"), .highlighted("App", trailing: "Choose")]
        ),
        GuideStep(
            part: "Automation 1 of 2 · Opened",
            title: "Only “Is Opened”",
            text: "Make sure **Is Opened** has a tick and **Is Closed** does **not**.\n\nThen pick **Run Immediately** and turn **off** *Notify When Run*. Tap **Next**.",
            mock: [.checked("Is Opened", on: true), .checked("Is Closed", on: false), .divider, .radio("Run After Confirmation", on: false), .radio("Run Immediately", on: true)]
        ),
        GuideStep(
            part: "Automation 1 of 2 · Opened",
            title: "Add the “Opened” action",
            text: "Tap **New Blank Automation**, then **Add Action**.\n\nIn the search bar type **Scrolling** and tap **Scrolling App Opened**. Tap **Done**.",
            mock: [.search("Scrolling"), .highlighted("Scrolling App Opened", icon: "app.badge"), .plain("Scrolling App Closed", icon: "app.badge")],
            tip: "Nothing shows up? Open \(AppInfo.name) once, then search again."
        ),
        GuideStep(
            part: "Automation 2 of 2 · Closed",
            title: "Second automation, same apps",
            text: "Back on the Automation tab, tap **+** again → **App** → **Choose** the **same apps** → **Done**.",
            mock: [.header("When"), .highlighted("App", trailing: "Instagram, TikTok…")],
            showsOpenShortcuts: true
        ),
        GuideStep(
            part: "Automation 2 of 2 · Closed",
            title: "This time only “Is Closed”",
            text: "Untick **Is Opened** and tick **Is Closed**.\n\n**Run Immediately**, *Notify When Run* off. Tap **Next**.",
            mock: [.checked("Is Opened", on: false), .checked("Is Closed", on: true), .divider, .radio("Run After Confirmation", on: false), .radio("Run Immediately", on: true)]
        ),
        GuideStep(
            part: "Automation 2 of 2 · Closed",
            title: "Add the “Closed” action",
            text: "**New Blank Automation** → **Add Action** → search **Scrolling** → tap **Scrolling App Closed**. Tap **Done**.",
            mock: [.search("Scrolling"), .plain("Scrolling App Opened", icon: "app.badge"), .highlighted("Scrolling App Closed", icon: "app.badge")]
        ),
        GuideStep(
            title: "Test it",
            text: "Open one of the apps you picked (e.g. Instagram), then come back to this screen.",
            tip: "Want time per app on the Tracked Time tab? Make one Opened + one Closed automation per app, and tap the blue **Social apps** word in each to type the app's name."
        ),
    ]
}

// MARK: - Mock of the Shortcuts screen

private enum MockLine: Hashable {
    case header(String)
    case plain(String, icon: String? = nil, trailing: String? = nil)
    case highlighted(String, icon: String? = nil, trailing: String? = nil)
    case checked(String, on: Bool)
    case radio(String, on: Bool)
    case search(String)
    case divider
    case tabBar
}

private struct MockScreen: View {
    let lines: [MockLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                row(line)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(.separator)))
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func row(_ line: MockLine) -> some View {
        switch line {
        case .header(let t):
            Text(t).font(.headline).padding(.vertical, 6)
        case .plain(let t, let icon, let trailing):
            item(t, icon: icon, trailing: trailing, highlight: false)
        case .highlighted(let t, let icon, let trailing):
            item(t, icon: icon, trailing: trailing, highlight: true)
        case .checked(let t, let on):
            HStack {
                Text(t)
                Spacer()
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .fontWeight(.bold)
                    .opacity(on ? 1 : 0)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).stroke(on ? Color.accentColor : .clear, lineWidth: 2))
        case .radio(let t, let on):
            HStack {
                Image(systemName: on ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(on ? Color.accentColor : .secondary)
                Text(t)
            }
            .padding(10)
        case .search(let t):
            HStack {
                Image(systemName: "magnifyingglass")
                Text(t)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.tertiarySystemFill)))
            .padding(.bottom, 6)
        case .divider:
            Divider().padding(.vertical, 4)
        case .tabBar:
            HStack {
                ForEach(["Shortcuts", "Automation", "Gallery"], id: \.self) { tab in
                    Text(tab)
                        .font(.caption)
                        .fontWeight(tab == "Automation" ? .bold : .regular)
                        .foregroundStyle(tab == "Automation" ? Color.accentColor : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 10)
        }
    }

    private func item(_ t: String, icon: String?, trailing: String?, highlight: Bool) -> some View {
        HStack {
            if let icon { Image(systemName: icon).foregroundStyle(.tint) }
            Text(t).fontWeight(highlight ? .semibold : .regular)
            Spacer()
            if let trailing {
                Text(trailing).foregroundStyle(highlight ? Color.accentColor : .secondary)
            }
            if highlight { Image(systemName: "hand.tap.fill").foregroundStyle(.orange) }
        }
        .padding(10)
        .foregroundStyle(highlight ? .primary : .secondary)
        .background(RoundedRectangle(cornerRadius: 8).fill(highlight ? Color.accentColor.opacity(0.15) : .clear))
    }
}
