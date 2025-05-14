//
//  ContentView.swift
//  PolyPrep
//
//  Created by boss on 25.03.2025.
//

import SwiftUI
import AuthenticationServices

// Тестовые данные
//private var allNotes = [
//    Note(
//        author: "Макс Пупкин",
//        date: Date(),
//        title: "Конспекты по кмзи от Пупки Лупкиной",
//        content: "11111111Представляю вам свои гадкие конспекты по вышматы или не вышмату не знаб но не по кмзи точно. Это очень длинный текст, который нужно сократить и показать троеточие в конце. Продолжение текста, которое будет скрыто до нажатия на троеточие.",
//        hashtags: ["#матан", "#крипта", "#бип", "#программирование"],
//        likesCount: 1,
//        commentsCount: 0
//    ),
//    Note(
//        author: "Макс Пупкин",
//        date: Date().addingTimeInterval(-86400),
//        title: "Еще один конспект",
//        content: "Другой интересный конспект по разным предметам",
//        likesCount: 5,
//        commentsCount: 2
//    )
//]

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var notesManager = NotesManager()
//    @State private var savedNotes: [Note] = []
    @State private var selectedTab = 0
    @State private var showNewNote = false
    @State private var showSearch = false
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    
    init()
    {
        NetworkAuthService = authService
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Основной контент
            TabView(selection: $selectedTab) {
                // Browser Tab
                NavigationView {
                    ZStack {
                        Theme.background.edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 0) {
                            // Список заметок
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    //                                    ForEach(Array(notesManager.notes.enumerated()), id: \.element.id) { index, _ in
                                    //                                        NoteCard(note: &notesManager.notes[index],
                                    //                                                 savedNotes: $savedNotes,
                                    //                                                 notesManager: notesManager,
                                    //                                                 currentUsername: authService.username ?? "Неизвестный пользователь").contentShape(Rectangle())
                                    //                                    }
                                    ForEach(notesManager.notes) { note in
                                        NoteCard(note: note, savedNotes: $notesManager.savedNotes, notesManager: notesManager, currentUsername: authService.username ?? "Неизвестный пользователь")
                                            .contentShape(Rectangle())
                                    }
                                }
                                .padding(.top, 62)
                                .padding(.bottom, 16)
                            }
                            .scrollDismissesKeyboard(.immediately)
                            
                            BottomButtons
                        }
                    }
                }
                .sheet(isPresented: $showNewNote) {
                    NewNoteView(onNoteCreated: { newNote in
                        var mutableNote = newNote
                        notesManager.UploadNote(Note: &mutableNote)
                        notesManager.addNote(mutableNote)
                    }, currentUsername: authService.username ?? "Неизвестный пользователь")
                }
                .sheet(isPresented: $showSearch)
                {
                    SearchView(onSearchButton: {searchLine in
                        notesManager.searchNotes(searchLine)
                    })
                }
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("Поиск")
                }
                .tag(0)
                
                BookmarksTab
                
                ProfileTab
            }
            .accentColor(Theme.accent)
            
            // Верхняя черная полоска с названием
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Theme.header)
                        .frame(height: 60)
                        .ignoresSafeArea(edges: .top)
                    
                Button(action: { notesManager.fetchNotes() })
                {
                    Text("PolyPrep <<")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.accent)
                        .padding(.leading, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 40)
                        .background(Theme.header)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onOpenURL { url in
            authService.handleAuthCallback(url: url)
        }
    }
    
    private var ProfileTab: some View
    {
        // Profile Tab
        NavigationView {
//            ViewProfile
            ProfileView(authService: authService, notesManager: notesManager)
        }
        .tabItem {
            Image(systemName: "person.fill")
            Text("Профиль")
        }
        .tag(2)
    }
    
    private var BookmarksTab: some View
    {
        // Bookmarks Tab
        NavigationView {
            ZStack {
                Theme.background.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        //                        ForEach(Array(savedNotes.enumerated()), id: \.element.id) { index, _ in
                        //                            NoteCard(note: &notesManager.notes[index],
                        //                                     savedNotes: $savedNotes,
                        //                                     notesManager: notesManager,
                        //                                     currentUsername: authService.username ?? "Неизвестный пользователь").contentShape(Rectangle())
                        //                        }
                        ForEach(notesManager.savedNotes) { note in
                            NoteCard(note: note, savedNotes: $notesManager.savedNotes, notesManager: notesManager, currentUsername: authService.username ?? "Неизвестный пользователь")
                                .contentShape(Rectangle())
                        }
                    }
                    .padding(.top, 62)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .tabItem {
            Image(systemName: "bookmark.fill")
            Text("Закладки")
        }
        .tag(1)
    }
    
    private var BottomButtons: some View
    {
        // Кнопки внизу
        HStack(spacing: 20) {
            // Кнопка поиска
            Button(action: {
                // Действие для поиска
                Task {
                    showSearch = true
                }
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.black)
                    Text("Поиск")
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(20)
            }
            
            // Кнопка новой заметки
            Button(action: {
                if authService.isLoggedIn {
                    showNewNote = true
                } else {
                    selectedTab = 2
                }
            }) {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                    Text("Новая заметка")
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(20)
            }
        }
        .padding(.bottom, 8)
    }
}

