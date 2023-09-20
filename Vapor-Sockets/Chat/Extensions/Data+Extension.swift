//
//  Data+Extension.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 19/09/23.
//

import Foundation

extension Data {
    func chunked(into chunkSize: Int) -> [Data] {
        var chunks = [Data]()
        var offset = 0
        while offset < count {
            let chunk = subdata(in: offset..<Swift.min(offset + chunkSize, count))
            chunks.append(chunk)
            offset += chunkSize
        }
        return chunks
    }
}
