import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct NewNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var attachments: [Attachment] = []
    @State private var hashtags = ""
    @State private var isPrivate = false
    @State private var isScheduled = false
    @State private var scheduledDate = Date().addingTimeInterval(3600) // По умолчанию через час
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    var onNoteCreated: (Note) -> Void
    var currentUsername: String
    
    private let maxLength = 150
    
    private var isValidNote: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func togglePrivate() {
        if isScheduled {
            isScheduled = false
        }
        isPrivate.toggle()
    }
    
    private func toggleScheduled() {
        if isPrivate {
            isPrivate = false
        }
        isScheduled.toggle()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Заголовок
                    VStack(alignment: .leading) {
                        Text("Заголовок")
                            .font(.headline)
                            .foregroundColor(.black)
                        TextField("Введите заголовок", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)
                    
                    // Текст заметки
                    VStack(alignment: .leading) {
                        Text("Текст заметки")
                            .font(.headline)
                            .foregroundColor(.black)
                        TextEditor(text: $content)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)
                    
                    // Вложения
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Вложения")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        ForEach(attachments) { attachment in
                            HStack {
                                Image(systemName: attachmentIcon(for: attachment.fileType))
                                    .foregroundColor(.black)
                                Text(attachment.fileName)
                                    .foregroundColor(.black)
                                Spacer()
                                Button(action: {
                                    if let index = attachments.firstIndex(where: { $0.id == attachment.id }) {
                                        attachments.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                        }
                        
                        HStack {
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Label("Фото", systemImage: "photo")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                            
                            Button(action: {
                                showDocumentPicker = true
                            }) {
                                Label("Файл", systemImage: "doc")
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Хэштеги
                    VStack(alignment: .leading) {
                        Text("Хэштеги")
                            .font(.headline)
                            .foregroundColor(.black)
                        TextField("#матан #крипта #хочу_зачет_по_бип", text: $hashtags)
                            .onChange(of: hashtags) { newValue in
                                if newValue.count > maxLength {
                                    hashtags = String(newValue.prefix(maxLength))
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)
                    
                    Text("\(hashtags.count) / \(maxLength)")
                        .foregroundColor(hashtags.count == maxLength ? .red : .gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                    
                    // Дополнительно
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Дополнительно")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Toggle(isOn: Binding(
                            get: { isPrivate },
                            set: { _ in togglePrivate() }
                        )) {
                            Text("Сделать заметку приватной")
                                .foregroundColor(.black)
                        }
                        
                        Toggle(isOn: Binding(
                            get: { isScheduled },
                            set: { _ in toggleScheduled() }
                        )) {
                            Text("Отложенная публикация")
                                .foregroundColor(.black)
                        }
                        
                        if isScheduled {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Дата и время публикации")
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                DatePicker("", selection: $scheduledDate, in: Date()...)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(.vertical, 8)
                            }
                            .padding(.leading)
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut, value: isScheduled)
                    
                    // Последний шаг
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Последний шаг")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Button(action: {
                            if isValidNote {
                                createAndSaveNote()
                            } else {
                                alertMessage = "Заполните название и текст заметки"
                                showAlert = true
                            }
                        }) {
                            Text("Создать пост")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isValidNote ? Color.black : Color.gray)
                                .cornerRadius(8)
                        }
                        .disabled(!isValidNote)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .background(Color.white)
            }
            .background(Theme.background)
            .navigationTitle("Новая заметка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .alert("Внимание", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(attachments: $attachments, onImageSelected: nil)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(attachments: $attachments)
            }
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
    
    private func createAndSaveNote() {
        let hashtagsArray = hashtags
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }
            .map { word -> String in
                let trimmedWord = word.trimmingCharacters(in: .whitespaces)
                return trimmedWord.hasPrefix("#") ? trimmedWord : "#\(trimmedWord)"
            }
        
        let newNote = Note(
            author: currentUsername,
            date: Date(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            hashtags: hashtagsArray,
            likesCount: 0,
            commentsCount: 0,
            isPrivate: isPrivate || isScheduled, // Отложенные заметки всегда приватные
            isScheduled: isScheduled,
            scheduledDate: isScheduled ? scheduledDate : nil,
            attachments: attachments
        )
        onNoteCreated(newNote)
        dismiss()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var attachments: [Attachment]
    @Environment(\.dismiss) private var dismiss
    var onImageSelected: ((Data?) -> Void)?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = onImageSelected != nil ? 1 : 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            if let onImageSelected = parent.onImageSelected {
                if let result = results.first {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                        if let image = object as? UIImage,
                           let imageData = image.jpegData(compressionQuality: 0.8) {
                            DispatchQueue.main.async {
                                onImageSelected(imageData)
                            }
                        } else {
                            DispatchQueue.main.async {
                                onImageSelected(nil)
                            }
                        }
                    }
                } else {
                    onImageSelected(nil)
                }
                return
            }
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                        if let image = object as? UIImage,
                           let imageData = image.jpegData(compressionQuality: 0.8) {
                            let attachment = Attachment(
                                fileName: "image_\(Date().timeIntervalSince1970).jpg",
                                fileType: "image/jpeg",
                                fileData: imageData
                            )
                            DispatchQueue.main.async {
                                self?.parent.attachments.append(attachment)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var attachments: [Attachment]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .audio, .image])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.dismiss()
            
            for url in urls {
                do {
                    let data = try Data(contentsOf: url)
                    let attachment = Attachment(
                        fileName: url.lastPathComponent,
                        fileType: url.pathExtension,
                        fileData: data
                    )
                    DispatchQueue.main.async {
                        self.parent.attachments.append(attachment)
                    }
                } catch {
                    print("Error loading file: \(error)")
                }
            }
        }
    }
}
 
