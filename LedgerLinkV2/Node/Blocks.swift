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

public struct FullBlock: Decodable {
    public var number: BigUInt
    public var hash: Data
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
        case logsBloom
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
    
    public init(number: BigUInt, parentHash: Data, nonce: Data? = nil, transactionsRoot: Data, stateRoot: Data, receiptsRoot: Data, miner: EthereumAddress? = nil, difficulty: BigUInt? = nil, totalDifficulty: BigUInt? = nil, extraData: Data? = nil, gasLimit: BigUInt? = nil, gasUsed: BigUInt? = nil, transactions: [TreeConfigurableTransaction], uncles: [Data]? = nil) throws {
        self.number = number
        self.parentHash = parentHash
        self.nonce = nonce
        self.transactionsRoot = transactionsRoot
        self.stateRoot = stateRoot
        self.receiptsRoot = receiptsRoot
        self.miner = miner
        self.difficulty = difficulty
        self.totalDifficulty = totalDifficulty
        self.extraData = extraData
        self.gasLimit = gasLimit
        self.gasUsed = gasUsed
        self.timestamp = Date()
        self.transactions = transactions
        self.uncles = uncles
        
        var totalSize = 0
        totalSize += MemoryLayout.size(ofValue: self.number)
        totalSize += MemoryLayout.size(ofValue: self.parentHash)
        totalSize += MemoryLayout.size(ofValue: self.nonce)
        totalSize += MemoryLayout.size(ofValue: self.transactionsRoot)
        totalSize += MemoryLayout.size(ofValue: self.stateRoot)
        totalSize += MemoryLayout.size(ofValue: self.receiptsRoot)
        totalSize += MemoryLayout.size(ofValue: self.miner)
        totalSize += MemoryLayout.size(ofValue: self.difficulty)
        totalSize += MemoryLayout.size(ofValue: self.totalDifficulty)
        totalSize += MemoryLayout.size(ofValue: self.extraData)
        totalSize += MemoryLayout.size(ofValue: self.gasLimit)
        totalSize += MemoryLayout.size(ofValue: self.gasUsed)
        totalSize += MemoryLayout.size(ofValue: self.timestamp)
        totalSize += MemoryLayout.size(ofValue: self.transactions)
        totalSize += MemoryLayout.size(ofValue: self.uncles)
        self.size = BigUInt(totalSize)
        
        self.hash = Data()
        self.hash = try generateBlockHash()
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(number.serialize().toHexString(), forKey: .number)
        try encoder.encode(hash, forKey: .hash)
        try encoder.encode(nonce, forKey: .nonce)
        try encoder.encode(parentHash, forKey: .parentHash)
        try encoder.encode(nonce, forKey: .nonce)
        try encoder.encode(transactionsRoot, forKey: .transactionsRoot)
        try encoder.encode(stateRoot, forKey: .stateRoot)
        try encoder.encode(receiptsRoot, forKey: .receiptsRoot)
        try encoder.encode(miner, forKey: .miner)
        try encoder.encode(difficulty?.serialize(), forKey: .difficulty)
        try encoder.encode(totalDifficulty?.serialize(), forKey: .totalDifficulty)
        try encoder.encode(extraData, forKey: .extraData)
        try encoder.encode(size.serialize(), forKey: .size)
        try encoder.encode(gasLimit?.serialize(), forKey: .gasLimit)
        try encoder.encode(gasUsed?.serialize(), forKey: .gasUsed)
        let dateInt = Int(timestamp.timeIntervalSince1970)
        let dateHex = String(dateInt, radix: 16, uppercase: true)
        try encoder.encode(dateHex, forKey: .timestamp)
        try encoder.encode(transactions, forKey: .transactions)
        let convertedUncles = uncles?.map { $0.toHexString() }
        try encoder.encode(convertedUncles, forKey: .uncles)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let number = try decodeHexToBigUInt(container, key: .number) else {throw Web3Error.dataError}
        self.number = number
        
        guard let hash = try? container.decode(Data.self, forKey: .hash) else {throw Web3Error.dataError }
        self.hash = hash
        
        
        guard let parentHash = try? container.decode(Data.self, forKey: .parentHash) else { throw Web3Error.dataError }
        self.parentHash = parentHash
        
        if nonce != nil {
            guard let nonce = try? container.decode(Data.self, forKey: .nonce) else { throw Web3Error.dataError }
            self.nonce = nonce
        }
        
//        let logsBloomData = try decodeHexToData(container, key: .logsBloom, allowOptional: true)
//        var bloom:EthereumBloomFilter?
//        if logsBloomData != nil {
//            bloom = EthereumBloomFilter(logsBloomData!)
//        }
//        self.logsBloom = bloom
        
        guard let transactionsRoot = try? container.decode(Data.self, forKey: .transactionsRoot) else { throw Web3Error.dataError }
        self.transactionsRoot = transactionsRoot
        
        guard let stateRoot = try? container.decode(Data.self, forKey: .stateRoot) else { throw Web3Error.dataError }
        self.stateRoot = stateRoot
        
        guard let receiptsRoot = try? container.decode(Data.self, forKey: .receiptsRoot) else { throw Web3Error.dataError }
        self.receiptsRoot = receiptsRoot
        
        if miner != nil {
            let minerAddress = try? container.decode(String.self, forKey: .miner)
            var miner:EthereumAddress?
            if minerAddress != nil {
                guard let minr = EthereumAddress(minerAddress!) else {throw Web3Error.dataError}
                miner = minr
            }
            self.miner = miner
        }
        
        if difficulty != nil {
            guard let difficulty = try? container.decode(Data.self, forKey: .difficulty) else { throw Web3Error.dataError }
            self.difficulty = BigUInt(difficulty)
        }
        
        if totalDifficulty != nil {
            guard let totalDifficulty = try? container.decode(Data.self, forKey: .totalDifficulty) else { throw Web3Error.dataError }
            self.totalDifficulty = BigUInt(totalDifficulty)
        }
        
        if extraData != nil {
            guard let extraData = try? container.decode(Data.self, forKey: .extraData) else { throw Web3Error.dataError }
            self.extraData = extraData
        }
        
        guard let size = try? container.decode(Data.self, forKey: .size) else { throw Web3Error.dataError }
        self.size = BigUInt(size)
        
        if gasLimit != nil {
            guard let gasLimit = try? container.decode(Data.self, forKey: .gasLimit) else { throw Web3Error.dataError }
            self.gasLimit = BigUInt(gasLimit)
        }
        
        if gasUsed != nil {
            guard let gasUsed = try? container.decode(Data.self, forKey: .gasUsed) else { throw Web3Error.dataError }
            self.gasUsed = BigUInt(gasUsed)
        }
        
        let timestampString = try container.decode(String.self, forKey: .timestamp).stripHexPrefix()
        guard let timestampInt = UInt64(timestampString, radix: 16) else {throw Web3Error.dataError}
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        self.timestamp = timestamp
        
        let transactions = try container.decode([TreeConfigurableTransaction].self, forKey: .transactions)
        self.transactions = transactions
        
        if uncles != nil {
            let unclesStrings = try container.decode([String].self, forKey: .uncles)
            var uncles = [Data]()
            for str in unclesStrings {
                guard let d = Data.fromHex(str) else {throw Web3Error.dataError}
                uncles.append(d)
            }
            self.uncles = uncles
        }
    }
}

