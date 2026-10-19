//  ContentView.swift
//  Three tabs: To-Dos · Tracked Time · Nudges

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var usage: UsageStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showWelcome = Storage.userName == nil

    var body: some View {
        TabView {
            TodoListView()
                .tabItem { Label("To-Dos", systemImage: "checklist") }

            ScreenTimeView()
                .tabItem { Label("Tracked Time", systemImage: "hourglass") }

            NudgeSettingsView()
                .tabItem { Label("Nudges", systemImage: "bell.badge") }
        }
        .sheet(isPresented: $showWelcome) { WelcomeView() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { usage.reload() }
        }
    }
}
