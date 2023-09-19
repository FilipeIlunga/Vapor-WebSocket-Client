//
//  WSCodable.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import Foundation

typealias WSCodable = Codable & BinaryCodable

final class WSCoder {
    private init() {}
    static let shared = WSCoder()
    
    func decode<T>(type: T.Type, from dataString: String) throws -> T where T: WSCodable {
        
        guard let jsonData = dataString.data(using: .utf8) else {
            throw NSError(domain: "Error ao converter string para jason", code: 0)
        }
        
        let decoder = JSONDecoder()
        let wsObject = try decoder.decode(T.self, from: jsonData)
        
        return wsObject
    }
    
    func encode(data: WSCodable) throws -> String {
        let encoder = JSONEncoder()
        let jsonEncodeData = try encoder.encode(data)
        
        guard let wsEncode = String(data: jsonEncodeData, encoding: .utf8) else {
            throw NSError(domain: "Erro ao converte json para string", code: 0)
        }
        
        return wsEncode
    }
}
