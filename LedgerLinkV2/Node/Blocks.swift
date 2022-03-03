//
//  Blocks.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-08.
//

/*
 Abstract:
 
 FullBlock: an unencoded, uncompressed block. At a regular time interval, a block is instantiated by NodeDB.
 LightBlock: a full block is encoded into a Light block in order to improve the space complexity before being saved in Core Data. The light node is added to the Blockchain and the trees.
 */

import Foundation
import web3swift
import BigInt

public struct FullBlock: Codable {
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
    public var miner: String
    public var transactions: [TreeConfigurableTransaction]?
    public var accounts: [TreeConfigurableAccount]?
    public var uncles: [Data]?
    
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
        case miner
        case transactions
        case accounts
    }
    
    public init(number: BigUInt, parentHash: Data, nonce: Data? = nil, transactionsRoot: Data, stateRoot: Data, receiptsRoot: Data, extraData: Data? = nil, gasLimit: BigUInt? = nil, gasUsed: BigUInt? = nil, miner: String, transactions: [TreeConfigurableTransaction]?, accounts: [TreeConfigurableAccount]?) throws {
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
        self.miner = miner
        self.transactions = transactions
        self.accounts = accounts
        
        var totalSize = 0
        totalSize += MemoryLayout.size(ofValue: self.number)
        totalSize += MemoryLayout.size(ofValue: self.parentHash)
        totalSize += MemoryLayout.size(ofValue: self.nonce)
        totalSize += MemoryLayout.size(ofValue: self.transactionsRoot)
        totalSize += MemoryLayout.size(ofValue: self.stateRoot)
        totalSize += MemoryLayout.size(ofValue: self.receiptsRoot)
        totalSize += MemoryLayout.size(ofValue: self.extraData)
        totalSize += MemoryLayout.size(ofValue: self.gasLimit)
        totalSize += MemoryLayout.size(ofValue: self.gasUsed)
        totalSize += MemoryLayout.size(ofValue: self.timestamp)
        totalSize += MemoryLayout.size(ofValue: self.transactions)
        totalSize += MemoryLayout.size(ofValue: self.uncles)
        self.size = BigUInt(totalSize)
        
        self.hash = try generateBlockHash()
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
        try encoder.encode(miner, forKey: .miner)
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
        
        self.miner = try container.decode(String.self, forKey: .miner)
        
        let transactions = try container.decodeIfPresent([TreeConfigurableTransaction].self, forKey: .transactions)
        self.transactions = transactions
        
        let accounts = try container.decodeIfPresent([TreeConfigurableAccount].self, forKey: .accounts)
        self.accounts = accounts
    }
}

extension FullBlock {
    
    public func generateBlockHash() throws -> Data {
//        guard let timestampData = try? JSONEncoder().encode(timestamp) else { throw NodeError.encodingError }
        var leaves = [number.serialize(), parentHash, transactionsRoot, stateRoot, receiptsRoot, size.serialize()]
        
        if let nonce = nonce {
            leaves.append(nonce)
        }
        
        if let gasLimit = gasLimit {
            leaves.append(gasLimit.serialize())
        }
        
        if let gasUsed = gasUsed {
            leaves.append(gasUsed.serialize())
        }
        if let uncles = uncles,
           let encoded = try? JSONEncoder().encode(uncles) {
            leaves.append(encoded)
        }
        
        if let extraData = extraData {
            leaves.append(extraData)
        }
        
        let rootNode = try MerkleTree<Data>.buildTree(fromData: leaves)
        if case .Node(hash: let merkleRoot, datum: _, left: _, right: _) = rootNode {
            return merkleRoot
        } else {
            throw NodeError.hashingError
        }
    }
}

