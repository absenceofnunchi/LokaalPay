//
//  BlockchainTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-17.
//

import XCTest
import BigInt
import web3swift
@testable import LedgerLinkV2

final class BlockchainTests: XCTestCase {
//    let binaryHashes = Vectors.binaryHashes
//    let treeConfigTransactions = Vectors.treeConfigurableTransactions
    let blocks = Vectors.blocks
    let mine = Mine()
    
    func test_blocks() {
        var previousHash = Data()
        var previousMinedHash = Data()

        for i in 0 ..< blocks.count {
//            let block = Block(number: BigUInt(i), hash: binaryHashes[i], parentHash: binaryHashes[i], transactionsRoot: binaryHashes[i], stateRoot: binaryHashes[i], receiptsRoot: binaryHashes[i], size: BigUInt(i), timestamp: Date(), transactions: [treeConfigTransactions[i]])
            let block = blocks[i]
            guard let blockHash = block.generateBlockHash() else { return }
            
            /// Test a block is propoerly instantiated
            XCTAssertNotNil(blockHash)
            XCTAssertEqual(blockHash.count, 32)
            XCTAssertNotEqual(previousHash, blockHash) /// Each blockHash shoud be different
            
            previousHash = blockHash
            
            /// Test the codability of the block
            guard let encoded = try? JSONEncoder().encode(block),
                  let decoded = try? JSONDecoder().decode(ChainBlock.self, from: encoded) else { return }
            XCTAssertEqual(decoded, block)
            
            /// Mining tests
            guard let hash = try? mine.generate(with: blockHash.toHexString()) else { return }
            XCTAssertNotNil(hash)
            XCTAssertNotEqual(previousMinedHash, hash)
            
            previousMinedHash = hash
        }
    }
    
    func test_append() {
        var blockchain = Blockchain<ChainBlock>()
        
        /// Subscript testing
        blockchain = [blocks[0], blocks[3]]
        let startIndex = blockchain.startIndex
        let firstBlock = blockchain[startIndex]
        XCTAssertEqual(firstBlock, blocks[0])
        XCTAssertTrue(blockchain.elementsEqual([blocks[0], blocks[3]]))
        
        blockchain.removeAll()
        
        /// Append testing
        for i in 0 ..< blocks.count {
            let block = blocks[i]
            blockchain.append(block)
        }
        
        /// Collection testing
        guard let head = blockchain.head,
              let tail = blockchain.tail else { return }
        XCTAssertEqual(head.number.description, "0")
        XCTAssertEqual(tail.number.description, "14")
        XCTAssertEqual(blockchain.count, 15)
        XCTAssertFalse(blockchain.isEmpty)
        
        guard let first = blockchain.popFirst() else { return }
        XCTAssertEqual(first, blocks[0])
        
        let filterd = blockchain.filter { $0.number > 10 }
        XCTAssertFalse(filterd.contains(blocks[2]))
        
        /// Comparable testing
        let block1 = blockchain[blockchain.startIndex]
        let block2 = blockchain[blockchain.index(blockchain.startIndex, offsetBy: 3)]
        XCTAssertNotEqual(block1, block2)
        
        let randomIndex = blocks[Int(arc4random_uniform(UInt32(blocks.count)))]
        let blockchain2: Blockchain<ChainBlock> = [randomIndex, blocks[4]]
        XCTAssertNotEqual(blockchain, blockchain2)
        
        var regularTotalSize = 0
        for i in 0 ..< blocks.count {
            let block = blocks[i]
            let size = MemoryLayout.size(ofValue: block)
            regularTotalSize += size
        }
        print("regularTotalSize", regularTotalSize)

        var encodedTotalSize = 0
        for i in 0 ..< blocks.count {
            let block = blocks[i]
            guard let encoded = try? JSONEncoder().encode(block) else { continue }
            let size = MemoryLayout.size(ofValue: encoded)
            encodedTotalSize += size
        }
        print("encodedTotalSize", encodedTotalSize)
        
        var rlpTotalSize = 0
        for i in 0 ..< blocks.count {
            let block = blocks[i]
            guard let encoded = try? JSONEncoder().encode(block),
                  let rlpEncoded = RLP.encode([encoded] as [AnyObject]) else { continue }
            let size = MemoryLayout.size(ofValue: rlpEncoded)
            rlpTotalSize += size
        }
        print("rlpTotalSize", rlpTotalSize)

        var compressedSize = 0
        for i in 0 ..< blocks.count {
            let block = blocks[i]
            guard let encoded = try? JSONEncoder().encode(block),
                  let compressed = encoded.compressed else { continue }
            let size = MemoryLayout.size(ofValue: compressed)
            compressedSize += size
        }
        print("compressedSize", compressedSize as Any)
    }
}
