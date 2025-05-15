//
//  NetworkService.swift
//  PolyPrep
//
//  Created by Дмитрий Григорьев on 11.05.2025.
//

import Foundation
import UIKit

var NetworkAuthService: AuthService? = nil

func HandleNetwork(_ request: URLRequest) -> (Data, HTTPURLResponse)?
{
    var tmp_data: Data?
    var tmp_response: HTTPURLResponse?
    var error_flag = false
    URLSession.shared.dataTask(with: request){ data, response, error in
        print("Network request: ", request.url?.absoluteString ?? "")
        guard let httpResponse = response as? HTTPURLResponse else {
            print( NSError(domain: "Invalid response", code: 0))
            error_flag = true
            return
        }
        print("Status code:", httpResponse.statusCode)
        print("Response:", String(data: data ?? Data(), encoding: .utf8) ?? "")
        if (httpResponse.statusCode != 200)
        {
//            showAlert(title: "Error " + String(httpResponse.statusCode), message: String(data: data ?? Data(), encoding: .utf8) ?? "")
        }
        tmp_data = data ?? Data()
        tmp_response = httpResponse
    }.resume()
    while (tmp_data == nil && tmp_response == nil && !error_flag) {}
    if error_flag
    {
        return nil
    }
    return (tmp_data ?? Data(), tmp_response ?? HTTPURLResponse())
}

func HandleNetwork(_ url: URL) -> (Data?, HTTPURLResponse?)?
{
    var tmp_data: Data?
    var tmp_response: HTTPURLResponse?
    URLSession.shared.dataTask(with: url){ data, response, error in
        print("Network request: ", url.absoluteString)
        guard let httpResponse = response as? HTTPURLResponse else {
            print( NSError(domain: "Invalid response", code: 0))
            return
        }
        print("Status code:", httpResponse.statusCode)
        print("Response:", String(data: data ?? Data(), encoding: .utf8) ?? "")
        if (httpResponse.statusCode != 200)
        {
//            showAlert(title: "Error " + String(httpResponse.statusCode), message: String(data: data ?? Data(), encoding: .utf8) ?? "")
        }
        tmp_data = data
        tmp_response = httpResponse
    }.resume()
    while (tmp_data == nil && tmp_response == nil) {}
    return (tmp_data ?? Data(), tmp_response ?? HTTPURLResponse())
}

func showAlert(title: String, message: String) {
    // Создаем контроллер
    let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert
    )
    
    // Добавляем кнопку
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    
    // Показываем alert
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
        return
    }
    
    rootViewController.present(alert, animated: true)
}

func getLikes(id: Int) -> [[String: Any]] {
    guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.like + "?id=" + String(id)) else {
        fatalError("Invalid URL")
    }
    
    // 2. Создаем URLRequest
    var request = URLRequest(url: url)
    
    // 3. Добавляем заголовки
    
    // 4. Настраиваем метод (GET по умолчанию)
    request.httpMethod = "GET" // Можно изменить на POST/PUT и т.д.
    
    //        let (data, _) = try! await URLSession.shared.data(for: request)
    guard let (data, _) = HandleNetwork(request) else { return [] }
    
    do {
        // 1. Декодируем JSON в словарь
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // 2. Получаем значение по ключу
        if let count = json?["likes"] as? [[String: Any]] {
            print("Likes: ", count)
            return count
        }
        else
        {
            print("Can't get likes...")}
    } catch {
        print("🚨 JSON decoding error:", error.localizedDescription)
    }
    return []
}

func getComments(id: Int) -> [Comment]? {
    guard let url = URL(string: APIConstants.baseURL + APIConstants.PostEndpoints.comment + "?id=" + String(id)) else {
        fatalError("Invalid URL")
    }
    
    // 2. Создаем URLRequest
    var request = URLRequest(url: url)
    
    // 3. Добавляем заголовки
    
    // 4. Настраиваем метод (GET по умолчанию)
    request.httpMethod = "GET" // Можно изменить на POST/PUT и т.д.
    
    //        let (data, _) = try! await URLSession.shared.data(for: request)
    guard let (data, _) = HandleNetwork(request) else { return nil}
    
    do {
        // 1. Декодируем JSON в словарь
//        let jsonData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let comments = try decoder.decode([Comment].self, from: data)
        print("COMMENTS: ", comments)
        return comments
////        // 2. Получаем значение по ключу
//        if let count = json?.count as? Int {
//            print("Comments", count)
////            return count
//        }
//        else
//        { print("Can't get comments...") }
    } catch {
        print("🚨 JSON decoding error:", error.localizedDescription)
    }
    return nil
}

func getUsername(id: String) -> String {
    guard let url = URL(string: APIConstants.baseURL + APIConstants.UserEndpoints.user + "?id=" + id) else {
        fatalError("Invalid URL")
    }
    
    // 2. Создаем URLRequest
    var request = URLRequest(url: url)
    let accessToken = UserDefaults.standard.string(forKey: "access_token")

    // 3. Добавляем заголовки
    request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
//    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//    request.setValue("YourApp/1.0", forHTTPHeaderField: "User-Agent")

    // 4. Настраиваем метод (GET по умолчанию)
    request.httpMethod = "GET" // Можно изменить на POST/PUT и т.д.
    
//        let (data, _) = try! await URLSession.shared.data(for: request)
    guard let (data, _) = HandleNetwork(request) else { return ""}
        
        do {
                // 1. Декодируем JSON в словарь
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                // 2. Получаем значение по ключу
                if let username = json?["username"] as? String {
                    return username
                }
                
            } catch {
                print("🚨 JSON decoding error:", error.localizedDescription)
            }
    
    return "Неизвестный пользователь"
}

func CheckTokenValidity(_ token: inout String)
{
    if let ExpTime = NetworkAuthService?.getExpTimeFromToken(token)
    {
        if ((ExpTime) > Date())
        {
            return
        }
    }
    _ = NetworkAuthService!.RefreshToken(refresh_token: NetworkAuthService?.refreshToken ?? "")
    token = NetworkAuthService!.accessToken ?? ""
}
