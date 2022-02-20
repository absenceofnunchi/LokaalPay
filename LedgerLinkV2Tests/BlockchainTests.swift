//
//  BlockchainTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-17.
//

import XCTest
import BigInt
import web3swift
import Combine
@testable import LedgerLinkV2

final class BlockchainTests: XCTestCase {
    let mine = Mine()

    func test_blocks() throws {
        var previousHash = Data()
        var previousMinedHash = Data()

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
                  let decoded = try? JSONDecoder().decode(FullBlock.self, from: encoded) else { return }
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

        for i in 0 ..< lightBlocks.count {
            let block = lightBlocks[i]

            /// Test the codability of the block
            guard let encoded = try? JSONEncoder().encode(block),
                  let decoded = try? JSONDecoder().decode(LightBlock.self, from: encoded) else { return } // Decode to LightBlock
            XCTAssertEqual(decoded, block)
            
            guard let fullBlock = try? JSONDecoder().decode(FullBlock.self, from: decoded.data),
                  let decodedToFullBlock = LightBlock.decode(encoded), // Decode to FullBlock using its own method
                  let blockHash = try? fullBlock.generateBlockHash() else { return }

            XCTAssertEqual(decodedToFullBlock, fullBlock)
            /// Test a block is propoerly instantiated
            XCTAssertNotNil(blockHash)
            XCTAssertEqual(blockHash.count, 32)
            XCTAssertNotEqual(previousHash, blockHash) /// Each blockHash shoud be different

            previousHash = blockHash

            /// Mining tests
            /// Each block hash should be different if the content is different
            guard let hash = try? mine.generate(with: blockHash.toHexString()) else { return }
            XCTAssertNotNil(hash)
            XCTAssertNotEqual(previousMinedHash, hash)

            previousMinedHash = hash
        }
    }

    func test_blockchain() {
        var blockchain = Blockchain<FullBlock>()

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
        let blockchain2: Blockchain<FullBlock> = [randomIndex, blocks[4]]
        XCTAssertNotEqual(blockchain, blockchain2)
    }

    func test_light_blockchain() {
        var blockchain = Blockchain<LightBlock>()

        /// Subscript testing
        blockchain = [lightBlocks[0], lightBlocks[3]]
        let startIndex = blockchain.startIndex
        let firstBlock = blockchain[startIndex]
        XCTAssertEqual(firstBlock, lightBlocks[0])
        XCTAssertTrue(blockchain.elementsEqual([lightBlocks[0], lightBlocks[3]]))

        blockchain.removeAll()

        /// Append testing
        for i in 0 ..< lightBlocks.count {
            let block = lightBlocks[i]
            blockchain.append(block)
        }

        /// Collection testing
        guard let head = blockchain.head,
              let tail = blockchain.tail else { return }
        XCTAssertNotEqual(head.id, tail.id)
        XCTAssertEqual(blockchain.count, 15)
        XCTAssertFalse(blockchain.isEmpty)

        guard let first = blockchain.popFirst() else { return }
        XCTAssertEqual(first, lightBlocks[0])

        guard let head = blockchain.head else { return }
        XCTAssertTrue(blockchain.contains(head))

        /// Comparable testing
        let block1 = blockchain[blockchain.startIndex]
        let block2 = blockchain[blockchain.index(blockchain.startIndex, offsetBy: 3)]
        XCTAssertNotEqual(block1, block2)

        let randomIndex = lightBlocks[Int(arc4random_uniform(UInt32(lightBlocks.count)))]
        let blockchain2: Blockchain<LightBlock> = [randomIndex, lightBlocks[4]]
        XCTAssertNotEqual(blockchain, blockchain2)

        
//        var regularTotalSize = Data()
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            let size = MemoryLayout.size(ofValue: block)
//            regularTotalSize.append(block)
//        }
//        let regularTotalSize = MemoryLayout.size(ofValue: blocks)
//        print("regularTotalSize", regularTotalSize)
//
//        var encodedTotalSize = Data()
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            guard let encoded = try? JSONEncoder().encode(block) else { continue }
//            encodedTotalSize.append(encoded)
//        }
//        print("encodedTotalSize", encodedTotalSize)
//
//        var rlpTotalSize = Data()
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            guard let encoded = try? JSONEncoder().encode(block),
//                  let rlpEncoded = RLP.encode([encoded] as [AnyObject]) else { continue }
//            rlpTotalSize.append(rlpEncoded)
//        }
//        print("rlpTotalSize", rlpTotalSize)
//
//        var compressedSize = Data()
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            guard let encoded = try? JSONEncoder().encode(block),
//                  let compressed = encoded.compressed else { continue }
//            compressedSize.append(compressed)
//        }
//
//        print("compressedSize", compressedSize as Any)
    }
    
