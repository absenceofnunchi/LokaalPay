//
//  Block.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-08.
//

import Foundation
import web3swift
import CryptoKit

//public struct Block {
//    public struct Header {
//        var blockNumber: Int
//        var parentHash: String
//        var ommersHash: [String]?
//        var stateRoot: String
//        var receiptsRoot: String
//        var transactionRoot: String
//        var timeStamp: Date
//        var extraData: Data?
//
//        public func generateBlockHash() -> String? {
//            var leaves = [blockNumber.description.sha256(), parentHash, stateRoot, receiptsRoot, timeStamp.description.sha256()]
//            if let ommersHash = ommersHash,
//               let encoded = try? JSONEncoder().encode(ommersHash) {
//                let hashed = SHA256.hash(data: encoded)
//                leaves.append(hashed.hexStr)
//            }
//
//            if let extraData = extraData {
//                let hashed = SHA256.hash(data: extraData)
//                leaves.append(hashed.hexStr)
//            }
//
//            do {
//                let rootNode = try MerkleTree<String>.buildTree(fromData: leaves)
//                if case .Node(hash: let merkleRoot, datum: _, left: _, right: _) = rootNode {
//                    return merkleRoot
//                } else {
//                    return nil
//                }
//            } catch {
//                return nil
//            }
//        }
//    }
//
//    public struct Body {
//        var transactions: [EthereumTransaction]
//        var ommers: [Block]
//    }
//}

extension Block: Encodable {
    
    enum CodingKeys: String, CodingKey {
        case number
        case hash
        case parentHash
        case nonce
        case sha3Uncles
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
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(hash, forKey: .hash)
        try encoder.encode(nonce, forKey: .nonce)
        try encoder.encode(parentHash, forKey: .parentHash)
        try encoder.encode(nonce, forKey: .nonce)
        try encoder.encode(sha3Uncles, forKey: .sha3Uncles)
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
}
