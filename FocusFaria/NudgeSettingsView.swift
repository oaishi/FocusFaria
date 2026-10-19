//  NudgeSettingsView.swift
//  Function 3: turn the "don't waste time scrolling" nudges on/off and set them up.

import SwiftUI
import UIKit

struct NudgeSettingsView: View {
    @EnvironmentObject private var todos: TodoStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var name = Storage.userName ?? ""
    @State private var enabled = Storage.nudgesEnabled
    @State private var interval = Storage.intervalMinutes
    @State private var style = Storage.nudgeStyle
    @State private var notificationsAllowed = true
    @State private var nudgesToday = 0
    @State private var note: String?
    @State private var signalText: String?

    private let intervalOptions = [1, 5, 10, 15, 20, 30, 45, 60]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Your name", text: $name)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                } header: {
                    Text("Your name")
                } footer: {
                    Text("Used in your nudges: “\(name.isEmpty ? "Hey" : name), don't waste time scrolling 📵”")
                }

                Section {
                    Toggle(isOn: $enabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nudge me when I scroll too long").font(.headline)
                            Text(enabled ? "On — every \(interval) min on scrolling apps" : "Off")
                                .font(.caption)
                                .foregroundStyle(enabled ? Color.green : Color.secondary)
                        }
                    }
                    if let note {
                        Text(note).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section {
                    NavigationLink {
                        SetupGuideView()
                    } label: {
                        Label("Set up app tracking (one time, ~3 min)", systemImage: "wand.and.stars")
                    }
                    signalRow
                } header: {
                    Text("Connect your apps")
                } footer: {
                    Text("Apple's free Shortcuts app tells \(AppInfo.name) when you open or close Instagram, TikTok, YouTube… That's how tracking and nudges work without a paid developer account.")
                }

                Section("Nudge settings") {
                    Picker("Nudge every", selection: $interval) {
                        ForEach(intervalOptions, id: \.self) { m in
                            Text(m == 1 ? "1 minute (for testing)" : "\(m) minutes").tag(m)
                        }
                    }
                    Picker("Message type", selection: $style) {
                        ForEach(NudgeStyle.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section("Try it") {
                    Button {
                        Task {
                            if await NudgeScheduler.requestPermission() {
                                await NudgeScheduler.sendTest()
                                note = "Test nudge coming in 3 seconds… lock your phone to see it like a real one."
                            } else {
                                notificationsAllowed = false
                            }
                        }
                    } label: {
                        Label("Send a test nudge", systemImage: "paperplane")
                    }
                    if todos.pending.isEmpty && style != .quotesOnly {
                        Text("Add some to-dos so nudges can remind you of them. Until then you'll get motivation quotes.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Text(nudgesToday == 0 ? "No nudges today yet 🎉" : "Nudged \(nudgesToday) time\(nudgesToday == 1 ? "" : "s") today")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Permissions") {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        if notificationsAllowed {
                            Label("Allowed", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                        } else {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
            }
            .navigationTitle("Nudges")
            .task { await refresh(askPermission: true) }
            .onChange(of: scenePhase) { phase in
                if phase == .active { Task { await refresh(askPermission: false) } }
            }
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: name) { v in
                Storage.userName = v
                Task { await ScrollTracker.refreshSchedule() }
            }
            .onChange(of: enabled) { on in
                Storage.nudgesEnabled = on
                note = nil
                Task {
                    if on, !(await NudgeScheduler.requestPermission()) {
                        notificationsAllowed = false
                        note = "Please allow notifications for \(AppInfo.name) in Settings, otherwise nudges can't appear."
                    }
                    await ScrollTracker.refreshSchedule()
                }
            }
            .onChange(of: interval) { v in
                Storage.intervalMinutes = v
                Task { await ScrollTracker.refreshSchedule() }
            }
            .onChange(of: style) { v in
                Storage.nudgeStyle = v
                Task { await ScrollTracker.refreshSchedule() }
            }
        }
    }

    private var signalRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Last signal from Shortcuts").font(.subheadline)
            if let signalText {
                Text(signalText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("None yet — finish the setup, then open one of your apps.")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func refresh(askPermission: Bool) async {
        if askPermission {
            notificationsAllowed = await NudgeScheduler.requestPermission()
        } else {
            notificationsAllowed = await NudgeScheduler.isAllowed()
        }
        if let s = Storage.lastSignal {
            signalText = "\(s.text) · \(s.date.formatted(.relative(presentation: .named)))"
        } else {
            signalText = nil
        }
        nudgesToday = await NudgeScheduler.nudgesToday()
    }
}
