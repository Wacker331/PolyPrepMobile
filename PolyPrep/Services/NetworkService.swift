//
//  NetworkService.swift
//  PolyPrep
//
//  Created by Дмитрий Григорьев on 11.05.2025.
//

import Foundation
import UIKit

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

func HandleNetwork(_ url: URL) -> (Data?, HTTPURLResponse?)
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
