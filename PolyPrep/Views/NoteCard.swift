import SwiftUI
import AVFoundation

struct NoteCard: View {
    @State /*private */var note: Note
    @State private var isLiked: Bool
    @State private var isSaved: Bool
    @State private var isExpanded = false
    @State private var textHeight: CGFloat = 0
    @State private var hashtagColors: [Color]
    @Binding var savedNotes: [Note]
    @ObservedObject var notesManager: NotesManager
    @State private var showComments = false
    @State private var showDeleteAlert = false
    @State private var showLikeAlert = false
    @State private var showSaveAlert = false
    var currentUsername: String
    
    private var likesCount: Int {
        if let savedNote = savedNotes.first(where: { $0.id == note.id }) {
            return savedNote.likesCount
        }
        return note.likesCount
    }
    
    private var commentsCount: Int {
        if let savedNote = savedNotes.first(where: { $0.id == note.id }) {
            return savedNote.commentsCount
        }
        return note.commentsCount
    }
    
    private var comments: [Comment] {
        if let savedNote = savedNotes.first(where: { $0.id == note.id }) {
            return savedNote.comments
        }
        return note.comments
    }
    
    init(note: Note, savedNotes: Binding<[Note]>, notesManager: NotesManager, currentUsername: String) {
        self.note = note
        self._savedNotes = savedNotes
        self.notesManager = notesManager
        self.currentUsername = currentUsername
        self._hashtagColors = State(initialValue: Self.generateRandomColors(count: note.hashtags.count))
        self.isLiked = note.isLiked
        self.isSaved = note.isSaved
    }
    
    private static func generateRandomColors(count: Int) -> [Color] {
        return (0..<count).map { _ in
            Color(
                red: Double.random(in: 0...1),
                green: Double.random(in: 0...1),
                blue: Double.random(in: 0...1)
            )
        }
    }
    
    private func textColor(for backgroundColor: Color) -> Color {
        let components = backgroundColor.cgColor?.components ?? [0, 0, 0, 1]
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness > 0.5 ? .black : .white
    }
    
    private func toggleLike() {
        if isSaved {
            if let index = savedNotes.firstIndex(where: { $0.id == note.id }) {
                let updatedNote = savedNotes[index]
                updatedNote.isLiked.toggle()
                updatedNote.likesCount += updatedNote.isLiked ? 1 : -1
                savedNotes[index] = updatedNote
                notesManager.updateNoteLikes(noteId: note.id, isLiked: updatedNote.isLiked, likesCount: updatedNote.likesCount)
            }
        } else {
            let updatedNote = note
            updatedNote.isLiked.toggle()
            updatedNote.likesCount += updatedNote.isLiked ? 1 : -1
            notesManager.updateNoteLikes(noteId: note.id, isLiked: updatedNote.isLiked, likesCount: updatedNote.likesCount)
        }
    }
    
    private func toggleSaveNote() {
        if isSaved {
            savedNotes.removeAll(where: { $0.id == note.id })
        } else {
            let updatedNote = note
            updatedNote.isLiked = isLiked
            updatedNote.likesCount = likesCount
            updatedNote.comments = comments
            updatedNote.commentsCount = commentsCount
            savedNotes.append(updatedNote)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок, дата и кнопка сохранения
            HStack {
                Text(note.title)
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        if note.isScheduled {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.black)
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.black)
                        } else if note.isPrivate {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.black)
                            Text("Private")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                        Text(note.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    HStack(spacing: 8) {
                        if note.author == currentUsername {
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        saveButton
                    }
                }
            }
            
            // Автор
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.black)
                Text(note.author)
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
            
