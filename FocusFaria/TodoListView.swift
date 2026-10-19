//  TodoListView.swift
//  Function 1: input your to-dos.

import SwiftUI

struct TodoListView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var newTitle = ""
    @State private var editing: TodoItem?
    @State private var editText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("What do you need to do?", text: $newTitle)
                            .focused($inputFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                // Return adds the to-do and closes the keyboard.
                                addItem()
                                inputFocused = false
                            }
                        Button(action: addItem) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("Add to-do")
                    }
                }

                if store.items.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.largeTitle)
                                .foregroundStyle(.tint)
                            Text("No to-dos yet")
                                .font(.headline)
                            Text("Add a few — \(AppInfo.name) will remind you of one when you've been scrolling too long.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }

                if !store.pending.isEmpty {
                    Section("To do (\(store.pending.count))") {
                        ForEach(store.pending) { item in row(item) }
                            .onDelete { offsets in
                                store.delete(ids: offsets.map { store.pending[$0].id })
                            }
                    }
                }

                if !store.done.isEmpty {
                    Section {
                        ForEach(store.done) { item in row(item) }
                            .onDelete { offsets in
                                store.delete(ids: offsets.map { store.done[$0].id })
                            }
                    } header: {
                        HStack {
                            Text("Done (\(store.done.count))")
                            Spacer()
                            Button("Clear") { withAnimation { store.clearDone() } }
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("My To-Dos")
            // Scrolling the list or tapping "Done" above the keyboard closes it.
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { inputFocused = false }
                }
            }
            .alert("Edit to-do", isPresented: Binding(
                get: { editing != nil },
                set: { if !$0 { editing = nil } }
            )) {
                TextField("Title", text: $editText)
                Button("Save") {
                    if let item = editing { store.rename(item, to: editText) }
                    editing = nil
                }
                Button("Cancel", role: .cancel) { editing = nil }
            }
        }
    }

    @ViewBuilder
    private func row(_ item: TodoItem) -> some View {
        Button {
            inputFocused = false
            withAnimation { store.toggle(item) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isDone ? Color.green : Color.secondary)
                Text(item.title)
                    .strikethrough(item.isDone)
                    .foregroundStyle(item.isDone ? .secondary : .primary)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            Button {
                editText = item.title
                editing = item
            } label: { Label("Edit", systemImage: "pencil") }
            .tint(.orange)
        }
    }

    private func addItem() {
        withAnimation { store.add(newTitle) }
        newTitle = ""
    }
}
