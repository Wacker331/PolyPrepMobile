import Foundation

struct Comment: Identifiable, Equatable, Codable {
    let id: Int
//    let author: String
    let author_id: String
    let created_at: Date
    let updated_at: Date
    let post_id: Int
    let text: String
//    var isNew: Bool = false
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id &&
//        lhs.author == rhs.author &&
//        lhs.date == rhs.date &&
//        lhs.isNew == rhs.isNew &&
        lhs.text == rhs.text
    }
}

struct Note: Identifiable, Equatable {
    let id: Int
    let author: String
    let date: Date
    let title: String
    let content: String
    let hashtags: [String]
    var likesCount: Int
    var commentsCount: Int
    var isLiked: Bool = false
    var isSaved: Bool = false
    var like_id: Int
    
    init(id: Int, author: String, date: Date, title: String, content: String, hashtags: [String], isPrivate: Bool, isScheduled: Bool? = false, scheduledDate: Date? = nil /*, likesCount: Int, commentsCount: Int, isLiked: Bool, isSaved: Bool? = false, like_id: Int,comments: [Comment], attachments: [Attachment]*/) {
        self.id = id
        self.author = author
        self.date = date
        self.title = title
        self.content = content
        self.hashtags = hashtags
        self.isPrivate = isPrivate
        self.isScheduled = isScheduled ?? false
        self.scheduledDate = scheduledDate
        
        // from "/like" backend
        let likes = getLikes(id: id)
        self.likesCount = likes.count
        self.isLiked = false
        self.like_id = -1
        let UserId = UserDefaults.standard.string(forKey: "user_id") ?? ""
        for like in likes {
            if like["user_id"] as! String == UserId
            {
                self.isLiked = true
                self.like_id = like["id"] as! Int
            }
        }
        
        // from "/comment" backend
        let NetworkComments = getComments(id: id)
        self.comments = NetworkComments ?? []
        self.commentsCount = NetworkComments?.count ?? 0
        
        // from "/favourite" backend
//        self.isSaved = isSaved ?? false
        
        // from "/includes" backend
//        self.attachments = attachments
    }
    
    mutating func SetLike() {
        guard let url = URL(string: APIConstants.baseURL + "/like") else {
            fatalError("Invalid URL")
        }
        
        // 2. Создаем URLRequest
        var request = URLRequest(url: url)
        let accessToken = UserDefaults.standard.string(forKey: "access_token")

        // 3. Добавляем заголовки
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("YourApp/1.0", forHTTPHeaderField: "User-Agent")

        // 4. Настраиваем метод (GET по умолчанию)
        request.httpMethod = "POST" // Можно изменить на POST/PUT и т.д.
        let requestBody: [String: Any] = [
            "post_id": self.id
            ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                print("Failed to encode JSON")
                return
            }
        request.httpBody = jsonData
        let (data, _) = HandleNetwork(request)!
        
        var json: [String: Any] = [:]
        do { json = try (JSONSerialization.jsonObject(with: data) as? [String: Any])! }
        catch { return }
        self.like_id = json["like_id"] as? Int ?? -1
        likesCount = getLikes(id: id).count
//        URLSession.shared.dataTask(with: request){ data, response, error in
//        
//            guard let httpResponse = response as? HTTPURLResponse else {
//                    print( NSError(domain: "Invalid response", code: 0))
//                return
//                }
//            print("Status code:", httpResponse.statusCode)
//            print("Response:", String(data: data ?? Data(), encoding: .utf8) ?? "")
//            
//            let json = try! JSONSerialization.jsonObject(with: data!) as? [String: Any]
//            
//        }.resume()
        
    }
    
    mutating func DelLike() {
        guard let url = URL(string: APIConstants.baseURL + "/like" + "?id=" + String(self.like_id)) else {
            fatalError("Invalid URL")
        }
        
        // 2. Создаем URLRequest
        var request = URLRequest(url: url)
        let accessToken = UserDefaults.standard.string(forKey: "access_token")

        // 3. Добавляем заголовки
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("YourApp/1.0", forHTTPHeaderField: "User-Agent")

        // 4. Настраиваем метод (GET по умолчанию)
        request.httpMethod = "DELETE" // Можно изменить на POST/PUT и т.д.
        
        let (_, _) = HandleNetwork(request)!
        like_id = -1
        likesCount = getLikes(id: id).count
//        URLSession.shared.dataTask(with: request){ data, response, error in
//        
//            guard let httpResponse = response as? HTTPURLResponse else {
//                    print( NSError(domain: "Invalid response", code: 0))
//                return
//                }
//            print("Status code:", httpResponse.statusCode)
//            print("Response:", String(data: data ?? Data(), encoding: .utf8) ?? "")
//            
//        }.resume()
    }

    var isPrivate: Bool = false
    var isScheduled: Bool = false
    var scheduledDate: Date?
    var comments: [Comment] = []
    var attachments: [Attachment] = []
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.id == rhs.id &&
        lhs.author == rhs.author &&
        lhs.date == rhs.date &&
        lhs.title == rhs.title &&
        lhs.content == rhs.content &&
        lhs.hashtags == rhs.hashtags &&
        lhs.likesCount == rhs.likesCount &&
        lhs.commentsCount == rhs.commentsCount &&
        lhs.isLiked == rhs.isLiked &&
        lhs.isSaved == rhs.isSaved &&
        lhs.isPrivate == rhs.isPrivate &&
        lhs.isScheduled == rhs.isScheduled &&
        lhs.scheduledDate == rhs.scheduledDate &&
        lhs.comments == rhs.comments &&
        lhs.attachments == rhs.attachments
    }
}
