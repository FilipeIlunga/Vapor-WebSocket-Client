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

    var description: String {
        return "\(messageID)|\(senderID)|\(timestamp.timeIntervalSince1970)|\(content)"
    }
}
