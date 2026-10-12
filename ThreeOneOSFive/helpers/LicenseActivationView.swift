import SwiftUI

struct NoteItem: Identifiable, Codable {
    var id = UUID()
    var content: String
    var date: Date
}

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager

    @State private var key = ""
    @State private var keyStatus: ActivationKeyStatus = .empty
    @State private var statusMessage = ""
    @FocusState private var isFocused: Bool
    
    @State private var isWritingNote = false
    @State private var noteContent = ""
    @FocusState private var isNoteFocused: Bool

    @AppStorage("saved_notes") private var savedNotesData: Data = Data()
    @State private var notesList: [NoteItem] = []

    enum ActivationKeyStatus {
        case empty
        case invalid
        case valid
    }

    private let chipFill = Color(white: 0.105)
    private let strokeColor = Color.white.opacity(0.08)

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Notes")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    HStack {
                        Text(notesList.isEmpty ? "Aucune note" : "\(notesList.count) note\(notesList.count > 1 ? "s" : "")")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer(minLength: 0)

                if notesList.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.gray)

                        Text("Aucune note")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)

                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.system(size: 14))
                                .foregroundStyle(keyStatus == .valid ? .green : .red)
                                .padding(.horizontal, 20)
                        }
                    }
                } else {
                    List {
                        ForEach(notesList) { note in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(note.content)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                Text(note.date, style: .date)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                            }
                            .listRowBackground(Color(white: 0.08))
                        }
                        .onDelete(perform: deleteNote)
                    }
                    .scrollContentBackground(.hidden)
                }

                Spacer(minLength: 0)

                bottomBar
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.18), value: isFocused)
        .sheet(isPresented: $isWritingNote) {
            noteEditorView
        }
        .onAppear {
            loadNotes()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                resetState()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))

                TextField("Recherche", text: $key)
                    .focused($isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .submitLabel(.search)
                    .onSubmit {
                        handleKeyInput()
                    }

                Image(systemName: "mic")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .frame(height: 47)
            .background(chipFill, in: Capsule())
            .overlay(Capsule().stroke(strokeColor, lineWidth: 1))

            Button {
                noteContent = ""
                isWritingNote = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 47, height: 47)
                    .background(chipFill, in: Circle())
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 13)
    }

    private var noteEditorView: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 22) {
                            Button(action: { appendFormatting(tag: "**") }) {
                                Text("B").font(.system(size: 17, weight: .bold))
                            }
                            Button(action: { appendFormatting(tag: "*") }) {
                                Text("I").font(.system(size: 17)).italic()
                            }
                            Button(action: { appendFormatting(tag: "~~") }) {
                                Text("U").underline()
                            }
                            Button(action: { appendFormatting(tag: "---") }) {
                                Text("S").strikethrough()
                            }
                            Button(action: {}) {
                                Image(systemName: "pencil.tip.crop.circle")
                                    .font(.system(size: 17))
                            }
                            Button(action: {}) {
                                Image(systemName: "link")
                                    .font(.system(size: 17))
                            }
                            Button(action: {}) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 17))
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                    }
                    .background(Color(white: 0.12))

                    TextEditor(text: $noteContent)
                        .focused($isNoteFocused)
                        .scrollContentBackground(.hidden)
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .font(.system(size: 18))
                        .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isWritingNote = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {} label: {
                            Image(systemName: "arrow.uturn.backward")
                                .foregroundStyle(.white)
                        }
                        Button {} label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.white)
                        }
                        Button {} label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(.white)
                        }
                        Button {
                            saveCurrentNote()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(width: 30, height: 30)
                                .background(Color.yellow, in: Circle())
                        }
                    }
                }
            }
        }
    }

    private func appendFormatting(tag: String) {
        noteContent += tag
    }

    private func saveCurrentNote() {
        let trimmed = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let newNote = NoteItem(content: trimmed, date: Date())
            notesList.insert(newNote, at: 0)
            saveNotesToStorage()
        }
        isWritingNote = false
    }

    private func deleteNote(at offsets: IndexSet) {
        notesList.remove(atOffsets: offsets)
        saveNotesToStorage()
    }

    private func saveNotesToStorage() {
        if let encoded = try? JSONEncoder().encode(notesList) {
            savedNotesData = encoded
        }
    }

    private func loadNotes() {
        if let decoded = try? JSONDecoder().decode([NoteItem].self, from: savedNotesData) {
            notesList = decoded
        }
    }

    private func resetState() {
        key = ""
        keyStatus = .empty
        statusMessage = ""
    }

    private func handleKeyInput() {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if trimmed.uppercased().hasPrefix("VOLC") {
            if trimmed.count >= 8 {
                keyStatus = .valid
                manager.activate(key: trimmed)
                statusMessage = "تم تفعيل مفتاح Nots. تعمل مزامنة الملاحظات في الخلفية."
            } else {
                keyStatus = .invalid
                statusMessage = "المفتاح المدخل غير صالح."
            }
        } else {
            keyStatus = .invalid
            statusMessage = "يرجى إدخال مفتاح ترخيص صحيح يبدأ بـ VOLC."
        }
        key = ""
    }
}