            // Контент
            Button(action: {
                if textHeight > 60 || note.attachments.count > 2 {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }) {
                Text(note.content + ((textHeight > 60 || note.attachments.count > 2) && !isExpanded ? "..." : ""))
                    .font(.body)
                    .foregroundColor(.black)
                    .lineLimit(isExpanded ? nil : 3)
                    .multilineTextAlignment(.leading)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.onAppear {
                                textHeight = geometry.size.height
                            }
                        }
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Вложения
            if !note.attachments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Вложения")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    ForEach(Array(note.attachments.enumerated()), id: \.element.id) { index, attachment in
                        if isExpanded || index < 2 {
                            AttachmentView(attachment: attachment)
                                .opacity(isExpanded ? 1 : (index == 1 && note.attachments.count > 2 ? 0.5 : 1))
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            // Хэштеги
            if !note.hashtags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(zip(note.hashtags, hashtagColors)), id: \.0) { hashtag, color in
                            Text(hashtag)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(color)
                                .foregroundColor(textColor(for: color))
                                .cornerRadius(15)
                        }
                    }
                }
            }
            
            // Нижняя часть с кнопками
            HStack(spacing: 16) {
                likeButton
                
                commentButton
                
                Spacer()
                
                shareButton
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(note.isPrivate ? Color.black : Color.gray, lineWidth: note.isPrivate ? 2 : 1)
        )
        .padding(.horizontal)
        .alert("Удалить заметку?", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                notesManager.deleteNote(note: note)
                if isSaved {
                    savedNotes.removeAll { $0.id == note.id }
                }
            }
        } message: {
            Text("Это действие нельзя отменить")
        }
    }
    
    private func shareNote() {
        let noteText = "\(note.title)\n\(note.content)"
        let activityVC = UIActivityViewController(activityItems: [noteText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    private var likeButton: some View
    {
        // Кнопка лайка
        Button(action: {
            withAnimation {
//                isLiked.toggle()
//                likesCount += isLiked ? 1 : -1
                // Если ещё не лайкнуто
                if (!isLiked)
                {
                    // Поставить лайк
                    isLiked = note.SetLike()
                    // Если не поставился -> алерт
                    showLikeAlert = !isLiked
                }
                else // если лайкнуто
                {
                    // убрать лайк
                    isLiked = !note.DelLike() // возращает true если лайк убран
                    // Если лайк остался -> алерт
                    showLikeAlert = isLiked
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .foregroundColor(isLiked ? .blue : .black)
                Text("\(likesCount)")
                    .foregroundColor(.black)
            }
        }
        .alert("Session expired", isPresented: $showLikeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Не удалось поставить/убрать лайк :(")
        }
    }
    
    private var saveButton: some View
    {
        Button(action: {
            withAnimation {
                toggleSaveNote()
                if (!isSaved)
                {
                    // сохранить
                    isSaved = note.SetFavourite()
                    note.isSaved = isSaved
                    // Если не поставился -> алерт
                    showSaveAlert = !isSaved
                }
                else // если сохранено
                {
                    // удалить
                    isSaved = !note.DelFavourite() // возращает true если удалили
                    note.isSaved = isSaved
                    // Если сохранение осталось -> алерт
                    showSaveAlert = isSaved
                }
//                notesManager.notes.removeAll(where: { $0.id == note.id })
//                notesManager.notes.append(notesManager.getNoteById(note.id)!)
            }
        }) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .foregroundColor(isSaved ? .yellow : .black)
        }
        .alert("Session expired", isPresented: $showLikeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Не удалось сохранить/удалить пост :(")
        }
    }
    
    private var commentButton: some View
    {
        // Кнопка комментариев
        Button(action: {
            // Действие для комментариев
            showComments = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left")
                    .foregroundColor(.black)
                Text("\(note.commentsCount)")
                    .foregroundColor(.black)
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(note: &note, notesManager: notesManager, currentUsername: currentUsername, savedNotes: $savedNotes)
        }
    }
    
    private var shareButton: some View
    {
        Button(action: {
            shareNote()
        }) {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.black)
        }
    }
}

struct CommentsView: View {
    @State var note: Note
    @Environment(\.dismiss) private var dismiss
    @State private var newComment = ""
    @ObservedObject var notesManager: NotesManager
    @State private var currentUsername: String
    @Binding var savedNotes: [Note]
    @State private var showSessionExpired = false
    
    private var currentComments: [Comment] {
        if let savedNote = savedNotes.first(where: { $0.id == note.id }) {
            return savedNote.comments
        }
        return note.comments
    }
    
    private var currentCommentsCount: Int {
        if let savedNote = savedNotes.first(where: { $0.id == note.id }) {
            return savedNote.commentsCount
        }
        return note.commentsCount
    }
    
    init(note: inout Note, notesManager: NotesManager, currentUsername: String, savedNotes: Binding<[Note]>) {
        self.note = note
        self.notesManager = notesManager
        self._currentUsername = State(initialValue: currentUsername)
        self._savedNotes = savedNotes
        self.note.comments = getComments(id: note.id) ?? []
        self.note.commentsCount = self.note.comments.count
    }
    
    private func updateSavedNote(with comment: Comment) {
        if let index = savedNotes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = savedNotes[index]
//            updatedNote.comments.insert(comment, at: 0)
            updatedNote.comments = getComments(id: note.id) ?? []
            updatedNote.commentsCount = updatedNote.comments.count
            
            savedNotes[index] = updatedNote
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if currentComments.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Text("Прокомментируй первый!")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(currentComments) { comment in
                                CommentView(comment: comment)
                            }
                        }
                        .padding()
                    }
                }
                
                HStack {
                    TextField("Добавить комментарий...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: {
                        if !newComment.isEmpty {
                            let comment = Comment(
                                id: 0,
//                                author: currentUsername,
                                author_id: UserDefaults.standard.string(forKey: "user_id") ?? "",
                                created_at: Date(),
                                updated_at: Date(),
                                post_id: note.id,
                                text: newComment
                            )
                            showSessionExpired = !notesManager.addComment(to: &note, comment: comment)
//                            if let index = $notesManager.notes.firstIndex(where: { $0.id == note.id }) {
//                                var updatedNote = $notesManager.notes[index]
//                                updatedNote.comments = getComments(id: updatedNote.id) ?? []
//                                updatedNote.commentsCount = updatedNote.comments.count
//                                notesManager.notes[index] = updatedNote
//                            }
                            if let index = notesManager.notes.firstIndex(where: { $0.id == note.id }) {
                                notesManager.notes[index].comments = getComments(id: note.id) ?? []
                                notesManager.notes[index].commentsCount = notesManager.notes[index].comments.count
                            }
//                            updateSavedNote(with: comment)
                            newComment = ""
                        }
                    }) {
                        Text("Отправить")
                            .foregroundColor(.blue)
                    }
                    .disabled(newComment.isEmpty)
                    .alert("Session expired", isPresented: $showSessionExpired) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Не удалось отправить комментарий :(")
                    }
                }
                .padding()
            }
            .navigationTitle("Комментарии (\(notesManager.formatCount(currentCommentsCount)))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CommentView: View {
    let comment: Comment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(getUsername(id: comment.author_id))
                    .font(.headline)
                Spacer()
                Text(comment.created_at, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(comment.text)
                .font(.body)
        }
        .padding()
//        .background(comment.isNew ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AttachmentView: View {
    let attachment: Attachment
    @State private var showPreview = false
    
    var body: some View {
        Button(action: {
            showPreview = true
        }) {
            HStack {
                Image(systemName: attachmentIcon(for: attachment.fileType))
                    .foregroundColor(.black)
                Text(attachment.fileName)
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(8)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
        .sheet(isPresented: $showPreview) {
            AttachmentPreviewView(attachment: attachment)
        }
    }
    
    private func attachmentIcon(for fileType: String) -> String {
        switch fileType.lowercased() {
        case "image/jpeg", "image/png", "image/gif":
            return "photo"
        case "audio/mpeg", "audio/wav":
            return "music.note"
        case "application/pdf":
            return "doc.text"
        default:
            return "doc"
        }
    }
}

struct AttachmentPreviewView: View {
    let attachment: Attachment
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if attachment.fileType.lowercased().contains("image") {
                    if let image = UIImage(data: attachment.fileData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                } else if attachment.fileType.lowercased().contains("audio") {
                    AudioPlayerView(data: attachment.fileData)
                } else {
                    Text("Предпросмотр недоступен")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle(attachment.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AudioPlayerView: View {
    let data: Data
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack {
            Button(action: {
                if isPlaying {
                    audioPlayer?.pause()
                } else {
                    if audioPlayer == nil {
                        do {
                            audioPlayer = try AVAudioPlayer(data: data)
                            audioPlayer?.prepareToPlay()
                        } catch {
                            print("Error creating audio player: \(error)")
                        }
                    }
                    audioPlayer?.play()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.black)
            }
        }
        .onDisappear {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }
}

#Preview {
    var note = Note(
        id: 0,
        author: "Макс Пупкин",
        date: Date(),
        title: "Конспекты по кмзи от Пупки Лупкиной",
        content: "Представляю вам свои гадкие конспекты по вышматы или не вышмату не знаб но не по кмзи точно",
        hashtags: ["#матан", "#крипта", "#бип"],
        isPrivate: false
//            likesCount: 1,
//            commentsCount: 0,
//            like_id: -1
    )
    NoteCard(
        note: note,
        savedNotes: .constant([]),
        notesManager: NotesManager(),
        currentUsername: "Макс Пупкин"
    )
}
