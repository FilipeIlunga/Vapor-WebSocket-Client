//
//  Reaction+CoreDataProperties.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 17/09/23.
//
//

import Foundation
import CoreData


extension Reaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reaction> {
        return NSFetchRequest<Reaction>(entityName: "Reaction")
    }

    @NSManaged public var id: String?
    @NSManaged public var count: Int16
    @NSManaged public var emoji: String?
    @NSManaged public var message: ChatMessage?

}

extension Reaction : Identifiable {

}

extension Reaction {
    func toWSReaction() -> WSReaction? {
        guard let emoji = self.emoji else {
            return nil
        }
        
        return WSReaction(count: Int(self.count), emoji: emoji)
    }
}
