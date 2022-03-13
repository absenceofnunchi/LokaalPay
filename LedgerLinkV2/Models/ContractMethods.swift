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
    case blockchainDownloadRequest(Int32)
    case blockchainDownloadResponse(Packet)
    case blockchainDownloadAllRequest
    case blockchainDownloadAllResponse(Packet)
    case sendBlock(Data)
    case eventsQueryRequest
    case eventsQueryResponse(Data)
    
    enum CodingKeys: String, CodingKey {
        case createAccount
        case transferValue
        case blockchainDownloadRequest
        case blockchainDownloadResponse
        case blockchainDownloadAllRequest
        case blockchainDownloadAllResponse
        case sendBlock
        case eventsQueryRequest
        case eventsQueryResponse
        
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
                /// Block number is passed to let the recipient know from which point in the blockchain the sender needs to download
                try container.encode(blockNumber, forKey: .blockchainDownloadRequest)
            case .blockchainDownloadResponse(let packet):
                let encoded = try JSONEncoder().encode(packet)
                guard let compressed = encoded.compressed else { return }
                try container.encode(compressed, forKey: .blockchainDownloadResponse)
            case .blockchainDownloadAllRequest:
                try container.encode("blockchainDownloadAllRequest", forKey: .blockchainDownloadAllRequest)
            case .blockchainDownloadAllResponse(let packet):
                let encoded = try JSONEncoder().encode(packet)
                guard let compressed = encoded.compressed else { return }
                try container.encode(compressed, forKey: .blockchainDownloadAllResponse)
            case .sendBlock(let data):
                try container.encode(data, forKey: .sendBlock)
            case .eventsQueryRequest:
                try container.encode("eventsQueryRequest", forKey: .eventsQueryRequest)
            case .eventsQueryResponse(let data):
                try container.encode(data, forKey: .eventsQueryResponse)
        }
    }
    
    /// The difference between the regularing encoding and this method's encoding is:
    ///  1. Can be encoded statically and directly from the contract method instance
//    static func encode(_ method: ContractMethod) throws -> Data? {
//        switch method {
//            case .createAccount(let rlpEncoded):
//                let encoded = try JSONEncoder().encode(ContractMethod.createAccount(rlpEncoded))
//                return encoded
//            case .transferValue(let rlpEncoded):
//                let encoded = try JSONEncoder().encode(ContractMethod.transferValue(rlpEncoded))
//                return encoded
//            case .blockchainDownloadRequest(let blockNumber):
//                let encoded = try JSONEncoder().encode(ContractMethod.blockchainDownloadRequest(blockNumber))
//                return encoded
//            case .blockchainDownloadResponse(let data):
//                guard let compressed = data.compressed else { return nil }
//                let encodedFinal = try JSONEncoder().encode(ContractMethod.blockchainDownloadResponse(compressed))
//                return encodedFinal
//            case .sendBlock(let data):
//                guard let compressed = data.compressed else { return nil }
//                let encoded = try JSONEncoder().encode(ContractMethod.sendBlock(compressed))
//                return encoded
//        }
//    }
    
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
                let blockNumber = try container.decode(Int32.self, forKey: .blockchainDownloadRequest)
                self = .blockchainDownloadRequest(blockNumber)
            case .blockchainDownloadResponse:
                let data = try container.decode(Data.self, forKey: .blockchainDownloadResponse)
                guard let decompressed = data.decompressed else { throw NodeError.generalError("Unable to decode blockchain response in ContractMethod") }
                let decoded = try JSONDecoder().decode(Packet.self, from: decompressed)
                self = .blockchainDownloadResponse(decoded)
            case .blockchainDownloadAllRequest:
                guard let decoded = try? container.decode(String.self, forKey: .blockchainDownloadAllRequest), decoded == "blockchainDownloadAllRequest" else {
                    throw NodeError.generalError("Unable to decode blockchainDownloadAllRequest in ContractMethod")
                }
                self = .blockchainDownloadAllRequest
            case .blockchainDownloadAllResponse:
                let data = try container.decode(Data.self, forKey: .blockchainDownloadAllResponse)
                guard let decompressed = data.decompressed else { throw NodeError.generalError("Unable to decode blockchainDownloadAllResponse in ContractMethod") }
                let decoded = try JSONDecoder().decode(Packet.self, from: decompressed)
                self = .blockchainDownloadAllResponse(decoded)
            case .sendBlock:
                let data = try container.decode(Data.self, forKey: .sendBlock)
//                guard let decompressed = data.decompressed else { throw NodeError.generalError("Unable to decode sendBlock in ContractMethod") }
//                let decoded = try JSONDecoder().decode(LightBlock.self, from: decompressed)
                self = .sendBlock(data)
            case .eventsQueryRequest:
                guard let decoded = try? container.decode(String.self, forKey: .eventsQueryRequest), decoded == "eventsQueryRequest" else {
                    throw NodeError.generalError("Unable to decode eventsQueryRequest in ContractMethod")
                }
                self = .eventsQueryRequest
            case .eventsQueryResponse:
                let data = try container.decode(Data.self, forKey: .eventsQueryResponse)
                self = .eventsQueryResponse(data)
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
