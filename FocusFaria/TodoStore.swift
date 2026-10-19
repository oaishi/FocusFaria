//  TodoStore.swift
//  Keeps the to-do list in sync with the phone storage.

import Foundation
import Combine

@MainActor
final class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = Storage.loadTodos() {
        didSet { Storage.saveTodos(items) }
    }

    var pending: [TodoItem] { items.filter { !$0.isDone } }
    var done: [TodoItem] { items.filter { $0.isDone } }

    func add(_ text: String) {
        let title = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        items.insert(TodoItem(title: title), at: 0)
    }

    func toggle(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].isDone.toggle()
    }

    func rename(_ item: TodoItem, to text: String) {
        let title = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].title = title
    }

    func delete(ids: [UUID]) {
        items.removeAll { ids.contains($0.id) }
    }

    func clearDone() {
        items.removeAll { $0.isDone }
    }
}
