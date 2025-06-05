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

class Note: Identifiable, Equatable, ObservableObject {
    var id: Int
    var author: String
    let date: Date
    let title: String
    let content: String
    let hashtags: [String]
    var likesCount: Int
    @Published var commentsCount: Int = 0
    var isLiked: Bool = false
    var isSaved: Bool = false
    var like_id: Int
    
    init(id: Int, author: String, date: Date, title: String, content: String, hashtags: [String], isPrivate: Bool, isScheduled: Bool? = false, scheduledDate: Date? = nil, /*likesCount: Int, commentsCount: Int, isLiked: Bool, isSaved: Bool? = false, like_id: Int,comments: [Comment],*/ attachments: [Attachment]? = []) {
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
//        let NetworkComments = getComments(id: id)
        getComments(id: id) {   newComments in
            self.comments = newComments
            self.commentsCount = newComments.count
        }
//        self.commentsCount = self.comments.count
//        self.comments = NetworkComments ?? []
//        self.commentsCount = NetworkComments?.count ?? 0
        
        // from "/favourite" backend
        self.isSaved = CheckSaved(id: id)
        
        // from "/includes" backend
        self.attachments = attachments ?? []
        
    }
    
    private func CheckSaved (id: Int) -> Bool
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.UserEndpoints.check_favourite + "?id=" + String(id)) else {
            fatalError("Invalid URL")
        }
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let (_, response) = HandleNetwork(request)!
        
        return response.statusCode == 200
    }
    
    func SetLike() -> Bool {
        guard let url = URL(string: APIConstants.baseURL + "/like") else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")

        request.httpMethod = "POST"
        let requestBody: [String: Any] = [
            "post_id": self.id
            ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to encode JSON")
            return false
        }
        request.httpBody = jsonData
        let (data, response) = HandleNetwork(request)!
        
        var json: [String: Any] = [:]
        do { json = try (JSONSerialization.jsonObject(with: data) as? [String: Any])! }
        catch { return false }
        self.like_id = json["like_id"] as? Int ?? -1
        likesCount = getLikes(id: id).count
        
        if response.statusCode == 200
        {
            return true
        }
        return false
    }
    
    func DelLike() -> Bool {
        guard let url = URL(string: APIConstants.baseURL + "/like" + "?id=" + String(self.like_id)) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")

        request.httpMethod = "DELETE"
        
        let (_, response) = HandleNetwork(request)!
        like_id = -1
        likesCount = getLikes(id: id).count
        
        if response.statusCode == 200
        {
            return true
        }
        return false
    }
    
    func SetFavourite() -> Bool
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.favourite) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let requestBody: [String: Any] = [
            "post_id": self.id
            ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Failed to encode JSON")
            return false
        }
        request.httpBody = jsonData
        let (data, response) = HandleNetwork(request)!
        
        isSaved = response.statusCode == 200
        
        if response.statusCode == 200
        {
            return true
        }
        return false
    }
    
    func DelFavourite() -> Bool
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.favourite + "?id=" + String(self.id)) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        var accessToken = UserDefaults.standard.string(forKey: "access_token")
        CheckTokenValidity(&accessToken!)
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")

        request.httpMethod = "DELETE"
        
        let (_, response) = HandleNetwork(request)!
        
        isSaved = !(response.statusCode == 200)
        
        if response.statusCode == 200
        {
            return true
        }
        return false
    }

    var isPrivate: Bool = false
    var isScheduled: Bool = false
    var scheduledDate: Date?
    @Published var comments: [Comment] = []
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
