//
//  WSMessage.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import Foundation

struct WSChatMessage: Hashable, WSCodable {
    let messageID: String
    let senderID: String
    let timestamp: Date
    let content: String
    var isSendByUser: Bool
    var reactions: [String]

    var description: String {
        return "\(messageID)|\(senderID)|\(timestamp.timeIntervalSince1970)|\(content)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(messageID)
        hasher.combine(senderID)
        hasher.combine(timestamp)
    }
    
    mutating func addReaction(_ reaction: String) {
        var mutableReactions = reactions
        mutableReactions.append(reaction)
        reactions = mutableReactions
    }
    
    func getDisplayDate() -> String {
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter
        }()
        
        return dateFormatter.string(from: timestamp)
    }
}
