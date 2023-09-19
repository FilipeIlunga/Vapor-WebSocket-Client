//
//  BinaryCodable+Extension.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 18/09/23.
//

import Foundation


extension Array: BinaryCodable where Element: Codable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(self.count)
        for element in self {
            try element.encode(to: encoder)
        }
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        let count = try decoder.decode(Int.self)
        guard count < 1024*1024*50 else {  //less than 50MB
            throw BinaryDecoder.Error.prematureEndOfData
        }
        self.init()
        self.reserveCapacity(count)
        for _ in 0 ..< count {
            let decoded = try Element.self.init(from: decoder)
            self.append(decoded)
        }
    }
}

extension String: BinaryCodable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        try Array(self.utf8).binaryEncode(to: encoder)
    }

    public init(fromBinary decoder: BinaryDecoder) throws {
        let utf8: [UInt8] = try Array(fromBinary: decoder)
        if let str = String(bytes: utf8, encoding: .utf8) {
            self = str
        } else {
            throw BinaryDecoder.Error.invalidUTF8(utf8)
        }
    }
}

extension FixedWidthInteger where Self: BinaryEncodable {
    public func binaryEncode(to encoder: BinaryEncoder) {
        encoder.appendBytes(of: self.bigEndian)
    }
}

extension FixedWidthInteger where Self: BinaryDecodable {
    public init(fromBinary binaryDecoder: BinaryDecoder) throws {
        var v = Self.init()
        try binaryDecoder.read(into: &v)
        self.init(bigEndian: v)
    }
}

extension Int8: BinaryCodable {}
extension UInt8: BinaryCodable {}
extension Int16: BinaryCodable {}
extension UInt16: BinaryCodable {}
extension Int32: BinaryCodable {}
extension UInt32: BinaryCodable {}
extension Int64: BinaryCodable {}
extension UInt64: BinaryCodable {}
