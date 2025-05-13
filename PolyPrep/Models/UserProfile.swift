import Foundation
import SwiftUI

class UserProfile: ObservableObject {
    @Published var avatarImage: Data?
    @Published var username: String
    @Published var userInfo: UserInfo
    
    @State private var uploadProgress: Double = 0
    @State private var uploadError: String?
    @State private var isUploading = false
    
    init(userInfo: UserInfo) {
        self.userInfo = userInfo
        self.username = getUsername(id: userInfo.id)
        if userInfo.img_link != ""
        {
//            UserDefaults.standard.set(userInfo.img_link, forKey: "userAvatar_\(username)")
            if avatarImage == nil
            {
                loadAvatar(userInfo.img_link)
            }
        }
    }
    
    private func NetworkLoadAvatar(_ urlString: String) -> Data?
    {
        guard let url = URL(string: urlString) else {
            fatalError("Invalid URL")
        }
        let (data, _) = HandleNetwork(url)
        
        return data
    }
    
    func loadAvatar(_ urlString: String) {
            if (urlString != "")
            {
                self.avatarImage = NetworkLoadAvatar(urlString)
                self.userInfo.img_link = urlString
//                UserDefaults.standard.set(urlString, forKey: "userAvatar_\(username)")
            }
//        else
//        {
//            self.avatarImage = NetworkLoadAvatar(urlString)
//            UserDefaults.standard.set(self.avatarImage, forKey: "userAvatar_\(username)")
//        }
//        self.avatarImage = NetworkLoadAvatar(urlString)
    }
    
    private func NetworkUploadAvatar(_ imageData: Data) {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.UserEndpoints.user_photo) else {
            fatalError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        let accessToken = UserDefaults.standard.string(forKey: "access_token")
        request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = NSMutableData()
        
        // Добавляем изображение
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        httpBody.append(imageData)
        httpBody.append("\r\n".data(using: .utf8)!)
        
        // Завершаем тело запроса
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = httpBody as Data
        isUploading = true
        uploadProgress = 0
        
        let session = URLSession(configuration: .default, delegate: UploadProgressDelegate(progress: $uploadProgress), delegateQueue: nil)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { [self] in
                isUploading = false
                
                if let error = error {
                    uploadError = error.localizedDescription
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    uploadError = "Неверный ответ сервера"
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    print("Фото успешно загружено!")
                    uploadError = nil
                } else {
                    uploadError = "Ошибка сервера: \(httpResponse.statusCode)"
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data ?? Data()) as? [String: Any]
                    if let link = json?["img_link"] as? String
                    {
                        userInfo.img_link = link
                    }
                } catch {}
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Ответ сервера:", responseString)
                }
            }
        }.resume()
    }
    
    func saveAvatar(_ imageData: Data) {
        NetworkUploadAvatar(imageData)
        
        self.avatarImage = imageData
        
//        UserDefaults.standard.set(userInfo.img_link, forKey: "userAvatar_\(username)")
    }
    
    func deleteAvatar() {
//        self.avatarImage = nil
//        UserDefaults.standard.removeObject(forKey: "userAvatar_\(username)")
    }
    
    func updateAvatar()
    {
        if self.avatarImage == nil && self.userInfo.img_link != ""
        {
            loadAvatar(self.userInfo.img_link)
        }
    }
}

// Для отслеживания прогресса загрузки
class UploadProgressDelegate: NSObject, URLSessionTaskDelegate {
    @Binding var progress: Double
    
    init(progress: Binding<Double>) {
        _progress = progress
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        DispatchQueue.main.async {
            self.progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        }
    }
}
