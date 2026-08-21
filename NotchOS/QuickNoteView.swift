//
//  QuickNoteView.swift
//  NotchOS
//
//  Copyright © 2026 Ishan Gupta. MIT License.
//

import SwiftUI

// MARK: - QuickNote Manager

class QuickNoteManager: ObservableObject {
    static let shared = QuickNoteManager()

    struct NoteItem: Identifiable, Codable, Equatable {
        let id: UUID
        var text: String
        var isDone: Bool

        init(id: UUID = UUID(), text: String, isDone: Bool = false) {
            self.id = id
            self.text = text
            self.isDone = isDone
        }
    }

    @Published var notes: [NoteItem] = [] {
        didSet { save() }
    }

    private let storageURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("NotchOS", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("quicknotes.json")
    }()

    private init() {
        load()
    }

    func addNote(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        notes.append(NoteItem(text: text))
    }

    func toggleNote(_ id: UUID) {
        guard let idx = notes.firstIndex(where: { $0.id == id }) else { return }
        notes[idx].isDone.toggle()
    }

    func deleteNote(_ id: UUID) {
        notes.removeAll { $0.id == id }
    }

    // Serial queue keeps writes ordered while staying off the main thread.
    private let saveQueue = DispatchQueue(label: "quicknote.save", qos: .utility)

    private func save() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        let url = storageURL
        saveQueue.async {
            try? data.write(to: url, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([NoteItem].self, from: data)
        else { return }
        notes = decoded
    }
}

// MARK: - QuickNote View (split row component)

struct QuickNoteView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject private var manager = QuickNoteManager.shared
    @State private var newNoteText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("QUICK NOTE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(0.5)
                Spacer()
                Image(systemName: "note.text")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(.bottom, 8)

            // Notes list
            if manager.notes.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No notes yet")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.2))
                    Spacer()
                }
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(manager.notes.prefix(3)) { note in
                        noteRow(note)
                    }
                }
                Spacer(minLength: 0)
            }

            // Inline add
            HStack(spacing: 6) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.25))
                TextField("Add note...", text: $newNoteText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
                    .focused($isInputFocused)
                    .onSubmit {
                        manager.addNote(newNoteText)
                        newNoteText = ""
                    }
            }
            .padding(.top, 4)
        }
        .padding(10)
    }

    func noteRow(_ note: QuickNoteManager.NoteItem) -> some View {
        NoteRow(note: note, vm: vm, manager: manager)
    }

    private struct NoteRow: View {
        let note: QuickNoteManager.NoteItem
        let vm: NotchViewModel
        @ObservedObject var manager: QuickNoteManager
        @State private var hovering = false

        var body: some View {
            HStack(spacing: 8) {
                Button {
                    withAnimation(vm.animation) {
                        manager.toggleNote(note.id)
                    }
                } label: {
                    Image(systemName: note.isDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(note.isDone ? .green : .white.opacity(0.25))
                }
                .buttonStyle(.plain)

                Text(note.text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(note.isDone ? .white.opacity(0.3) : .white.opacity(0.8))
                    .strikethrough(note.isDone, color: .white.opacity(0.2))
                    .lineLimit(1)

                Spacer(minLength: 0)

                if hovering {
                    Button {
                        withAnimation(vm.animation) {
                            manager.deleteNote(note.id)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
        }
    }
}
