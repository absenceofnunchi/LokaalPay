//
//  NetworkTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-24.
//

import XCTest
import MultipeerConnectivity
import web3swift
import BigInt
import Combine
@testable import LedgerLinkV2

public struct TestBlock: Codable {
    public var number: BigUInt
    public var hash: Data = Data()
    public var parentHash: Data
    public var nonce: Data?
    public var transactionsRoot: Data
    public var stateRoot: Data
    public var receiptsRoot: Data
    public var extraData: Data?
    public var size: BigUInt
    public var gasLimit: BigUInt?
    public var gasUsed: BigUInt?
    public var timestamp: Date
    public var transactions: [TreeConfigurableTransaction]?
    public var accounts: [TreeConfigurableAccount]?
    
    enum CodingKeys: String, CodingKey {
        case number
        case hash
        case parentHash
        case nonce
        case transactionsRoot
        case stateRoot
        case receiptsRoot
        case extraData
        case size
        case gasLimit
        case gasUsed
        case timestamp
        case transactions
        case accounts
    }
    
    public init(number: BigUInt, parentHash: Data, nonce: Data? = nil, transactionsRoot: Data, stateRoot: Data, receiptsRoot: Data, extraData: Data? = nil, gasLimit: BigUInt? = nil, gasUsed: BigUInt? = nil, transactions: [TreeConfigurableTransaction]?, accounts: [TreeConfigurableAccount]?) throws {
        self.number = number
        self.parentHash = parentHash
        self.nonce = nonce
        self.transactionsRoot = transactionsRoot
        self.stateRoot = stateRoot
        self.receiptsRoot = receiptsRoot
        self.extraData = extraData
        self.gasLimit = gasLimit
        self.gasUsed = gasUsed
        self.timestamp = Date()
        self.transactions = transactions
        self.accounts = accounts
        self.size = BigUInt(10)
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(number.serialize().toHexString(), forKey: .number)
        try encoder.encode(hash.toHexString(), forKey: .hash)
        try encoder.encode(parentHash.toHexString(), forKey: .parentHash)
        try encoder.encode(nonce?.toHexString(), forKey: .nonce)
        try encoder.encode(transactionsRoot.toHexString(), forKey: .transactionsRoot)
        try encoder.encode(stateRoot.toHexString(), forKey: .stateRoot)
        try encoder.encode(receiptsRoot.toHexString(), forKey: .receiptsRoot)
        try encoder.encode(extraData?.toHexString(), forKey: .extraData)
        try encoder.encode(size.serialize().toHexString(), forKey: .size)
        try encoder.encode(gasLimit?.serialize().toHexString(), forKey: .gasLimit)
        try encoder.encode(gasUsed?.serialize().toHexString(), forKey: .gasUsed)
        let dateInt = Int(timestamp.timeIntervalSince1970)
        let dateHex = String(dateInt, radix: 16, uppercase: true)
        try encoder.encode(dateHex, forKey: .timestamp)
        try encoder.encode(transactions, forKey: .transactions)
        try encoder.encode(accounts, forKey: .accounts)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let number = try decodeHexToBigUInt(container, key: .number) else {throw Web3Error.dataError}
        self.number = number
        
        guard let hash = try decodeHexToData(container, key: .hash) else {throw Web3Error.dataError}
        self.hash = hash
        
        guard let parentHash = try decodeHexToData(container, key: .parentHash) else {throw Web3Error.dataError}
        self.parentHash = parentHash
        
        let nonce = try decodeHexToData(container, key: .nonce, allowOptional: true)
        self.nonce = nonce

        guard let transactionsRoot = try decodeHexToData(container, key: .transactionsRoot) else {throw Web3Error.dataError}
        self.transactionsRoot = transactionsRoot

        guard let stateRoot = try decodeHexToData(container, key: .stateRoot) else {throw Web3Error.dataError}
        self.stateRoot = stateRoot

        guard let receiptsRoot = try decodeHexToData(container, key: .receiptsRoot) else {throw Web3Error.dataError}
        self.receiptsRoot = receiptsRoot

        let extraData = try decodeHexToData(container, key: .extraData, allowOptional: true)
        self.extraData = extraData

        guard let size = try decodeHexToBigUInt(container, key: .size) else {throw Web3Error.dataError}
        self.size = size

        let gasLimit = try decodeHexToBigUInt(container, key: .gasLimit, allowOptional: true)
        self.gasLimit = gasLimit

        let gasUsed = try decodeHexToBigUInt(container, key: .gasUsed, allowOptional: true)
        self.gasUsed = gasUsed

        let timestampString = try container.decode(String.self, forKey: .timestamp).stripHexPrefix()
        guard let timestampInt = UInt64(timestampString, radix: 16) else {throw Web3Error.dataError}
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        self.timestamp = timestamp

        let transactions = try container.decodeIfPresent([TreeConfigurableTransaction].self, forKey: .transactions)
        self.transactions = transactions

        let accounts = try container.decodeIfPresent([TreeConfigurableAccount].self, forKey: .accounts)
        self.accounts = accounts
    }
}