extension FullBlock: Encodable {
    
    public func generateBlockHash() throws -> Data {
        guard let timestampData = try? JSONEncoder().encode(timestamp) else { throw NodeError.encodingError }
        var leaves = [number.serialize(), parentHash, transactionsRoot, stateRoot, receiptsRoot, timestampData, size.serialize()]
        
        if let nonce = nonce {
            leaves.append(nonce)
        }
        
        if let miner = miner {
            leaves.append(miner.addressData)
        }
        
        if let difficulty = difficulty {
            leaves.append(difficulty.serialize())
        }
        
        if let totalDifficulty = totalDifficulty {
            leaves.append(totalDifficulty.serialize())
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

extension FullBlock: Equatable {
    public static func == (lhs: FullBlock, rhs: FullBlock) -> Bool {
        var conditions = [
            lhs.number == rhs.number,
            lhs.parentHash == rhs.parentHash,
            lhs.transactionsRoot == rhs.transactionsRoot,
            lhs.stateRoot == rhs.stateRoot,
            lhs.receiptsRoot == rhs.receiptsRoot,
            lhs.transactionsRoot == rhs.transactionsRoot,
            lhs.size == rhs.size,
            abs(lhs.timestamp.timeIntervalSince(rhs.timestamp)) < 1,
            lhs.transactions == rhs.transactions,
            lhs.hash == rhs.hash
        ]
        
        if let lnonce = lhs.nonce, let rnonce = rhs.nonce {
            conditions.append(lnonce == rnonce)
        }
        
        if let lminer = lhs.miner, let rminer = rhs.miner {
            conditions.append(lminer == rminer)
        }
        
        if let ldifficulty = lhs.difficulty, let rdifficulty = rhs.difficulty {
            conditions.append(ldifficulty == rdifficulty)
        }
        
        if let ldifficulty = lhs.totalDifficulty, let rdifficulty = rhs.totalDifficulty {
            conditions.append(ldifficulty == rdifficulty)
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
 */

struct LightBlock: LightConfigurable {
    typealias T = FullBlock
    var id: String
    var number: BigUInt
    var data: Data
    var dictionaryValue: [String: Any] {
        [
            "id": id,
            "number": number,
            "data": data
        ]
    }
    
    init(data: FullBlock) throws {
        self.id = data.hash.toHexString()
        self.number = data.number

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
    
    init(id: String, number: BigUInt, data: Data) {
        self.id = id
        self.number = number
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
            return nil
        }
    }
    
    static func fromCoreData(crModel: BlockCoreData) -> LightBlock? {
        guard let id = crModel.id,
              let data = crModel.data else { return nil }
        let convertedNumber = BigUInt(crModel.number)
        return LightBlock(id: id, number: convertedNumber, data: data)
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
            print(error)
            return nil
        }
    }

    static func < (lhs: LightBlock, rhs: LightBlock) -> Bool {
        return (lhs.id < rhs.id) && (lhs.data.toHexString() < rhs.data.toHexString())
    }
}

extension LightBlock {
    // The keys must have the same name as the attributes of the StateCoreData, TransactionCoreEntity, or ReceiptCoreEntity entity. For newBatchInsertRequest in Core Data.
    var dictionaryValue: [String: Any] {
        [
            "id": id,
            "number": number,
            "data": data
        ]
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