struct ProfileView: View {
    @ObservedObject var authService: AuthService
    @ObservedObject var notesManager: NotesManager
    // @State private var showSafari = false
    @State private var startingWebAuthenticationSession = false
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @StateObject private var userProfile: UserProfile
    @State private var showImagePicker = false
    @State private var showAvatarMenu = false
    
    init(authService: AuthService, notesManager: NotesManager) {
        self.authService = authService
        self.notesManager = notesManager
        self._userProfile = StateObject(wrappedValue: UserProfile(userInfo: authService.userInfo ?? UserInfo()))
//        self.userProfile.updateAvatar()
//        self.userProfile = UserProfile(userInfo: authService.userInfo ?? UserInfo())
    }
    
    var userNotes: [Note] {
        notesManager.getUserNotes(username: authService.username ?? "")
    }
    
    var body: some View {
        ZStack {
            Theme.background.edgesIgnoringSafeArea(.all)
            
            if authService.isLoggedIn {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 20) {
                            // Аватарка
                            ZStack {
                                if let avatarData = userProfile.avatarImage,
                                   let uiImage = UIImage(data: avatarData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 120, height: 120)
                                        .foregroundColor(.gray)
                                }
                                
                                // Кнопка изменения аватарки
                                Button(action: {
                                    showAvatarMenu = true
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.black)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .offset(x: 40, y: 40)
                                .confirmationDialog("Изменить аватар", isPresented: $showAvatarMenu) {
                                    Button("Выбрать фото") {
                                        showImagePicker = true
                                    }
                                    Button("Отмена", role: .cancel) { }
                                }
                            }
                            
                            Text(authService.username ?? "User")
                                .font(.title)
                                .foregroundColor(Theme.header)
//                            Text("User Information")
//                                .foregroundColor(Theme.header)
                            
                            Button(action: {
                                authService.updateUserInfo()
                                notesManager.user_notes.removeAll()
                                userProfile.loadAvatar((authService.profile_img_link ?? authService.userInfo?.img_link)!)
                                notesManager.updateFavourites()
                            }) {
                                Text("Обновить")
                                    .foregroundColor(.white)
                                    .frame(width: 200, height: 50)
                                    .background(Theme.accent)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Button(action: {
                                authService.logout()
                            }) {
                                Text("Выйти")
                                    .foregroundColor(.white)
                                    .frame(width: 200, height: 50)
                                    .background(Theme.accent)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.top, 60)
                        
                        // Все заметки пользователя
                        if !userNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Мои заметки")
                                    .font(.title2)
                                    .foregroundColor(Theme.header)
                                    .padding(.horizontal)
                                ForEach(userNotes) { note in
                                    NoteCard(note: note, savedNotes: .constant(userNotes), notesManager: notesManager, currentUsername: authService.username ?? "Неизвестный пользователь")
                                }
                            }
                            .padding(.top, 16)
                        }
                    }
                }
            } else {
                // Экран входа/регистрации
                VStack(spacing: 20) {
                    NavigationLink(destination: SettingsView()) {
                        Text("Настройки")
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Theme.accent)
                            .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Button(action: {
                        authService.register()
                        authService.RefreshToken(refresh_token: UserDefaults.standard.string(forKey: "refresh_token") ?? "")
//                        showSafari = true
                    }) {
                        Text("Регистрация")
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Theme.accent)
                            .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle())
//                    .sheet(isPresented: $showSafari) {
//                        WebViewWithPost(
//                            url: URL(string: APIConstants.baseURL + APIConstants.AuthEndpoints.check)!,
//                                        postData: ["refresh_token": "null", "access_token": "null", "next_page": "user"]
//                                    )
//                    }
                    
                    Button(action: {
                        Task {
                            await authService.CheckAuth(with: webAuthenticationSession)
                        }
                        }) {
                        Text("Вход")
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Theme.accent)
                            .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(attachments: .constant([])) { imageData in
                if let data = imageData {
                    userProfile.saveAvatar(data)
                }
            }
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
