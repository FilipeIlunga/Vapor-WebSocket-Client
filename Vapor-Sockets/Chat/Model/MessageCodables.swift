//
//  MessageType.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import Foundation

protocol MessageHeader {
    associatedtype MessageType
    var fromUserID: String { get set}
    var messageType: MessageType { get set}
    var subMessageTypeCode: Int { get set }
    
}

protocol SubMessageType: WSCodable {
    var code: Int { get }
}

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

enum NewMessageType: Int, WSCodable {
    case Chat = 0
    case Status
}

struct WSMessageHeader: WSCodable, MessageHeader {
    typealias MessageType = NewMessageType
    var fromUserID: String
    var messageType: MessageType
    var subMessageTypeCode: Int
    let payload: String
}
 
