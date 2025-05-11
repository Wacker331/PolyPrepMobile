import Foundation

class UserProfile: ObservableObject {
    @Published var avatarImage: Data?
    @Published var username: String
    
    init(username: String) {
        self.username = username
        loadAvatar()
    }
    
    private func loadAvatar() {
        if let data = UserDefaults.standard.data(forKey: "userAvatar_\(username)") {
            self.avatarImage = data
        }
    }
    
    func saveAvatar(_ imageData: Data) {
        self.avatarImage = imageData
        UserDefaults.standard.set(imageData, forKey: "userAvatar_\(username)")
    }
    
    func deleteAvatar() {
        self.avatarImage = nil
        UserDefaults.standard.removeObject(forKey: "userAvatar_\(username)")
    }
} 