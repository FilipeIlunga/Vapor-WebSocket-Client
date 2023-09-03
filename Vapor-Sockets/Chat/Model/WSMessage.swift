//
//  WSMessage.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import Foundation

struct WSMessage: Hashable {
    let senderID: String
    let messageType: MessageType
    let timestamp: Date
    let content: String
    var isSendByUser: Bool

    
    var description: String {
        return "\(senderID)|\(messageType.rawValue)|\(timestamp.timeIntervalSince1970)|\(content)"
    }
}
