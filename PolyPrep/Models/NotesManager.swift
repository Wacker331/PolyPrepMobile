import SwiftUI

class NotesManager: ObservableObject {
    @Published var notes: [Note] = [
        // Note(
        //     author: "Макс Пупкин",
        //     date: Date(),
        //     title: "Конспекты по кмзи от Пупки Лупкиной",
        //     content: "Представляю вам свои гадкие конспекты по вышматы или не вышмату не знаб но не по кмзи точно. Это очень длинный текст, который нужно сократить и показать троеточие в конце. Продолжение текста, которое будет скрыто до нажатия на троеточие.",
        //     hashtags: ["#матан", "#крипта", "#бип", "#программирование"],
        //     likesCount: 1,
        //     commentsCount: 0,
        //     comments: []
        // ),
        // Note(
        //     author: "Макс Пупкин",
        //     date: Date().addingTimeInterval(-86400),
        //     title: "Еще один конспект",
        //     content: "Другой интересный конспект по разным предметам",
        //     hashtags: ["#физика", "#математика", "#информатика"],
        //     likesCount: 5,
        //     commentsCount: 2,
        //     comments: [
        //         Comment(author: "Анна Сидорова", date: Date().addingTimeInterval(-10800), text: "Очень полезно!"),
        //         Comment(author: "Сергей Сергеев", date: Date().addingTimeInterval(-14400), text: "Спасибо!")
        //     ]
        // )
    ]
    
    @Published var savedNotes: [Note] = []
    
    @Published var user_notes: [Note] = []
    
    @StateObject var watchConnector = WatchConnector()
    
//    private var timer: Timer?
    
    init() {
//        startScheduledNotesTimer()
        notes.removeAll()
        fetchNotes()
        getFavourites() { favourites in
            self.savedNotes = favourites
        }
        getUserNotes(username: "")
        watchConnector.sendNotesToWatch(notes: savedNotes)
    }
    
    deinit {
//        timer?.invalidate()
    }
    
    private var notesDictionary: [Int: Note] = [:]
    func updateNote(_ updatedNote: Note) {
        if let index = notes.firstIndex(where: { $0.id == updatedNote.id }) {
            notes[index] = updatedNote
        }
        
        if let savIndex = savedNotes.firstIndex(where: { $0.id == updatedNote.id }) {
            if updatedNote.isSaved {
                savedNotes[savIndex] = updatedNote // Обновляем
            } else {
                savedNotes.remove(at: savIndex) // Удаляем если сняли из избранного
            }
        } else if updatedNote.isSaved {
            savedNotes.append(updatedNote) // Добавляем если новый избранный
        }
        
        if let userIndex = user_notes.firstIndex(where: { $0.id == updatedNote.id }) {
            user_notes[userIndex] = updatedNote // Обновляем
        }
        
        objectWillChange.send()
    }
    
    func addNote(_ note: Note) {
        // Все заметки добавляются в начало списка
//        notes.insert(note, at: 0)
        if !notes.contains(where: { $0.id == note.id }) {
//            notes.insert(note, at: 0)
            notes.append(note)
        }
    }
    
    func updateFavourites()
    {
        getFavourites() { favourites in
            self.savedNotes = favourites
        }
        watchConnector.sendNotesToWatch(notes: savedNotes)
    }
    