extension FullBlock: Equatable, Hashable {
    /// Excludes miner since two blocks can be considered the same regardless of who mined it.
    /// The information about a miner is still included because the unvalidated block pool prevents duplicates from the same miner.
    public static func == (lhs: FullBlock, rhs: FullBlock) -> Bool {
        var conditions = [
            lhs.number == rhs.number,
            lhs.parentHash == rhs.parentHash,
            lhs.transactionsRoot == rhs.transactionsRoot,
            lhs.stateRoot == rhs.stateRoot,
            lhs.receiptsRoot == rhs.receiptsRoot,
            lhs.transactionsRoot == rhs.transactionsRoot,
            lhs.size == rhs.size,
//            abs(lhs.timestamp.timeIntervalSince(rhs.timestamp)) < 1,
            lhs.hash == rhs.hash
        ]
        
        if let lnonce = lhs.nonce, let rnonce = rhs.nonce {
            conditions.append(lnonce == rnonce)
        }

        if let lhData = lhs.extraData, let rhData = rhs.extraData {
            conditions.append(lhData == rhData)
        }
        
        if let lhLimit = lhs.gasLimit, let rhLimit = rhs.gasLimit {
            conditions.append(lhLimit == rhLimit)
        }
        
        if let lh = lhs.gasUsed, let rh = rhs.gasUsed {
            conditions.append(lh == rh)
        }
        
        if let lh = lhs.uncles, let rh = rhs.uncles {
            conditions.append(lh == rh)
        }
        
        let isEqual = conditions.allSatisfy({ $0 == true })
        return isEqual
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(number)
        hasher.combine(parentHash)
        hasher.combine(transactionsRoot)
        hasher.combine(stateRoot)
        hasher.combine(receiptsRoot)
        hasher.combine(size)
//        hasher.combine(timestamp)
        hasher.combine(hash)
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

// MARK: - LightBlock

/*
 To be used for saving the full-ledged ChainBlock into Core Data. Better space complexity compared to ChainBlock
 PropertyLoopable protocol is used to extract the dictionary value of the properties for NSBatchInsertRequest instead of using a regular [String: Any] as one of the properties because it's not Codable
 The resulting keys must have the same name as the attributes of the StateCoreData, TransactionCoreEntity and other such entities.
 */

struct LightBlock: LightConfigurable, PropertyLoopable {    
    typealias T = FullBlock
    var id: String
    var number: Int32
    var data: Data
    
    init(data: FullBlock) throws {
        self.id = data.hash.toHexString()
        self.number = Int32(data.number)

        do {
            let encoded = try JSONEncoder().encode(data)
            guard let compressed = encoded.compressed else {
                throw NodeError.compressionError
            }
            self.data = compressed
        } catch {
            throw NodeError.encodingError
        }
    }
    
    init(id: String, number: Int32, data: Data) {
        self.id = id
        self.number = number
        self.data = data
    }
    
    init(id: String, number: BigUInt, data: Data) {
        self.id = id
        self.number = Int32(number)
        self.data = data
    }

    func decode() -> FullBlock? {
        do {
            guard let decompressed = data.decompressed else {
                throw NodeError.compressionError
            }
            
            let decoded = try JSONDecoder().decode(FullBlock.self, from: decompressed)
            return decoded
        } catch {
            print("decoding error", error)
            return nil
        }
    }
    
    static func fromCoreData(crModel: BlockCoreData) -> LightBlock? {
        guard let id = crModel.id,
              let data = crModel.data else { return nil }
        
        return LightBlock(id: id, number: crModel.number, data: data)
    }
    
    static func fromCoreData(crModel: BlockCoreData) -> FullBlock? {
        guard let data = crModel.data else { return nil }
        
        guard let chainBlock: FullBlock = decode(data) else {
            return nil
        }
        return chainBlock
    }

    static func decode(_ data: Data) -> FullBlock? {
        guard let decompressed = data.decompressed else {
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode(FullBlock.self, from: decompressed)
            return decoded
        } catch {
            print(error) /// < -- dataError
            return nil
        }
    }

    static func < (lhs: LightBlock, rhs: LightBlock) -> Bool {
        return (lhs.id < rhs.id) && (lhs.data.toHexString() < rhs.data.toHexString())
    }
}

// MARK: - BlockModel

/*
    Used as a buffer between Core Data format and regular format.
 */

//struct BlockModel {
//    let id: String
//    let number: BigUInt
//    let data: Data
//    
//    static func fromCoreData(crModel: BlockCoreData) -> BlockModel? {
//        guard let id = crModel.id,
//              let numberData = crModel.number,
//              let data = crModel.data else { return nil }
//
//        let number = BigUInt(numberData)
//
//        let model = BlockModel(id: id, number: number, data: data)
//        return model
//    }
//
//    static func fromCoreData(crModel: BlockCoreData) -> LightBlock? {
//        guard let data = crModel.data else { return nil }
//        
//        return decode(data)
//    }
//    
//    static func fromCoreData(crModel: BlockCoreData) -> ChainBlock? {
//        guard let data = crModel.data else { return nil }
//        
//        guard let chainBlock: ChainBlock = decode(data) else {
//            return nil
//        }
//        return chainBlock
//    }
//    
//    static func decode(_ model: BlockModel) -> ChainBlock? {
//        return decode(model.data)
//    }
//    
//    static func decode(_ data: Data) -> LightBlock? {
//        guard let decompressed = data.decompressed else {
//            return nil
//        }
//        
//        do {
//            let decoded = try JSONDecoder().decode(LightBlock.self, from: decompressed)
//            return decoded
//        } catch {
//            print(error)
//            return nil
//        }
//    }
//    
//    static func decode(_ data: Data) -> ChainBlock? {
//        guard let lightBlock: LightBlock = decode(data) else {
//            return nil
//        }
//        
//        return lightBlock.decode()
//    }
//}
