//
//  MessageType.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import Foundation



enum MessageType: Int {
    case alive = 0
    case chatMessage
    case disconnecting
    case typingStatus
}

enum ChatMessageType: Int, SubMessageType {
    
    case ContentString = 0
    case ContentData
    case Reaction
    case Reply
    case TypingStatus
    
    var code: Int {
        return self.rawValue
    }
}


enum StatusMessageType: Int, SubMessageType {
    case Alive = 0
    case Disconnect
    
    var code: Int {
        return self.rawValue
    }
}

enum NewMessageType: Int {
    case Chat = 0
    case Status
}

protocol SubMessageType {
    var code: Int { get }
}

struct WSMessageHeader {
    let messageType: NewMessageType
    let subMessageType: SubMessageType
    
    var wsEncode: String {
        return "\(messageType.rawValue)*|\(subMessageType.code)*|"
    }
}

