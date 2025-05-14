//
//  File.swift
//  PolyPrep
//
//  Created by Дмитрий Григорьев on 14.05.2025.
//

import Foundation
import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var attachments: [Attachment] = []
    @State private var hashtags = ""
    @State private var isPrivate = false
    @State private var isScheduled = false
    @State private var scheduledDate = Date().addingTimeInterval(3600) // По умолчанию через час
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showImagePicker = false
    @State private var showDocumentPicker = false
    var onSearchButton: (String) -> Void
//    var currentUsername: String
    
    private let maxLength = 150
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Заголовок
                    VStack(alignment: .leading) {
                        Text("Поиск")
                            .font(.headline)
                            .foregroundColor(.black)
                        TextField("Ключевые слова", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal)
                    
                    searchButton
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                
            }
            .background(Theme.background)
            .navigationTitle("Поиск по сайту")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .alert("Внимание", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func attachmentIcon(for fileType: String) -> String {
        switch fileType.lowercased() {
        case "image/jpeg", "image/png", "image/gif":
            return "photo"
        case "audio/mpeg", "audio/wav":
            return "music.note"
        case "application/pdf":
            return "doc.text"
        default:
            return "doc"
        }
    }
    
    private var searchButton: some View
    {
        VStack(alignment: .center, spacing: 8) {
            //                        Text("Последний шаг")
            //                            .font(.headline)
            //                            .foregroundColor(.black)
            
            Button(action: {
                onSearchButton(title)
                dismiss()
            }) {
                Text("Найти")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!title.isEmpty ? Color.black : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(title.isEmpty)
        }
        .padding(.horizontal)
    }
}
