//
//  WSMessage.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import Foundation

enum DataType: Int, WSCodable {
    case image = 0
    case document
}

struct WSReaction: Hashable, WSCodable {
    var count: Int
    var emoji: String
}

struct WSDeleteMessage: WSCodable {
    let id: String
    let messageTodeleteID: String
}

struct WSChatMessage: Hashable, WSCodable {
    let messageID: String
    var data: Data?
    var dataType: DataType?
    let senderID: String
    let timestamp: Date
    let content: String
    var isSendByUser: Bool
    var reactions: [WSReaction]

    var description: String {
        return "\(messageID)|\(senderID)|\(timestamp.timeIntervalSince1970)|\(content)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(messageID)
        hasher.combine(senderID)
        hasher.combine(timestamp)
    }
    
    mutating func addReaction(_ reaction: WSReaction) {
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
