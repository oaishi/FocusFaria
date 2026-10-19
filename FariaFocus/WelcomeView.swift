//  WelcomeView.swift
//  First launch: ask for the name used in nudges, then offer the tracking setup.

import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var showSetup = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("Welcome to \(AppInfo.name)")
                    .font(.largeTitle.bold())
                Text("What should your nudges call you?")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                TextField("Your first name", text: $name)
                    .textContentType(.givenName)
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .onSubmit { nameFocused = false }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                Text(preview)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    Storage.userName = name
                    showSetup = true
                } label: {
                    Text("Next: connect my apps").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Skip for now") {
                    Storage.userName = name
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(24)
            .navigationDestination(isPresented: $showSetup) { SetupGuideView() }
            .onChange(of: showSetup) { shown in
                // Finishing the guide closes the welcome screen too.
                if !shown { dismiss() }
            }
        }
        .interactiveDismissDisabled()
    }

    private var preview: String {
        let n = name.trimmingCharacters(in: .whitespaces)
        return "Your nudges will look like: “\(n.isEmpty ? "Hey" : n), don't waste time scrolling 📵”"
    }
}
