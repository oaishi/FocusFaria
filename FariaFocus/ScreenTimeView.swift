//  ScreenTimeView.swift
//  Function 2: which scrolling apps you used today and for how long.
//  (Data comes from your Shortcuts automations. For whole-phone screen time,
//   Apple's built-in Settings › Screen Time is free and always on.)

import SwiftUI

struct ScreenTimeView: View {
    @EnvironmentObject private var usage: UsageStore
    @State private var dayOffset = 0
    @State private var confirmClear = false

    private var day: Date {
        Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Day", selection: $dayOffset) {
                        Text("Today").tag(0)
                        Text("Yesterday").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if let live = usage.liveSession, dayOffset == 0 {
                        liveCard(live)
                    }

                    summaryCard
                    hourlyCard
                    appsCard
                    builtInCard
                }
                .padding()
            }
            .navigationTitle("Tracked Time")
            .refreshable { usage.reload() }
            .toolbar {
                Menu {
                    Button { usage.reload() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    Button(role: .destructive) { confirmClear = true } label: {
                        Label("Clear history", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            .confirmationDialog("Clear all tracked time?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) { usage.clearAll() }
            }
        }
    }

    // MARK: Cards

    private func liveCard(_ s: UsageSession) -> some View {
        HStack(spacing: 12) {
            Circle().fill(.red).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text("Now: \(s.app)").font(.headline)
                Text("for \(TimeText.format(s.duration(now: usage.now)))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }

    private var summaryCard: some View {
        let total = usage.total(on: day)
        let longest = usage.longestSession(on: day)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Time on scrolling apps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(TimeText.format(total))
                .font(.system(size: 44, weight: .bold, design: .rounded))
            if longest > 0 {
                Text("Longest stretch: \(TimeText.format(longest))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var hourlyCard: some View {
        let hours = usage.hourly(on: day)
        let maxValue = max(hours.max() ?? 0, 60)
        return VStack(alignment: .leading, spacing: 8) {
            Text("By hour").font(.headline)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<24, id: \.self) { h in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(hours[h] > 0 ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: max(3, CGFloat(hours[h] / maxValue) * 90))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90, alignment: .bottom)
            HStack {
                Text("12 AM"); Spacer(); Text("6 AM"); Spacer(); Text("12 PM"); Spacer(); Text("6 PM"); Spacer(); Text("11 PM")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var appsCard: some View {
        let apps = usage.perApp(on: day)
        let top = apps.first?.duration ?? 1
        return VStack(alignment: .leading, spacing: 12) {
            Text("Apps").font(.headline)
            if apps.isEmpty {
                Text("Nothing tracked yet. Set up the two Shortcuts automations in the Nudges tab › “Set up app tracking”, then open one of your apps.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(apps) { a in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(a.app).lineLimit(1)
                        Spacer()
                        Text("\(TimeText.format(a.duration)) · \(a.sessions)×")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.accentColor.opacity(0.8))
                            .frame(width: max(4, geo.size.width * CGFloat(a.duration / top)))
                    }
                    .frame(height: 5)
                }
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var builtInCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Whole-phone screen time", systemImage: "hourglass")
                .font(.headline)
            Text("Your iPhone already tracks every app for free: open **Settings › Screen Time › See All App & Website Activity**. This tab shows the apps you connected to \(AppInfo.name).")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
