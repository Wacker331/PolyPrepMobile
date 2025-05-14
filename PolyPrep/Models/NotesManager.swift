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
    
    private var timer: Timer?
    
    init() {
        startScheduledNotesTimer()
        notes.removeAll()
        fetchNotes()
        savedNotes = getFavourites()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startScheduledNotesTimer() {
        // Проверяем отложенные заметки каждую минуту
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkScheduledNotes()
        }
    }
    
    private func checkScheduledNotes() {
        let now = Date()
        var updatedNotes = notes
        
        for (index, note) in notes.enumerated() {
            if note.isScheduled,
               let scheduledDate = note.scheduledDate,
               scheduledDate <= now {
                let updatedNote = note
                updatedNote.isScheduled = false
                updatedNote.isPrivate = false
                updatedNote.scheduledDate = nil
                updatedNotes[index] = updatedNote
            }
        }
        
        if updatedNotes != notes {
            DispatchQueue.main.async { [weak self] in
                self?.notes = updatedNotes
            }
        }
    }
    
    func addNote(_ note: Note) {
        // Все заметки добавляются в начало списка
//        notes.insert(note, at: 0)
        if !notes.contains(where: { $0.id == note.id }) {
            notes.insert(note, at: 0)
        }
    }
    
    func updateFavourites()
    {
        savedNotes = getFavourites()
    }
    
    private func getFavourites() -> [Note]
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.favourite) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        guard let (data, response) = HandleNetwork(request) else {
            return []
        }
        if response.statusCode != 200
        { return [] }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            
            if let json = json {
                var favourites: [Note] = []
                for item in json {
                    
                    //                    let note = try Note(json: item)
                    if let note = getNoteById(item["post_id"] as! Int)
                    { favourites.append(note) }
                }
                return favourites
            }
            return []
        } catch { return [] }
        
    }
    
    func getUserNotes(username: String) -> [Note] {
        if (user_notes.isEmpty)
        {
            user_notes = fetchUserNotes()
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
    
    func fetchUserNotes() -> [Note]
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
        
        guard let (data, _) = HandleNetwork(request) else {
            return []
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
                            isPrivate: !(post["public"] as! Bool)
                        )
                     )
                }
                return Notes
            }
            
        } catch {
            print("🚨 JSON decoding error:", error.localizedDescription)
        }
        return []
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
                                isPrivate: !(post["public"] as! Bool)
                                //                            likesCount: getLikesCount(id: post["id"] as! Int),
                                //                            commentsCount: comments.count,
                                //                            like_id: -1,
                                //                            comments: comments
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
        guard let (data, _) = HandleNetwork(request) else {
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let posts = json?["posts"] as? [[String: Any]]
            {
                for post in posts {
//                    let comments = getComments(id: post["id"] as! Int) ?? []
                    addNote(
                        Note(
                            id: post["id"] as! Int,
                            author: getUsername(id: post["author_id"] as! String),
                            date: Date(timeIntervalSince1970: post["updated_at"] as! TimeInterval),
                            title: post["title"] as! String, content: post["text"] as! String,
                            hashtags: post["hashtages"] as! [String],
                            isPrivate: !(post["public"] as! Bool)
//                            likesCount: getLikesCount(id: post["id"] as! Int),
//                            commentsCount: comments.count,
//                            like_id: -1,
//                            comments: comments
                        )
                    )
                }
            }
            
        } catch {
            print("🚨 JSON decoding error:", error.localizedDescription)
        }
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
    }

    
    func toggleLike(for noteId: Int) {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            notes[index].isLiked.toggle()
            notes[index].likesCount += notes[index].isLiked ? 1 : -1
        }
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
    }
    
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
        
        note.comments = getComments(id: note.id) ?? []
        note.commentsCount = note.comments.count
        
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
        return NetworkAddComment(comment: comment, note: &note)
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
