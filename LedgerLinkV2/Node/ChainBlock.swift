//
//  ChainBlock.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-08.
//

import Foundation
import web3swift
import BigInt

public struct ChainBlock: Decodable {
    public var number: BigUInt
    public var hash: Data?
    public var parentHash: Data
    public var nonce: Data?
    public var logsBloom: EthereumBloomFilter?
    public var transactionsRoot: Data
    public var stateRoot: Data
    public var receiptsRoot: Data
    public var miner: EthereumAddress?
    public var difficulty: BigUInt?
    public var totalDifficulty: BigUInt?
    public var extraData: Data?
    public var size: BigUInt
    public var gasLimit: BigUInt?
    public var gasUsed: BigUInt?
    public var timestamp: Date
    public var transactions: [TreeConfigurableTransaction]
    public var uncles: [Data]?
    
    enum CodingKeys: String, CodingKey {
        case number
        case hash
        case parentHash
        case nonce
        case transactionsRoot
        case stateRoot
        case receiptsRoot
        case miner
        case difficulty
        case totalDifficulty
        case extraData
        case size
        case gasLimit
        case gasUsed
        case timestamp
        case transactions
        case uncles
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
        
//        let logsBloomData = try decodeHexToData(container, key: .logsBloom, allowOptional: true)
//        var bloom:EthereumBloomFilter?
//        if logsBloomData != nil {
//            bloom = EthereumBloomFilter(logsBloomData!)
//        }
//        self.logsBloom = bloom
        
        guard let transactionsRoot = try decodeHexToData(container, key: .transactionsRoot) else {throw Web3Error.dataError}
        self.transactionsRoot = transactionsRoot
        
        guard let stateRoot = try decodeHexToData(container, key: .stateRoot) else {throw Web3Error.dataError}
        self.stateRoot = stateRoot
        
        guard let receiptsRoot = try decodeHexToData(container, key: .receiptsRoot) else {throw Web3Error.dataError}
        self.receiptsRoot = receiptsRoot
        
        let minerAddress = try? container.decode(String.self, forKey: .miner)
        var miner:EthereumAddress?
        if minerAddress != nil {
            guard let minr = EthereumAddress(minerAddress!) else {throw Web3Error.dataError}
            miner = minr
        }
        self.miner = miner
        
        guard let difficulty = try decodeHexToBigUInt(container, key: .difficulty) else {throw Web3Error.dataError}
        self.difficulty = difficulty
        
        guard let totalDifficulty = try decodeHexToBigUInt(container, key: .totalDifficulty) else {throw Web3Error.dataError}
        self.totalDifficulty = totalDifficulty
        
        guard let extraData = try decodeHexToData(container, key: .extraData) else {throw Web3Error.dataError}
        self.extraData = extraData
        
        guard let size = try decodeHexToBigUInt(container, key: .size) else {throw Web3Error.dataError}
        self.size = size
        
        guard let gasLimit = try decodeHexToBigUInt(container, key: .gasLimit) else {throw Web3Error.dataError}
        self.gasLimit = gasLimit
        
        guard let gasUsed = try decodeHexToBigUInt(container, key: .gasUsed) else {throw Web3Error.dataError}
        self.gasUsed = gasUsed
        
        let timestampString = try container.decode(String.self, forKey: .timestamp).stripHexPrefix()
        guard let timestampInt = UInt64(timestampString, radix: 16) else {throw Web3Error.dataError}
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        self.timestamp = timestamp
        
        let transactions = try container.decode([TreeConfigurableTransaction].self, forKey: .transactions)
        self.transactions = transactions
        
        let unclesStrings = try container.decode([String].self, forKey: .uncles)
        var uncles = [Data]()
        for str in unclesStrings {
            guard let d = Data.fromHex(str) else {throw Web3Error.dataError}
            uncles.append(d)
        }
        self.uncles = uncles
    }
}

