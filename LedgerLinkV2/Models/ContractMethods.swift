//
//  ContractMethods.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-16.
//

import Foundation
import web3swift

enum ContractMethod: Codable {
    case createAccount(Data)
    case transferValue(Data)
    case blockchainDownloadRequest(Data)
    case blockchainDownloadResponse(Data)
    
    enum CodingKeys: String, CodingKey {
        case createAccount
        case transferValue
        case blockchainDownloadRequest
        case blockchainDownloadResponse
        
        var data: Data? {
            return Data(self.rawValue.utf8)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .createAccount(let rlpEncoded):
                try container.encode(rlpEncoded, forKey: .createAccount)
            case .transferValue(let rlpEncoded):
                try container.encode(rlpEncoded, forKey: .transferValue)
            case .blockchainDownloadRequest(let blockNumber):
                try container.encode(blockNumber, forKey: .blockchainDownloadRequest)
            case .blockchainDownloadResponse(let data):
                try container.encode(data, forKey: .blockchainDownloadResponse)
        }
    }
    
    static func encode(_ method: ContractMethod) throws -> Data? {
        switch method {
            case .createAccount(let rlpEncoded):
                let encoded = try JSONEncoder().encode(ContractMethod.createAccount(rlpEncoded))
                return encoded
            case .transferValue(let rlpEncoded):
                let encoded = try JSONEncoder().encode(ContractMethod.transferValue(rlpEncoded))
                return encoded
            case .blockchainDownloadRequest(let blockNumber):
                let encoded = try JSONEncoder().encode(ContractMethod.blockchainDownloadRequest(blockNumber))
                return encoded
            case .blockchainDownloadResponse(let data):
                let encoded = try JSONEncoder().encode(ContractMethod.blockchainDownloadResponse(data))
                return encoded
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        
        switch key {
            case .createAccount:
                let rlpEncoded = try container.decode(Data.self, forKey: .createAccount)
                self = .createAccount(rlpEncoded)
            case .transferValue:
                let rlpEncoded = try container.decode(Data.self, forKey: .transferValue)
                self = .transferValue(rlpEncoded)
            case .blockchainDownloadRequest:
                let blockNumber = try container.decode(Data.self, forKey: .blockchainDownloadRequest)
                self = .blockchainDownloadRequest(blockNumber)
            case .blockchainDownloadResponse:
                let data = try container.decode(Data.self, forKey: .blockchainDownloadResponse)
                self = .blockchainDownloadResponse(data)
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unabled to decode enum."
                    )
                )
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
