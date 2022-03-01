//
//  ContractMethods.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-16.
//

import Foundation
import web3swift

enum ContractMethod: Codable {
    case createAccount(Data, Date)
    case blockchainDownloadResponse(Data, Date)
    
    enum CodingKeys: String, CodingKey {
        case createAccount
        case blockchainDownloadResponse
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .createAccount(let rlpEncoded, let date):
                try container.encodeValues(rlpEncoded, date, for: .createAccount)
            case .blockchainDownloadResponse(let data, let date):
                try container.encodeValues(data, date, for: .blockchainDownloadResponse)
            
        }
    }
    
    static func encode(_ method: ContractMethod) throws -> Data? {
        switch method {
            case .createAccount(let rlpEncoded, let date):
                let encoded = try JSONEncoder().encode(ContractMethod.createAccount(rlpEncoded, date))
                return encoded
            case .blockchainDownloadResponse(let data, let date):
                let encoded = try JSONEncoder().encode(ContractMethod.blockchainDownloadResponse(data, date))
                return encoded
                
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        
        switch key {
            case .createAccount:
                let (rlpEncoded, date): (Data, Date) = try container.decodeValues(for: .createAccount)
                self = .createAccount(rlpEncoded, date)
            case .blockchainDownloadResponse:
                let (data, date): (Data, Date) = try container.decodeValues(for: .blockchainDownloadResponse)
                self = .blockchainDownloadResponse(data, date)
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unabled to decode enum."
                    )
                )
        }
    }

    
    enum Name: String {
        case createAccount
        case transferValue
        case blockchainDownloadRequest
        case blockchainDownloadResponse
        
        var data: Data? {
            return Data(self.rawValue.utf8)
        }
    }
}

extension KeyedEncodingContainer {
    mutating func encodeValues<V1: Encodable, V2: Encodable>(
        _ v1: V1,
        _ v2: V2,
        for key: Key) throws {
            
            var container = self.nestedUnkeyedContainer(forKey: key)
            try container.encode(v1)
            try container.encode(v2)
        }
}

extension KeyedDecodingContainer {
    func decodeValues<V1: Decodable, V2: Decodable>(
        for key: Key) throws -> (V1, V2) {
            
            var container = try self.nestedUnkeyedContainer(forKey: key)
            return (
                try container.decode(V1.self),
                try container.decode(V2.self)
            )
        }
}