extension ChainBlock: Encodable {
    public init(number: BigUInt, hash: Data?, parentHash: Data, nonce: Data? = nil, transactionsRoot: Data, stateRoot: Data, receiptsRoot: Data, miner: EthereumAddress? = nil, difficulty: BigUInt? = nil, totalDifficulty: BigUInt? = nil, extraData: Data? = nil, size: BigUInt, gasLimit: BigUInt? = nil, gasUsed: BigUInt? = nil, timestamp: Date, transactions: [TreeConfigurableTransaction], uncles: [Data]? = nil) {
        self.number = number
        self.hash = hash
        self.parentHash = parentHash
        self.nonce = nonce
        self.transactionsRoot = transactionsRoot
        self.stateRoot = stateRoot
        self.receiptsRoot = receiptsRoot
        self.miner = miner
        self.difficulty = difficulty
        self.totalDifficulty = totalDifficulty
        self.extraData = extraData
        self.size = size
        self.gasLimit = gasLimit
        self.gasUsed = gasUsed
        self.timestamp = timestamp
        self.transactions = transactions
        self.uncles = uncles
        
        
    }

    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(hash, forKey: .hash)
        try encoder.encode(nonce, forKey: .nonce)
        try encoder.encode(parentHash, forKey: .parentHash)
        try encoder.encode(nonce, forKey: .nonce)
        try encoder.encode(transactionsRoot, forKey: .transactionsRoot)
        try encoder.encode(stateRoot, forKey: .stateRoot)
        try encoder.encode(receiptsRoot, forKey: .receiptsRoot)
        try encoder.encode(miner, forKey: .miner)
        try encoder.encode(difficulty, forKey: .difficulty)
        try encoder.encode(totalDifficulty, forKey: .totalDifficulty)
        try encoder.encode(extraData, forKey: .extraData)
        try encoder.encode(size, forKey: .size)
        try encoder.encode(gasLimit, forKey: .gasLimit)
        try encoder.encode(gasUsed, forKey: .gasUsed)
        try encoder.encode(timestamp, forKey: .timestamp)
        try encoder.encode(transactions, forKey: .transactions)
        try encoder.encode(uncles, forKey: .uncles)
    }
    
    public func generateBlockHash() -> Data? {
        guard let timestampData = try? JSONEncoder().encode(timestamp) else { return nil }
        var leaves = [number.serialize(), parentHash, transactionsRoot, stateRoot, receiptsRoot, timestampData]
        
        if let uncles = uncles,
           let encoded = try? JSONEncoder().encode(uncles) {
            leaves.append(encoded)
        }
        
        if let extraData = extraData {
            leaves.append(extraData)
        }
        
        do {
            let rootNode = try MerkleTree<Data>.buildTree(fromData: leaves)
            if case .Node(hash: let merkleRoot, datum: _, left: _, right: _) = rootNode {
                return merkleRoot
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
}

extension ChainBlock: Equatable {
    public static func == (lhs: ChainBlock, rhs: ChainBlock) -> Bool {
        var conditions = [
            lhs.number == rhs.number,
            lhs.parentHash == rhs.parentHash,
            lhs.transactionsRoot == rhs.transactionsRoot,
            lhs.stateRoot == rhs.stateRoot,
            lhs.receiptsRoot == rhs.receiptsRoot,
            lhs.transactionsRoot == rhs.transactionsRoot,
            lhs.size == rhs.size,
            lhs.timestamp == rhs.timestamp,
            lhs.transactions == rhs.transactions
        ]
        
        if let lhash = lhs.hash, let rhash = rhs.hash {
            conditions.append(lhash == rhash)
        }

        if let lnonce = lhs.nonce, let rnonce = rhs.nonce {
            conditions.append(lnonce == rnonce)
        }
        
        if let lhash = lhs.hash, let rhash = rhs.hash {
            conditions.append(lhash == rhash)
        }
        
        if let lminer = lhs.miner, let rminer = rhs.miner {
            conditions.append(lminer == rminer)
        }
        
        if let ldifficult = lhs.difficulty, let rdifficulty = rhs.difficulty {
            conditions.append(ldifficult == rdifficulty)
        }
        
        if let ldifficult = lhs.totalDifficulty, let rdifficulty = rhs.totalDifficulty {
            conditions.append(ldifficult == rdifficulty)
        }
        
        if let rh = lhs.extraData, let lh = rhs.extraData {
            conditions.append(lh == rh)
        }
        
        if let rh = lhs.gasLimit, let lh = rhs.gasLimit {
            conditions.append(lh == rh)
        }
        
        if let rh = lhs.gasUsed, let lh = rhs.gasUsed {
            conditions.append(lh == rh)
        }
        
        if let rh = lhs.uncles, let lh = rhs.uncles {
            conditions.append(lh == rh)
        }
        
        let isEqual = conditions.allSatisfy({ $0 == true })
        return isEqual
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

struct LightBlock: LightConfigurable {
    typealias T = ChainBlock
    var id: Data
    var data: Data
    
    init(data: ChainBlock) throws {
        
    }
    
    func decode() -> ChainBlock? {
        
    }

    static func < (lhs: LightBlock, rhs: LightBlock) -> Bool {
        <#code#>
    }


}
