//
//  ChatMessage+CoreDataProperties.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 05/09/23.
//
//

import Foundation
import CoreData


extension ChatMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessage> {
        return NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
    }

    @NSManaged public var id: String?
    @NSManaged public var senderID: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var content: String?
    @NSManaged public var reactions: NSObject?
    @NSManaged public var isSendByUser: DarwinBoolean

}

extension ChatMessage : Identifiable {

}

extension ChatMessage {
    
    func toWSMessage() -> WSChatMessage? {
        guard let messageID = self.id,
              let senderID = self.senderID,
              let timestamp = self.timestamp,
              let content = self.content,
              let reactions = self.reactions as? [String] else {
            return nil
        }
        
        let wsChatMessage = WSChatMessage(messageID: messageID, senderID: senderID, timestamp: timestamp, content: content, isSendByUser: isSendByUser.boolValue, reactions: reactions)
        
        return wsChatMessage
    }
}
