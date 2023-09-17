//
//  ChatMessage+CoreDataProperties.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 17/09/23.
//
//

import Foundation
import CoreData


extension ChatMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMessage> {
        return NSFetchRequest<ChatMessage>(entityName: "ChatMessage")
    }

    @NSManaged public var content: String?
    @NSManaged public var id: String?
    @NSManaged public var isSendByUser: Bool
    @NSManaged public var senderID: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var messageReactions: NSSet?

}

// MARK: Generated accessors for messageReactions
extension ChatMessage {

    @objc(addMessageReactionsObject:)
    @NSManaged public func addToMessageReactions(_ value: Reaction)

    @objc(removeMessageReactionsObject:)
    @NSManaged public func removeFromMessageReactions(_ value: Reaction)

    @objc(addMessageReactions:)
    @NSManaged public func addToMessageReactions(_ values: NSSet)

    @objc(removeMessageReactions:)
    @NSManaged public func removeFromMessageReactions(_ values: NSSet)

}

extension ChatMessage : Identifiable {

}

extension ChatMessage {
    func toWSMessage() -> WSChatMessage? {
        guard let messageID = self.id,
              let senderID = self.senderID,
              let timestamp = self.timestamp,
              let content = self.content
              else {
            return nil
        }

        let reactions = self.messageReactions?.allObjects as? [Reaction] ?? []

        let wsChatMessage = WSChatMessage(messageID: messageID, senderID: senderID, timestamp: timestamp, content: content, isSendByUser: isSendByUser, reactions: reactions.compactMap {$0.toWSReaction()} )

        return wsChatMessage
    }
}