    private func getFavourites(completion: @escaping ([Note]) -> Void)
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.favourite) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
//        var result: [Note] = []
        
        DispatchQueue.global(qos: .background).async {
            guard let (data, response) = HandleNetwork(request) else {
                return
            }
            if response.statusCode != 200
            { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                
                if let json = json {
                    var favourites: [Note] = []
                    for item in json {
                        
                        //                    let note = try Note(json: item)
                        if let note = self.getNoteById(item["post_id"] as! Int)
                        {
                            note.attachments = self.fetchIncludes(id: note.id)
                            favourites.append(note)
                        }
                    }
                    DispatchQueue.main.async {
                        completion(favourites)
                    }
//                    return favourites
                }
                return
            } catch { return }
        }
        return
    }
    
    func getUserNotes(username: String) -> [Note] {
        if (user_notes.isEmpty)
        {
            fetchUserNotes() { userNotes in
                self.user_notes = userNotes
            }
        }
        return user_notes
        //        notes.filter { $0.author == username }
    }
    
    func getNoteById(_ id: Int) -> Note?
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.post + "?id=" + String(id)) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        guard let (data, response) = HandleNetwork(request) else {
            return nil
        }
        if (response.statusCode != 200)
        { return nil }
        
        do {
            
            if let post = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                return Note(
                    id: post["id"] as! Int,
                    author: getUsername(id: post["author_id"] as! String),
                    date: Date(timeIntervalSince1970: post["updated_at"] as! TimeInterval),
                    title: post["title"] as! String, content: post["text"] as! String,
                    hashtags: post["hashtages"] as! [String],
                    isPrivate: !(post["public"] as! Bool)
                )
            }
        } catch {return nil}
        return nil
    }
    
    func fetchUserNotes(completion: @escaping ([Note]) -> Void)
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.user_posts) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        var Notes = [Note]()
        
        // 3. Добавляем заголовки
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        DispatchQueue.global(qos: .background).async {
            guard let (data, _) = HandleNetwork(request) else {
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                
                if let posts = json
                {
                    for post in posts {
                        //                    let comments = getComments(id: post["id"] as! Int) ?? []
                        Notes.append(
                            Note(
                                id: post["id"] as! Int,
                                author: getUsername(id: post["author_id"] as! String),
                                date: Date(timeIntervalSince1970: post["updated_at"] as! TimeInterval),
                                title: post["title"] as! String, content: post["text"] as! String,
                                hashtags: post["hashtages"] as! [String],
                                isPrivate: !(post["public"] as! Bool),
                                attachments: self.fetchIncludes(id: post["id"] as! Int)
                            )
                        )
                    }
                    DispatchQueue.main.async {
                        completion(Notes)
                    }
                    //                return Notes
                }
                
            } catch {
                print("🚨 JSON decoding error:", error.localizedDescription)
            }
        }
        return
    }
    
    func searchNotes(_ searchText: String)
    {
        notes.removeAll()
        
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.search + "?text=" + searchText + "&from=0&to=60") else {
            fatalError("Invalid URL")
        }
        
        guard let (data, _) = HandleNetwork(url) else {
            return
        }
        
        if let data = data
        {
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let posts = json?["result"] as? [[String: Any]]
                {
                    for post in posts {
                        
                        addNote(
                            Note(
                                id: post["id"] as! Int,
                                author: getUsername(id: post["author_id"] as! String),
                                date: Date(timeIntervalSince1970: post["updated_at"] as! TimeInterval),
                                title: post["title"] as! String, content: post["text"] as! String,
                                hashtags: post["hashtages"] as! [String],
                                isPrivate: !(post["public"] as! Bool),
                                //                            likesCount: getLikesCount(id: post["id"] as! Int),
                                //                            commentsCount: comments.count,
                                //                            like_id: -1,
                                //                            comments: comments
                                attachments: fetchIncludes(id: post["id"] as! Int)
                            )
                        )
                    }
                }
                
            } catch {
                print("🚨 JSON decoding error:", error.localizedDescription)
            }
        }
    }
    
    func fetchNotes()
    {
//        notes.removeAll()
        guard let url = URL(string: APIConstants.baseURL + "/post/random" + "?count=10") else {
            fatalError("Invalid URL")
        }
        
        // 2. Создаем URLRequest
        var request = URLRequest(url: url)
        
        // 3. Добавляем заголовки
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("YourApp/1.0", forHTTPHeaderField: "User-Agent")
        request.httpMethod = "GET"
        
        //        let (data, _) = try! await URLSession.shared.data(for: request)
        DispatchQueue.global(qos: .background).async {
            
            guard let (data, _) = HandleNetwork(request) else {
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let posts = json?["posts"] as? [[String: Any]]
                {
                    for post in posts {
                        //                    let comments = getComments(id: post["id"] as! Int) ?? []
                        self.addNote(
                            Note(
                                id: post["id"] as! Int,
                                author: getUsername(id: post["author_id"] as! String),
                                date: Date(timeIntervalSince1970: post["updated_at"] as! TimeInterval),
                                title: post["title"] as! String,
                                content: post["text"] as! String,
                                hashtags: post["hashtages"] as! [String],
                                isPrivate: !(post["public"] as! Bool),
                                //                            likesCount: getLikesCount(id: post["id"] as! Int),
                                //                            commentsCount: comments.count,
                                //                            like_id: -1,
                                //                            comments: comments
                                attachments: self.fetchIncludes(id: post["id"] as! Int)
                            )
                        )
                    }
                }
                
            } catch {
                print("🚨 JSON decoding error:", error.localizedDescription)
            }
        }
    }
    
    func fetchIncludes(id: Int) -> [Attachment]
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.includes +
                            "?id=" + String(id)) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        guard let (data, _) = HandleNetwork(request) else {
            return []
        }
        var result = [Attachment]()
        do {
            if let attach = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            {
                for info in attach {
//                    let FileData = LoadInclude(info["link"] as! String) ?? Data()
                    let tmp_attach = Attachment(id: info["id"] as! Int, filename: info["filename"] as! String,
                                                filelink: info["link"] as! String, filedata: Data())
                    result.append(tmp_attach)
                }
            }
            
        } catch {
            print("🚨 JSON decoding error:", error.localizedDescription)
        }
        return result
    }
    
    func UploadNote(Note: inout Note) {
        guard let url = URL(string: APIConstants.baseURL + "/post") else {
            fatalError("Invalid URL")
        }
        
        // 2. Создаем URLRequest
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        // 3. Добавляем заголовки
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("YourApp/1.0", forHTTPHeaderField: "User-Agent")

        // 4. Настраиваем метод (GET по умолчанию)
        request.httpMethod = "POST" // Можно изменить на POST/PUT и т.д.
        let requestBody: [String: Any] = [
                "title": Note.title,
                "text": Note.content,
                "public": !(Note.isPrivate),
                "hashtages": Note.hashtags,
                "scheduled_at": Note.scheduledDate ?? NSNull() // эквивалент null в JSON
            ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                print("Failed to encode JSON")
                return
            }
        request.httpBody = jsonData
        
        let (data, _) = HandleNetwork(request)!
        
        do {
            let post = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            Note.id = post?["id"] as! Int
//            Note.author = getUsername(id: post?["author_id"] as! String)
        } catch {}
        print("ATTACHMENTS!!!")
        for attachment in Note.attachments {
            UploadAttachment(attachment: attachment, note: Note)
        }
    }

    func UploadAttachment(attachment: Attachment, note: Note)
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.includes +
                            "?filename=" + attachment.fileName + "&post_id=" + String(note.id))
        else {
            fatalError("Invalid URL")
        }
        print("FILE: " + attachment.fileName)
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = NSMutableData()
        
        // Добавляем изображение
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: multipart/form-data\r\n\r\n".data(using: .utf8)!)
        httpBody.append(attachment.fileData)
        httpBody.append("\r\n".data(using: .utf8)!)
        
        // Завершаем тело запроса
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = httpBody as Data
        
