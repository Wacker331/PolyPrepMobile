//
//  PhoneConnector.swift
//  PolyPrepWatches Watch App
//
//  Created by Дмитрий Григорьев on 15.05.2025.
//

import Foundation
import WatchConnectivity
import SwiftUI

class PhoneConnector: NSObject, WCSessionDelegate, ObservableObject
{
    var session: WCSession
    @Published var savedNotes: [Note]
    
    init(session: WCSession = .default, savedNotes: [Note]) {
        self.session = session
        self.savedNotes = savedNotes
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any])
    {
        let newNote = Note(
            id: message["id"] as! Int,
            title: message["title"] as! String,
            content: message["content"] as! String,
            author: message["author"] as! String,
            date: message["date"] as! Date
        )
        
        DispatchQueue.main.async
        {
            if !self.savedNotes.contains(where: { $0.id == newNote.id })
            {
                self.savedNotes.insert(newNote, at: 0)
            }
            self.saveNotes()
        }
        print(message)
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data)
    {
        print("MSG RECEIVED!")
        if String(data: messageData, encoding: .utf8) == "clear"
        {
            savedNotes.removeAll()
            print("CLEAR RECEIVED!")
        }
    }
    
    static func loadNotes() -> [Note] {
        guard let data = UserDefaults.standard.data(forKey: "savedNotes"),
              let notes = try? JSONDecoder().decode([Note].self, from: data) else {
            return []
        }
        return notes
    }
        
    private func saveNotes() {
        if let data = try? JSONEncoder().encode(savedNotes) {
            UserDefaults.standard.set(data, forKey: "savedNotes")
        }
    }
}
