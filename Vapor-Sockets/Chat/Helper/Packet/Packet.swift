//
//  Packet.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 19/09/23.
//

import Foundation

struct Packet: BinaryCodable {

    let totalSize: Int
    let currentSize: Int
    let data: Data

    init(totalSize: Int, currentSize: Int, data: Data) {
        self.totalSize = totalSize
        self.currentSize = currentSize
        self.data = data
    }


    enum CodingKeys: String, CodingKey {
        case totalSize
        case currentSize
        case data
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalSize, forKey: .totalSize)
        try container.encode(currentSize, forKey: .currentSize)
        try container.encode(data, forKey: .data)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalSize = try container.decode(Int.self, forKey: .totalSize)
        currentSize = try container.decode(Int.self, forKey: .currentSize)
        data = try container.decode(Data.self, forKey: .data)
    }
}