fileprivate func decodeHexToData<T>(_ container: KeyedDecodingContainer<T>, key: KeyedDecodingContainer<T>.Key, allowOptional:Bool = false) throws -> Data? {
    if (allowOptional) {
        let string = try? container.decode(String.self, forKey: key)
        if string != nil {
            guard let data = Data.fromHex(string!) else {throw Web3Error.dataError}
            return data
        }
        return nil
    } else {
        let string = try container.decode(String.self, forKey: key)
        guard let data = Data.fromHex(string) else {throw Web3Error.dataError}
        return data
    }
}

fileprivate func decodeHexToBigUInt<T>(_ container: KeyedDecodingContainer<T>, key: KeyedDecodingContainer<T>.Key, allowOptional:Bool = false) throws -> BigUInt? {
    if (allowOptional) {
        let string = try? container.decode(String.self, forKey: key)
        if string != nil {
            guard let number = BigUInt(string!.stripHexPrefix(), radix: 16) else {throw Web3Error.dataError}
            return number
        }
        return nil
    } else {
        let string = try container.decode(String.self, forKey: key)
        guard let number = BigUInt(string.stripHexPrefix(), radix: 16) else {throw Web3Error.dataError}
        return number
    }
}

final class NetworkTests: XCTestCase {
    let password = "1"
    var storage = Set<AnyCancellable>()

    func test_hello() {
        do {
            let bigint = BigUInt(100)
            let encoded = try JSONEncoder().encode(bigint)
            print(encoded)
            
            let hex = BigUInt(100).serialize().toHexString()
            let encoded1 = try JSONEncoder().encode(hex)
            print("1", encoded1)
        } catch {
            print(error)
        }
    }
    
    func test_codable() {
        for i in 0...10 {
            let testBlock = try? TestBlock(number: BigUInt(i), parentHash: binaryHashes[i], transactionsRoot: binaryHashes[i], stateRoot: binaryHashes[i], receiptsRoot: binaryHashes[i], transactions: [], accounts: [])
            
            do {
                let encoded = try JSONEncoder().encode(testBlock)
                print("encoded", encoded)
                guard let compressed = encoded.compressed else { return }
                print("compressed", compressed)
                
                guard let decompressed = compressed.decompressed else { return }
                print("de", decompressed)
                
                let decoded = try JSONDecoder().decode(TestBlock.self, from: decompressed)
                print("decoded", decoded)
            } catch {
                print(error)
            }
        }
    }
    
    func test_createNewBlock() {
        for _ in 0...5 {
            Node.shared.createBlock { lightBlock in
                print("lightblock", lightBlock)
            }
        }
    }
    
    func test_test() {
//        let date0 = Date()
//        let date1 = Date().advanced(by: 100)
//
//        print("A", date0 < date1)
//        print("B", date0 > date1)
        
        for transaction in transactions {
            guard let encodedTx = transaction.encode() else { return }
            let timeStampedTx = [
                Date(): encodedTx
            ]
            
            do {
                let encoded = try JSONEncoder().encode(timeStampedTx)
                print("encoded", encoded)
                guard let result = parse(encoded) else { return }
                switch result {
                    case .data(let data):
                        print("data", data)
                        break
                    case .date(let date):
                        print("date", date)
                        break
                    case .timeStampedData(let data):
                        print("timestamped", data)
                        break
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func parse(_ data: Data) -> Result? {
        if let decompressed = data.decompressed {
            return .data(decompressed)
        } else if let decoded = try? JSONDecoder().decode(Date.self, from: data) {
            return .date(decoded)
        } else if let decoded = try? JSONDecoder().decode([Date: Data].self, from: data) {
            return .timeStampedData(decoded)
        }
        
        return nil
    }
    
    enum Result {
        case data(Data)
        case date(Date)
        case timeStampedData([Date: Data])
    }
    
    struct Example: Codable {
        var extraData: Data?
        
        enum CodingKeys: String, CodingKey {
            case extraData
        }
        
        func encode(to encoder: Encoder) throws {
            var encoder = encoder.container(keyedBy: CodingKeys.self)
            try encoder.encode(extraData, forKey: .extraData)
        }
        
        init(extraData: Data?) {
            self.extraData = extraData
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.extraData = try container.decodeIfPresent(Data.self, forKey: .extraData)
        }
    }
    
    func test_test1() {
        let rlp1 = transactions[0].encode()!
        let rlp2 = transactions[1].encode()!
        let rlp3 = transactions[0].encode()!
        
        
        print(rlp1 == rlp2)
        print(rlp1 == rlp3)
    }
  
}
