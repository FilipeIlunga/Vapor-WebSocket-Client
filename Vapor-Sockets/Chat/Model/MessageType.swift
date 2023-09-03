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
