import Foundation

struct AuthResponse: Codable {
    var access_token: String
    var refresh_token: String
//    let expires_in: Int
//    let token_type: String
}

struct UserInfo: Codable {
    let id: String
    let username: String
    let img_link: String
//    let email: String
//    let name: String
    // Добавьте другие поля, которые приходят с вашего бэкенда
}

struct AuthError: Codable {
    let error: String
    let message: String
}

