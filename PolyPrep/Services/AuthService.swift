import Foundation
import SwiftUI
import SafariServices
import WebKit
import AuthenticationServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = .green // Цвет кнопок
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

class AuthService: ObservableObject {
    @Published var isLoggedIn = false
    @Published var username: String?
    @Published var error: String?
    @Published var userInfo: UserInfo?
    
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "access_token") }
    }
    
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "refresh_token") }
    }
    
    init() {
        isLoggedIn = RefreshToken(refresh_token: self.refreshToken ?? "")
        if (isLoggedIn)
        {
            self.fetchUserInfo(token: self.accessToken ?? "")
        }
    }
    
    func RefreshToken(refresh_token: String) -> Bool
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.AuthEndpoints.refresh) else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let requestBody: [String: Any] = [
                "refresh_token": refreshToken ?? NSNull()
            ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        guard let (data, response) = HandleNetwork(request) else {
            return false
        }
        
        if (response.statusCode == 200)
        {
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                DispatchQueue.main.async {
                    self.accessToken = json?["access_token"] as? String ?? ""
                    self.refreshToken = json?["refresh_token"] as? String ?? ""
                    self.fetchUserInfo(token: self.accessToken!)
                }
            } catch {}
            return true
        }
        else if (response.statusCode == 405)
        {
            self.accessToken = ""
            self.refreshToken = ""
            return false
        }
        print("ERROR: ", String(data: data, encoding: .utf8) ?? "No data...")
        return false
    }
    
    func CheckAuth(with session: WebAuthenticationSession) async
    {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.AuthEndpoints.check) else { return }
        var request = URLRequest(url: url)
        let accessToken = UserDefaults.standard.string(forKey: "access_token")
        let refreshToken = UserDefaults.standard.string(forKey: "refresh_token")
        request.httpMethod = "POST"
        
        let requestBody: [String: Any] = [
                "refresh_token": refreshToken ?? NSNull(),
                "access_token": accessToken ?? NSNull(),
                "next_page": "",
            ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        do
        {
//            let (data, _) = try! await URLSession.shared.data(for: request)
            let (data, _) = HandleNetwork(request)!
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            if json?["redirect"] as? Bool == true
            {
                let redirectURL = json?["url"] as? String
                print("REDIRECT: " + redirectURL!)
                let urlWithToken = try await session.authenticate(
                    using: URL(string: redirectURL!)!,
                    callbackURLScheme: "yourapp"
                )
                var _: () = self.handleAuthCallback(url: urlWithToken)
            }
            else
            {
                self.fetchUserInfo(token: self.accessToken!)
            }
        } catch
        {
            print("something went wrong :(")
        }
        
    }
    
    func handleAuthCallback(url: URL) {
        guard let code = extractCode(from: url) else {
            self.error = "Не удалось получить код авторизации"
            return
        }
        
        exchangeCodeForToken(code: code)
    }
    
    private func extractCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return nil
        }
        return code
    }
    
    private func exchangeCodeForToken(code: String) {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.AuthEndpoints.callback + "?code=" + code + "&next_page=/user") else { return }
        print(url.absoluteString)
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                DispatchQueue.main.async {
                    self.accessToken = json?["access_token"] as? String ?? ""
                    self.refreshToken = json?["refresh_token"] as? String ?? ""
                    self.fetchUserInfo(token: self.accessToken!)
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    print(self.error)
                }
            }
        }.resume()
    }
    
    private func fetchUserInfo(token: String) {
        guard let url = URL(string: APIConstants.baseURL + APIConstants.AuthEndpoints.userInfo + "?id=" + (getUserIdFromToken(token) ?? "")) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
                return
            }
            
            guard let data = data else { return }
            print(String(data: data ?? Data(), encoding: .utf8) ?? "Нет данных")
            
            do {
                let userInfo = try JSONDecoder().decode(UserInfo.self, from: data)
                DispatchQueue.main.async {
                    self.userInfo = userInfo
                    self.username = userInfo.username
                    self.isLoggedIn = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func logout() {
        accessToken = ""
        refreshToken = ""
        userInfo = nil
        username = ""
        isLoggedIn = false
    }
    
    func login() async {

    }
    
    func register() {
        
    }
    
    func getUserIdFromToken(_ token: String) -> String? {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        
        return decodeJWTPart(parts[1])
    }

    private func decodeJWTPart(_ part: String) -> String? {
        // 1. Дополняем строку до длины, кратной 4
        var base64 = part
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        
        // 2. Декодируем Base64
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // 3. Извлекаем поле "sub"
        return json["sub"] as? String
    }
}
