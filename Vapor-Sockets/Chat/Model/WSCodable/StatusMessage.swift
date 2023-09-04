//
//  StatusMessage.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 04/09/23.
//

import Foundation

struct StatusMessage: WSCodable {
    let userID: String
    let type: StatusMessageType
}
