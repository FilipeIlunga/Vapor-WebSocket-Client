//
//  ReactionMessage.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 04/09/23.
//

import Foundation

struct ReactionMessage: WSCodable {
    let userID: String
    let messageID: String
    let messageReacted: WSChatMessage
    let reactionIcon: WSReaction
}
