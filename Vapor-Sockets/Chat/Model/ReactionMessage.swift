//
//  ReactionMessage.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 04/09/23.
//

import Foundation

struct ReactionMessage: WSCodable {
    let userID: String
    let id: String
    let messageReactedID: String
    let reactionIcon: WSReaction
}
