//
//  Packet.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 19/09/23.
//

import Foundation

struct Packet: BinaryCodable {

    let userID: String
    let messageID: String
    let totalSize: Int
    let currentSize: Int
    let currentOffset: Int
    let isLast: Bool
    let data: [UInt8]

    init(userID: String, messageID: String, totalSize: Int, currentSize: Int,currentOffset: Int, isLast: Bool,data: [UInt8]) {
        self.userID = userID
        self.messageID = messageID
        self.totalSize = totalSize
        self.currentSize = currentSize
        self.currentOffset = currentOffset
        self.isLast = isLast
        self.data = data
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.messageID = try container.decode(String.self, forKey: .messageID)
        totalSize = try container.decode(Int.self, forKey: .totalSize)
        currentSize = try container.decode(Int.self, forKey: .currentSize)
        currentOffset = try container.decode(Int.self, forKey: .currentOffset)
        isLast = try container.decode(Bool.self, forKey: .isLast)
        data = try container.decode([UInt8].self, forKey: .data)
    }

    enum CodingKeys: String, CodingKey {
        case userID
        case messageID
        case totalSize
        case currentSize
        case currentOffset
        case isLast
        case data
    }

}
