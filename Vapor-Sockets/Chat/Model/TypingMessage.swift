//
//  TypingMessage.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import Foundation

struct TypingMessage: WSCodable {
    let userID: String
    let isTyping: Bool
}
