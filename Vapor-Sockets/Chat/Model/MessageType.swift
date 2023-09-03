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
    

}

enum StatusMessageType: Int, SubMessageType {
    case Alive
    case Disconnect
    

}

enum NewMessageType {
    case Chat
    case Status
}

protocol SubMessageType {
}

struct WSMessageHeader {
    let messageType: NewMessageType
    let subMessageType: SubMessageType
}

