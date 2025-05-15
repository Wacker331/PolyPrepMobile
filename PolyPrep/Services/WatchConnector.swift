//
//  WatchConnector.swift
//  PolyPrep
//
//  Created by Дмитрий Григорьев on 15.05.2025.
//

import Foundation
import WatchConnectivity

class WatchConnector: NSObject, WCSessionDelegate, ObservableObject
{
    var session: WCSession
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func clear()
    {
        if session.isReachable
        {
            session.sendMessageData("clear".data(using: .utf8) ?? Data(), replyHandler: nil)
            print("SENDED CLEAR!!!")
        }
        else
        {
            print("ERROR: Session is not reachable!")
        }
    }
    
    func sendNotesToWatch(notes: [Note])
    {
        if session.isReachable
        {
            clear()
            for note in notes
            {
                let data: [String: Any] = [
                    "id": note.id,
                    "title": note.title,
                    "content": note.content,
                    "author": note.author,
                    "date": note.date
                ]
                session.sendMessage(data, replyHandler: nil)
                print("SENDED: ", data)
            }
        }
        else
        {
            print("ERROR: Session is not reachable!")
        }
    }
}