    /// Test Core Data operations from CoreDataService: Save, fetch by ID or Number, fetch the latest block, and delete.
    var storage = Set<AnyCancellable>()
    func test_core_data() {
        /// Delete all existing blocks in Core Data before testing
        LocalStorage.shared.deleteAllBlocks { error in
            if let error = error {
                XCTAssertNil(error)
            }
            
            do {
                let results: [LightBlock] = try LocalStorage.shared.getAllBlocks()
                XCTAssertNil(results)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        /// Save and fetch a single block
        let hash = "0xfFbb73852d9DA0DF8a9ecEbB85e896fd1e7D51Ec"
        guard let converted = hash.data(using: .utf8) else { return }
        let hashData = converted.sha256()
        guard let address = EthereumAddress(hash) else { return }
        let tx = EthereumTransaction(gasPrice: BigUInt(10), gasLimit: BigUInt(10), to: address, value: BigUInt(10), data: Data())
        guard let treeConfigTx = try? TreeConfigurableTransaction(data: tx) else { return }
        guard let block = try? FullBlock(number: BigUInt(10), parentHash: hashData, transactionsRoot: hashData, stateRoot: hashData, receiptsRoot: hashData, transactions: [treeConfigTx]) else { return }
        
        guard let lightBlock = try? LightBlock(data: block) else { return }
        Deferred {
            Future<Bool, NodeError> { promise in
                try? LocalStorage.shared.saveBlock(block: lightBlock) { error in
                    if let error = error {
                        XCTAssertNil(error)
                        promise(.failure(.generalError("error")))
                    }
                    promise(.success(true))
                    
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap { _ in
            Future<Bool, NodeError> { promise in
                let _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Core Data wait")], timeout: 1.0)
                promise(.success(true))
            }
            .eraseToAnyPublisher()
        }
        .sink { completion in
            switch completion {
                case .finished:
                    do {
                        guard let fetchedBlock: FullBlock = try LocalStorage.shared.getBlock(id: lightBlock.id) else {
                            fatalError()
                        }
                        XCTAssertEqual(fetchedBlock, block)
                    } catch {
                        fatalError()
                    }
                    break
                case .failure(let error):
                    XCTAssertNil(error)
                    break
            }
        } receiveValue: { _ in
 
        }
        .store(in: &storage)
        
        /// Save light blocks
        for block in blocks {
            guard let lightBlock = try? LightBlock(data: block) else { fatalError() }
            try? LocalStorage.shared.saveBlock(block: lightBlock) { error in
                if let error = error {
                    XCTAssertNil(error)
                }
            }
        }
        
        /// Wait till Core Data saves
        let _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Core Data wait")], timeout: 1.0)
        
        /// Fetch the previously saved light blocks as light blocks & full blocks
        for block in blocks {
            guard let lightBlock = try? LightBlock(data: block) else { fatalError() }
            
            do {
                guard let fetchedBlock: FullBlock = try LocalStorage.shared.getBlock(id: lightBlock.id) else {
                    fatalError()
                }
                XCTAssertEqual(fetchedBlock, block)
                
                guard let fetchedBlock: FullBlock = try LocalStorage.shared.getBlock(number: lightBlock.number) else {
                    fatalError()
                }
                XCTAssertEqual(fetchedBlock, block)
                
                guard let fetchedBlock: LightBlock = try LocalStorage.shared.getBlock(id: lightBlock.id) else {
                    fatalError()
                }
                XCTAssertEqual(fetchedBlock, lightBlock)
                
                guard let fetchedBlock: LightBlock = try LocalStorage.shared.getBlock(number: lightBlock.number) else {
                    fatalError()
                }
                XCTAssertEqual(fetchedBlock, lightBlock)
            } catch {
                fatalError()
            }
        }
        
        /// Fetch the latest block
        do {
            guard let latestBlock = blocks.last else { fatalError() }
            guard let fetchedLatestBlock: FullBlock = try LocalStorage.shared.getLatestBlock() else { fatalError() }
            XCTAssertEqual(fetchedLatestBlock, latestBlock)
            
            guard let latestLightBlock = lightBlocks.last else { fatalError() }
            guard let fetchedLatestLightBlock: LightBlock = try LocalStorage.shared.getLatestBlock() else { fatalError() }
            XCTAssertEqual(fetchedLatestLightBlock, latestLightBlock)
        } catch {
            fatalError()
        }
        
        /// Delete all blocks in Core Data
        LocalStorage.shared.deleteAllBlocks { error in
            if let error = error {
                XCTAssertNil(error)
            }
            
            do {
                let results: [LightBlock] = try LocalStorage.shared.getAllBlocks()
                XCTAssertNil(results)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func test_test() {
        guard let lightBlock = try? LightBlock(data: blocks.first!) else { fatalError() }
        try? LocalStorage.shared.saveBlock(block: lightBlock) { error in
            if let error = error {
                XCTAssertNil(error)
            }
        }
        
        do {
            let allBlocks: [FullBlock] = try LocalStorage.shared.getAllBlocks()
            print("fetched block", allBlocks)
            
            guard let fetchedBlock: FullBlock = try LocalStorage.shared.getBlock(number: lightBlock.number) else {
                fatalError()
            }
            print("fetched block", fetchedBlock)
        } catch {
            print(error)
        }
    }
}
