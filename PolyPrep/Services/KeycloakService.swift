import Foundation
import SwiftUI

class KeycloakService: ObservableObject {
    private let baseURL = "YOUR_KEYCLOAK_BASE_URL"
    private let realm = "YOUR_REALM"
    private let clientId = "YOUR_CLIENT_ID"
    private let redirectUri = "YOUR_REDIRECT_URI"
    
    @Published var isAuthenticated = false
    @Published var userInfo: KeycloakUserInfo?
    @Published var error: String?
    
    private var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "access_token") }
    }
    
    private var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "refresh_token") }
    }
    
    init() {
        if let token = accessToken {
            fetchUserInfo(token: token)
        }
    }
    
    func getLoginURL() -> URL? {
        let urlString = "\(baseURL)/realms/\(realm)/protocol/openid-connect/auth?" +
            "client_id=\(clientId)" +
            "&redirect_uri=\(redirectUri)" +
            "&response_type=code" +
            "&scope=openid profile email" +
            "&state=\(UUID().uuidString)"
        
        return URL(string: urlString)
    }
    
    func getRegisterURL() -> URL? {
        let urlString = "\(baseURL)/realms/\(realm)/protocol/openid-connect/registrations?" +
            "client_id=\(clientId)" +
            "&redirect_uri=\(redirectUri)" +
            "&response_type=code" +
            "&scope=openid profile email"
        
        return URL(string: urlString)
    }
    
    func handleCallback(url: URL) {
        guard let code = extractCode(from: url) else {
            self.error = "Failed to extract authorization code"
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
        let tokenURL = "\(baseURL)/realms/\(realm)/protocol/openid-connect/token"
        guard let url = URL(string: tokenURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=authorization_code" +
            "&client_id=\(clientId)" +
            "&code=\(code)" +
            "&redirect_uri=\(redirectUri)"
        
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
                return
            }
            
            guard let data = data else { return }
            
            do {
                let tokenResponse = try JSONDecoder().decode(KeycloakTokenResponse.self, from: data)
                DispatchQueue.main.async {
                    self.accessToken = tokenResponse.access_token
                    self.refreshToken = tokenResponse.refresh_token
                    self.isAuthenticated = true
                    self.fetchUserInfo(token: tokenResponse.access_token)
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    private func fetchUserInfo(token: String) {
        let userInfoURL = "\(baseURL)/realms/\(realm)/protocol/openid-connect/userinfo"
        guard let url = URL(string: userInfoURL) else { return }
        
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
            
            do {
                let userInfo = try JSONDecoder().decode(KeycloakUserInfo.self, from: data)
                DispatchQueue.main.async {
                    self.userInfo = userInfo
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                }
            }
        }.resume()
    }
    
    func logout() {
        accessToken = nil
        refreshToken = nil
        userInfo = nil
        isAuthenticated = false
    }
}
