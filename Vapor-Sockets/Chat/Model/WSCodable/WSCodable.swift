//
//  WSCodable.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 03/09/23.
//

import Foundation

protocol WSCodable: Codable {
    
}

extension WSCodable {
    func encode() throws -> String {
        let encoder = JSONEncoder()
        let jsonEncodeData = try encoder.encode(self)
        
        guard let wsEncode = String(data: jsonEncodeData, encoding: .utf8) else {
            throw NSError(domain: "Erro ao converte json para string", code: 0)
        }
        
        return wsEncode
    }
}

extension String {
    func decodeWSEncodable<T>(type: T.Type) throws -> T where T: WSCodable {
        
        guard let jsonData = self.data(using: .utf8) else {
            throw NSError(domain: "Error ao converter string para jason", code: 0)
        }
        
        let decoder = JSONDecoder()
        let wsObject = try decoder.decode(T.self, from: jsonData)
        
        return wsObject
    }
}
