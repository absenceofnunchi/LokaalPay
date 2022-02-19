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
    let lightBlocks = Vectors.lightBlocks
    let mine = Mine()
    
    func test_blocks() throws {
        var previousHash = Data()
        var previousMinedHash = Data()
        guard let blocks = blocks else { return }
        
        for i in 0 ..< blocks.count {
            let block = blocks[i]
            guard let blockHash = try? block.generateBlockHash() else { return }
            
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
    
    func test_light_blocks() throws {
        var previousHash = Data()
        var previousMinedHash = Data()
        guard let blocks = lightBlocks else { return }
        
        for i in 0 ..< blocks.count {
            let block = blocks[i]
            
            /// Test the codability of the block
            guard let encoded = try? JSONEncoder().encode(block),
                  let decoded = try? JSONDecoder().decode(LightBlock.self, from: encoded) else { return }
            XCTAssertEqual(decoded, block)
            
            guard let fullBlock = try? JSONDecoder().decode(ChainBlock.self, from: decoded.data),
                  let blockHash = try? fullBlock.generateBlockHash() else { return }
            
            /// Test a block is propoerly instantiated
            XCTAssertNotNil(blockHash)
            XCTAssertEqual(blockHash.count, 32)
            XCTAssertNotEqual(previousHash, blockHash) /// Each blockHash shoud be different
            
            previousHash = blockHash
            
            /// Mining tests
            guard let hash = try? mine.generate(with: blockHash.toHexString()) else { return }
            XCTAssertNotNil(hash)
            XCTAssertNotEqual(previousMinedHash, hash)
            
            previousMinedHash = hash
        }
    }
    
    func test_blockchain() {
        guard let blocks = blocks else { return }
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
    
    func test_light_blockchain() {
        guard let blocks = lightBlocks else { return }
        var blockchain = Blockchain<LightBlock>()
        
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
        XCTAssertNotEqual(head.id.toHexString(), tail.id.toHexString())
        XCTAssertEqual(blockchain.count, 15)
        XCTAssertFalse(blockchain.isEmpty)
        
        guard let first = blockchain.popFirst() else { return }
        XCTAssertEqual(first, blocks[0])

        guard let head = blockchain.head else { return }
        XCTAssertTrue(blockchain.contains(head))
        
        /// Comparable testing
        let block1 = blockchain[blockchain.startIndex]
        let block2 = blockchain[blockchain.index(blockchain.startIndex, offsetBy: 3)]
        XCTAssertNotEqual(block1, block2)
        
        let randomIndex = blocks[Int(arc4random_uniform(UInt32(blocks.count)))]
        let blockchain2: Blockchain<LightBlock> = [randomIndex, blocks[4]]
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
    
    func test_core_data() {
        
    }
}
