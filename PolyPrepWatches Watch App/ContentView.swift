//
//  ContentView.swift
//  PolyPrepWatches Watch App
//
//  Created by Дмитрий Григорьев on 15.05.2025.
//

import SwiftUI
import SwiftData

//struct ContentView: View {
//    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
//    }
//}
//
//#Preview {
//    SavedNotesView()
//}

@main
struct PolyPrep_Watch_AppApp: App {
//    @StateObject private var notesManager = NotesManager()
    
    var body: some Scene {
        WindowGroup {
            SavedNotesView(savedNotes: PhoneConnector.loadNotes())
//                .environmentObject(notesManager)
        }
    }
}

struct SavedNotesView: View {
//    @EnvironmentObject var notesManager: NotesManager
    
//    @State var savedNotes: [Note]
//    var phoneConnector: PhoneConnector = PhoneConnector()
    @StateObject private var phoneConnector: PhoneConnector
    @State private var showFullNote = false
    
    init(savedNotes: [Note]) {
        _phoneConnector = StateObject(wrappedValue: PhoneConnector(savedNotes: savedNotes))
    }
    
    var body: some View {
        if phoneConnector.savedNotes.isEmpty {
            VStack {
                Text("Нет сохраненных заметок")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        } else {
            List {
                ForEach(phoneConnector.savedNotes) { note in
                    Button(action: {
                        showFullNote = true
                    }){
                        NoteRow(note: note)
                    }
                    .sheet(isPresented: $showFullNote)
                    {
                        NoteView(note: note)
                    }
                }
            }
            .navigationTitle("Сохраненные")
        }
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(note.content)
                .font(.caption)
                .lineLimit(2)
                .foregroundColor(.gray)
            
            HStack {
                Text(note.author)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(note.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NoteView: View {
    let note: Note
    
    var body: some View {
        ScrollView
        {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(note.content)
                    .font(.caption)
                //                .lineLimit(2)
                    .foregroundColor(.gray)
                
                HStack {
                    Text(note.author)
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(note.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
            .ignoresSafeArea()
        }
    }
}

class Note: Identifiable, Codable
{
    var id: Int
    var title: String
    var content: String
    var author: String
    var date: Date
    
    init(id: Int, title: String, content: String, author: String, date: Date)
    {
        self.id = id
        self.title = title
        self.content = content
        self.author = author
        self.date = date
    }
}
