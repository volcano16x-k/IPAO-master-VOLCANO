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
    
    // حالة التنقل بين الواجهات
    @State private var currentScreen: AppScreen = .folders
    
    @State private var isWritingNote = false
    @State private var noteContent = ""
    @FocusState private var isNoteFocused: Bool

    @AppStorage("saved_notes") private var savedNotesData: Data = Data()
    @State private var notesList: [NoteItem] = []

    enum AppScreen {
        case folders
        case notesList
    }

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

            if currentScreen == .folders {
                foldersView
            } else {
                notesListView
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

    // MARK: - Folders View (الواجهة الرئيسية الأولى للمجلدات)

    private var foldersView: some View {
        VStack(spacing: 0) {
            // شريط علوي للمجلدات
            HStack(spacing: 12) {
                Spacer()
                Button {} label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(chipFill, in: Circle())
                        .overlay(Circle().stroke(strokeColor, lineWidth: 1))
                }
                Button {} label: {
                    Text("Modifier")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(chipFill, in: Capsule())
                        .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)

            // عنوان Dossiers
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Dossiers")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                }

                Text("iCloud")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // عنصر مجلد Notes للانتقال
            VStack(spacing: 0) {
                Button {
                    currentScreen = .notesList
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.yellow)

                        Text("Notes")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)

                        Spacer()

                        Text("\(notesList.count)")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.gray)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color(white: 0.11), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }

            Spacer(minLength: 0)

            // شريط البحث السفلي
            bottomBar
        }
    }

    // MARK: - Notes List View (واجهة الملاحظات الحالية)

    private var notesListView: some View {
        VStack(spacing: 0) {
            // شريط علوي للرجوع
            HStack(spacing: 12) {
                Button {
                    currentScreen = .folders
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("Dossiers")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(.yellow)
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

            // العنوان الرئيسي (Notes)
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

                TextEditor(text: $noteContent)
                    .focused($isNoteFocused)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                    .foregroundStyle(.white)
                    .font(.system(size: 18))
                    .padding(16)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 22) {
                                    Button(action: { appendFormatting(tag: "**") }) {
                                        Text("Aa").font(.system(size: 16, weight: .bold))
                                    }
                                    Button(action: { appendFormatting(tag: "- ") }) {
                                        Image(systemName: "list.bullet")
                                    }
                                    Button(action: { appendFormatting(tag: "| |") }) {
                                        Image(systemName: "tablecells")
                                    }
                                    Button(action: { appendFormatting(tag: "---") }) {
                                        Image(systemName: "paperclip")
                                    }
                                    Button(action: { appendFormatting(tag: "*") }) {
                                        Image(systemName: "pencil.tip.crop.circle")
                                    }
                                    Button(action: { appendFormatting(tag: "[]") }) {
                                        Image(systemName: "link")
                                    }
                                }
                                .foregroundStyle(.white)
                            }
                        }
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
