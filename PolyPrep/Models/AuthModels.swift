import Foundation

struct AuthResponse: Codable {
    var access_token: String
    var refresh_token: String
//    let expires_in: Int
//    let token_type: String
}

class UserInfo: Codable {
    let id: String
    let username: String
    var img_link: String
//    let email: String
//    let name: String
    // Добавьте другие поля, которые приходят с вашего бэкенда
    init()
    {
        id = ""
        username = ""
        img_link = ""
    }
}

struct AuthError: Codable {
    let error: String
    let message: String
}

