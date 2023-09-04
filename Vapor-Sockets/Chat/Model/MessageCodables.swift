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

enum NewMessageType: Int, WSCodable {
    case Chat = 0
    case Status
}

struct WSMessageHeader {
    let messageType: NewMessageType
    let subMessageType: SubMessageType
    
    var wsEncode: String {
        return "\(messageType.rawValue)*|\(subMessageType.code)*|"
    }
}

protocol MessageHeader {
    associatedtype MessageType
    var messageType: MessageType { get set}
    var subMessageTypeCode: Int { get set }
    
    func makeWSMessage() throws -> String
}

protocol SubMessageType: WSCodable {
    var code: Int { get }
}

struct WSMessage: WSCodable, MessageHeader {
    typealias MessageType = NewMessageType
    
    var messageType: MessageType
    var subMessageTypeCode: Int
    let payload: String
    
    func makeWSMessage() throws -> String {
      let wsMessage = try self.encode()
        return wsMessage
    }
}

/*

 Mark: Exemplo de como decodar e decodar WSMessage
 
 let wsMessage = WSChatMessage(
     messageID: UUID().uuidString,
     senderID: user.userName,
     timestamp: timestamp,
     content: messageContent,
     isSendByUser: true)
 
 
 let socketMessage = getWSMessage(header: header, payload: wsMessage.description)
 
 //Encode -> Objeto para string
 let wsTest = try! WSMessage(messageType: .Chat, subMessageType: ChatMessageType.ContentString.code, payload: try! wsMessage.encode()).encode()

 // Decode -> String para objeto
 let x = try! wsTest.decodeWSEncodable(type: WSMessage.self)
 
 // Decode do payload
 switch x.messageType {
     
 case .Chat:
     guard let subMessage: ChatMessageType = ChatMessageType(rawValue: x.subMessageType) else {
         return
     }
     
     switch subMessage {
     case .ContentString:
         let y = try! x.payload.decodeWSEncodable(type: WSChatMessage.self)
     case .ContentData:
         print("")
     case .Reaction:
         print("")
     case .Reply:
         print("")
     case .TypingStatus:
         print("")
     }
     
 case .Status:
     print("")
 }

 
 */