//        var isUploading = true
//        var uploadProgress: Double = 0
        var errorMessage: String?
        
//        let session = URLSession(configuration: .default, delegate: UploadTaskDelegate(progress: $uploadProgress), delegateQueue: nil)
                
        URLSession.shared.dataTask(with: request) { data, response, error in
                    DispatchQueue.main.async {
//                        isUploading = false
                        
                        if let error = error {
                            errorMessage = error.localizedDescription
                            return
                        }
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            errorMessage = "Неверный ответ сервера"
                            return
                        }
                        
                        if (200...299).contains(httpResponse.statusCode) {
                            print("Файл успешно загружен!")
                            errorMessage = nil
                        } else {
                            errorMessage = "Ошибка сервера: \(httpResponse.statusCode)"
                            print(errorMessage!)
                        }
                        
                        if let data = data, let responseString = String(data: data, encoding: .utf8) {
                            print("Ответ сервера:", responseString)
                        }
                    }
                }.resume()
    }
    
    func toggleLike(for noteId: Int) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].isLiked.toggle()
            notes[index].likesCount += notes[index].isLiked ? 1 : -1
        }
    }
    
//    func updateNote(_ note: Note) {
//        if let index = notes.firstIndex(where: { $0.id == note.id }) {
//            notes[index] = note
//        }
//    }
    
    func updateNoteLikes(noteId: Int, isLiked: Bool, likesCount: Int) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].isLiked = isLiked
            notes[index].likesCount = likesCount
        }
    }
    
    func NetworkAddComment(comment: Comment, note: inout Note) -> Bool
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.comment) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let requestBody: [String: Any] = [
            "text": comment.text,
            "post_id": note.id
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to encode JSON")
            return false
        }
        request.httpBody = jsonData
        
        let (_, response) = HandleNetwork(request)!
        
        if response.statusCode == 200
        {
            return true
        }
        return false
    }
    
    func addComment(to note: inout Note, comment: Comment) -> Bool {
//        if let index = notes.firstIndex(where: { $0.id == noteId }) {
//            var updatedNote = notes[index]
//            updatedNote.comments.insert(comment, at: 0)
//            updatedNote.commentsCount += 1
//            notes[index] = updatedNote
//        }
        let result = NetworkAddComment(comment: comment, note: &note)
        return result
    }
    
    func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            let kCount = Double(count) / 1000.0
            return String(format: "%.1fK", kCount)
        }
        return "\(count)"
    }
    
    private func NetworkDelete(_ note: Note)
    {
        guard let url = URL(string: APIConstants.baseURL + "/post?id=" + String(note.id)) else {
            fatalError("Invalid URL")
        }
        
        print("Network delete post: ", url.absoluteString)
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        
//        URLSession.shared.dataTask(with: request){ data, response, error in
//            
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print( NSError(domain: "Invalid response", code: 0))
//                return
//            }
//            print("Status code:", httpResponse.statusCode)
//            print("Response:", String(data: data ?? Data(), encoding: .utf8) ?? "")
//        }.resume()
        let (_, _) = HandleNetwork(request)!
    }
    
    func deleteNote(note: Note) {
        NetworkDelete(note)
        notes.removeAll { $0.id == note.id }
        
    }
    
    func getScheduledNotes(username: String) -> [Note] {
        notes.filter { $0.author == username && $0.isScheduled }
    }
    
    func getActiveNotes(username: String) -> [Note] {
        notes.filter { $0.author == username && !$0.isScheduled }
    }
}
