import Foundation

enum APIConstants {
    static var baseURL = UserDefaults.standard.string(forKey: "BackEndURL") ?? "http://90.156.170.153:8081/api/v1";
    static var FrontEndURL = UserDefaults.standard.string(forKey: "FrontEndURL") ?? "http://90.156.170.153:3001";
    static var KeyCloakURL = UserDefaults.standard.string(forKey: "KeyCloakURL") ?? "http://90.156.170.153:8091";
    
    enum AuthEndpoints {
        static let login = "/auth/login"
        static let register = "/auth/register"
        static let userInfo = "/user"
        static let check = "/auth/mobile/check"
        static let logout = "/auth/logout"
        static let callback = "/auth/mobile/callback"
        static let refresh = "/auth/refresh"
    }
    
    enum PostEndpoints {
        static let post = "/post"
        static let like = "/like"
        static let comment = "/comment"
        static let search = "/post/search"
        static let random = "/post/random"
        static let includes = "/includes"
        static let favourite = "/favourite"
        static let user = "/user"
        static let user_posts = "/user/posts"
    }
    
    enum UserEndpoints {
        static let check_favourite = "/favourite/check"
        static let user = "/user"
        static let user_posts = "/user/posts"
        static let user_photo = "/user/photo"
    }
    
    enum SharedEndpoints
    {
        static let get_shared = "/post/shared"
        static let control_shared = "/shared"
    }
}

