//
//  BlockchainTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-17.
//

import XCTest
import BigInt
import web3swift
import Compression
import Combine
@testable import LedgerLinkV2

final class BlockchainTests: XCTestCase {
//    let binaryHashes = Vectors.binaryHashes
//    let treeConfigTransactions = Vectors.treeConfigurableTransactions
//    let blocks = Vectors.blocks
//    let lightBlocks = Vectors.lightBlocks
//    let mine = Mine()
//
//    func test_blocks() throws {
//        var previousHash = Data()
//        var previousMinedHash = Data()
//        guard let blocks = blocks else { return }
//
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            guard let blockHash = try? block.generateBlockHash() else { return }
//
//            /// Test a block is propoerly instantiated
//            XCTAssertNotNil(blockHash)
//            XCTAssertEqual(blockHash.count, 32)
//            XCTAssertNotEqual(previousHash, blockHash) /// Each blockHash shoud be different
//
//            previousHash = blockHash
//
//            /// Test the codability of the block
//            guard let encoded = try? JSONEncoder().encode(block),
//                  let decoded = try? JSONDecoder().decode(ChainBlock.self, from: encoded) else { return }
//            XCTAssertEqual(decoded, block)
//
//            /// Mining tests
//            guard let hash = try? mine.generate(with: blockHash.toHexString()) else { return }
//            XCTAssertNotNil(hash)
//            XCTAssertNotEqual(previousMinedHash, hash)
//
//            previousMinedHash = hash
//        }
//    }
//
//    func test_light_blocks() throws {
//        var previousHash = Data()
//        var previousMinedHash = Data()
//        guard let blocks = lightBlocks else { return }
//
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//
//            /// Test the codability of the block
//            guard let encoded = try? JSONEncoder().encode(block),
//                  let decoded = try? JSONDecoder().decode(LightBlock.self, from: encoded) else { return }
//            XCTAssertEqual(decoded, block)
//
//            guard let fullBlock = try? JSONDecoder().decode(ChainBlock.self, from: decoded.data),
//                  let blockHash = try? fullBlock.generateBlockHash() else { return }
//
//            /// Test a block is propoerly instantiated
//            XCTAssertNotNil(blockHash)
//            XCTAssertEqual(blockHash.count, 32)
//            XCTAssertNotEqual(previousHash, blockHash) /// Each blockHash shoud be different
//
//            previousHash = blockHash
//
//            /// Mining tests
//            guard let hash = try? mine.generate(with: blockHash.toHexString()) else { return }
//            XCTAssertNotNil(hash)
//            XCTAssertNotEqual(previousMinedHash, hash)
//
//            previousMinedHash = hash
//        }
//    }
//
//    func test_blockchain() {
//        guard let blocks = blocks else { return }
//        var blockchain = Blockchain<ChainBlock>()
//
//        /// Subscript testing
//        blockchain = [blocks[0], blocks[3]]
//        let startIndex = blockchain.startIndex
//        let firstBlock = blockchain[startIndex]
//        XCTAssertEqual(firstBlock, blocks[0])
//        XCTAssertTrue(blockchain.elementsEqual([blocks[0], blocks[3]]))
//
//        blockchain.removeAll()
//
//        /// Append testing
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            blockchain.append(block)
//        }
//
//        /// Collection testing
//        guard let head = blockchain.head,
//              let tail = blockchain.tail else { return }
//        XCTAssertEqual(head.number.description, "0")
//        XCTAssertEqual(tail.number.description, "14")
//        XCTAssertEqual(blockchain.count, 15)
//        XCTAssertFalse(blockchain.isEmpty)
//
//        guard let first = blockchain.popFirst() else { return }
//        XCTAssertEqual(first, blocks[0])
//
//        let filterd = blockchain.filter { $0.number > 10 }
//        XCTAssertFalse(filterd.contains(blocks[2]))
//
//        /// Comparable testing
//        let block1 = blockchain[blockchain.startIndex]
//        let block2 = blockchain[blockchain.index(blockchain.startIndex, offsetBy: 3)]
//        XCTAssertNotEqual(block1, block2)
//
//        let randomIndex = blocks[Int(arc4random_uniform(UInt32(blocks.count)))]
//        let blockchain2: Blockchain<ChainBlock> = [randomIndex, blocks[4]]
//        XCTAssertNotEqual(blockchain, blockchain2)
//
//        var regularTotalSize = 0
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            let size = MemoryLayout.size(ofValue: block)
//            regularTotalSize += size
//        }
//        print("regularTotalSize", regularTotalSize)
//
//        var encodedTotalSize = 0
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            guard let encoded = try? JSONEncoder().encode(block) else { continue }
//            let size = MemoryLayout.size(ofValue: encoded)
//            encodedTotalSize += size
//        }
//        print("encodedTotalSize", encodedTotalSize)
//
//        var rlpTotalSize = 0
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            guard let encoded = try? JSONEncoder().encode(block),
//                  let rlpEncoded = RLP.encode([encoded] as [AnyObject]) else { continue }
//            let size = MemoryLayout.size(ofValue: rlpEncoded)
//            rlpTotalSize += size
//        }
//        print("rlpTotalSize", rlpTotalSize)
//
//        var compressedSize = 0
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            guard let encoded = try? JSONEncoder().encode(block),
//                  let compressed = encoded.compressed else { continue }
//            let size = MemoryLayout.size(ofValue: compressed)
//            compressedSize += size
//        }
//        print("compressedSize", compressedSize as Any)
//
//        var newCompressedSize = 0
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            guard let encoded = try? JSONEncoder().encode(block) else { continue }
//            let compressed = compress(encoded)
//            let size = MemoryLayout.size(ofValue: compressed)
//            newCompressedSize += size
//        }
//        print("newCompressedSize", newCompressedSize as Any)
//    }
//
//    func test_light_blockchain() {
//        guard let blocks = lightBlocks else { return }
//        var blockchain = Blockchain<LightBlock>()
//
//        /// Subscript testing
//        blockchain = [blocks[0], blocks[3]]
//        let startIndex = blockchain.startIndex
//        let firstBlock = blockchain[startIndex]
//        XCTAssertEqual(firstBlock, blocks[0])
//        XCTAssertTrue(blockchain.elementsEqual([blocks[0], blocks[3]]))
//
//        blockchain.removeAll()
//
//        /// Append testing
//        for i in 0 ..< blocks.count {
//            let block = blocks[i]
//            blockchain.append(block)
//        }
//
//        /// Collection testing
//        guard let head = blockchain.head,
//              let tail = blockchain.tail else { return }
//        XCTAssertNotEqual(head.id.toHexString(), tail.id.toHexString())
//        XCTAssertEqual(blockchain.count, 15)
//        XCTAssertFalse(blockchain.isEmpty)
//
//        guard let first = blockchain.popFirst() else { return }
//        XCTAssertEqual(first, blocks[0])
//
//        guard let head = blockchain.head else { return }
//        XCTAssertTrue(blockchain.contains(head))
//
//        /// Comparable testing
//        let block1 = blockchain[blockchain.startIndex]
//        let block2 = blockchain[blockchain.index(blockchain.startIndex, offsetBy: 3)]
//        XCTAssertNotEqual(block1, block2)
//
//        let randomIndex = blocks[Int(arc4random_uniform(UInt32(blocks.count)))]
//        let blockchain2: Blockchain<LightBlock> = [randomIndex, blocks[4]]
//        XCTAssertNotEqual(blockchain, blockchain2)
//
////        var regularTotalSize = Data()
////        for i in 0 ..< blocks.count {
////            let block = blocks[i]
////            let size = MemoryLayout.size(ofValue: block)
////            regularTotalSize.append(block)
////        }
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
//    }
//
//    func test_core_data() throws {
//        guard let lightBlocks = lightBlocks else {
//            return
//        }
//
//        for lightBlock in lightBlocks {
//            let blockModel = BlockModel(id: lightBlock.id, number: lightBlock.number, data: lightBlock.data)
//            try LocalStorage.shared.saveBlock(block: blockModel) { error in
//                if let error = error {
//                    print(error)
//                }
//
//                guard let block: LightBlock = try LocalStorage.shared.getBlock(id: lightBlock.id) else { return }
//                print("block", block as Any)
//            }
//        }
//
//        for lightBlock in lightBlocks {
//            guard let block: LightBlock = try LocalStorage.shared.getBlock(id: lightBlock.id) else { return }
//            print("block", block as Any)
//            XCTAssertEqual(lightBlock, block)
//        }
//    }
//
//    func compress(_ sourceData: Data) -> Data {
//        let pageSize = 128
//        var compressedData = Data()
//
//        do {
//            let outputFilter = try OutputFilter(.compress, using: .lzfse) { (data: Data?) -> Void in
//                if let data = data {
//                    compressedData.append(data)
//                }
//            }
//
//            var index = 0
//            let bufferSize = sourceData.count
//
//            while true {
//                let rangeLength = min(pageSize, bufferSize - index)
//
//                let subdata = sourceData.subdata(in: index ..< index + rangeLength)
//                index += rangeLength
//
//                try outputFilter.write(subdata)
//
//                if (rangeLength == 0) {
//                    break
//                }
//            }
//        }catch {
//            fatalError("Error occurred during encoding: \(error.localizedDescription).")
//        }
//
//        return compressedData
//    }

    
    func test_test() {
        let account = Account(address: EthereumAddress("0x139b782cE2da824b98b6Af358f725259799D2f74")!, nonce: BigUInt(10))
        guard let encoded = account.encode() else {
            print("encoded error")
            return
        }
        print("encoded", encoded)
        
        guard let compressed = encoded.compressed else {
            print("compressed error")
            return
        }
        
        guard let decompressed = compressed.decompressed else {
            print("decompress error")
            return
        }
        
        guard let decoded = Account.fromRaw(decompressed) else {
            print("decode error")
            return
        }
        
        print("decoded", decoded)
    }
    
    var storage = Set<AnyCancellable>()
    func test_speed() {
        let hash = "0xfFbb73852d9DA0DF8a9ecEbB85e896fd1e7D51Ec"
        guard let converted = hash.data(using: .utf8) else { return }
        let hashData = converted.sha256()
        guard let address = EthereumAddress(hash) else { return }
        let tx = EthereumTransaction(gasPrice: BigUInt(10), gasLimit: BigUInt(10), to: address, value: BigUInt(10), data: Data())
        guard let treeConfigTx = try? TreeConfigurableTransaction(data: tx) else { return }
        guard let block = try? ChainBlock(number: BigUInt(10), parentHash: hashData, transactionsRoot: hashData, stateRoot: hashData, receiptsRoot: hashData, transactions: [treeConfigTx]) else { return }
        let blockSize = MemoryLayout.size(ofValue: block)
        print("blockSize", blockSize)
        
        guard let lightBlock = try? LightBlock(data: block) else { return }
        Deferred {
            Future<Bool, NodeError> { promise in
                let blockModel = BlockModel(id: lightBlock.id, number: lightBlock.number, data: lightBlock.data)
                try? LocalStorage.shared.saveBlock(block: blockModel) { error in
                    if let error = error {
                        print(error)
                        promise(.failure(.generalError("error")))
                    }
                    print("saved")
                    promise(.success(true))
                    
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap { _ in
            Future<Bool, NodeError> { promise in
                print("wait")
                let _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Hello World!")], timeout: 2.0)
                promise(.success(true))
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    promise(.success(true))
//                }
            }
            .eraseToAnyPublisher()
        }
        .sink { completion in
            switch completion {
                case .finished:
                    print("finsihed")
                    break
                case .failure:
                    print("failed")
                    break
            }
        } receiveValue: { _ in
            print("getblock")
            do {
                guard let block: ChainBlock = try LocalStorage.shared.getBlock(id: lightBlock.id) else {
                    print("LocalStorage.shared.getBlock")
                    return
                }
                print("block", block as Any)
            } catch {
                print(error)
            }
        }
        .store(in: &storage)
        
//        guard let encoded1 = try? JSONEncoder().encode(block) else { return }
//        print("simple encoded", encoded1)
//        let blockSize1 = MemoryLayout.size(ofValue: encoded1)
//        print("MemoryLayout", blockSize1)
//        
//        guard let block2 = try? ChainBlock(number: BigUInt(10), parentHash: hashData, transactionsRoot: hashData, stateRoot: hashData, receiptsRoot: hashData, transactions: [treeConfigTx]) else { return }
//        guard let encoded2 = try? JSONEncoder().encode(block2) else { return }
//        guard let rlpEncoded = RLP.encode([encoded2 as AnyObject]) else { return }
//        print("rlpEncoded", rlpEncoded)
//        let blockSize2 = MemoryLayout.size(ofValue: rlpEncoded)
//        print("MemoryLayout", blockSize2)
//        
//        guard let block3 = try? ChainBlock(number: BigUInt(10), parentHash: hashData, transactionsRoot: hashData, stateRoot: hashData, receiptsRoot: hashData, transactions: [treeConfigTx]) else { return }
//        guard let encoded3 = try? JSONEncoder().encode(block3) else { return }
//        guard let compressed = encoded3.compressed else { return }
//        print("compressed", compressed)
//        let blockSize3 = MemoryLayout.size(ofValue: compressed)
//        print("MemoryLayout", blockSize3)
//        
//        var regularBlockArray = [ChainBlock]()
//        for _ in 0 ... 20 {
//            guard let block = try? ChainBlock(number: BigUInt(10), parentHash: hashData, transactionsRoot: hashData, stateRoot: hashData, receiptsRoot: hashData, transactions: [treeConfigTx]) else { return }
//            regularBlockArray.append(block)
//        }
//        guard let encodedRegularArr = try? JSONEncoder().encode(regularBlockArray) else { return }
//        print("encodedRegularArr", encodedRegularArr)
//        
//        var compressedArray = [Data]()
//        for _ in 0 ... 20 {
//            guard let block = try? ChainBlock(number: BigUInt(10), parentHash: hashData, transactionsRoot: hashData, stateRoot: hashData, receiptsRoot: hashData, transactions: [treeConfigTx]) else { return }
//            guard let encodedArr = try? JSONEncoder().encode(block) else { return }
//            guard let compressedArr = encodedArr.compressed else { return }
//            compressedArray.append(compressedArr)
//        }
//        print("compressedArray", compressedArray)
//        guard let encodedCompressedArr = try? JSONEncoder().encode(compressedArray) else { return }
//        print("encodedCompressedArr", encodedCompressedArr)
    }
}

extension Array {
    func asData() -> NSData {
        return self.withUnsafeBufferPointer({
            NSData(bytes: $0.baseAddress, length: count * MemoryLayout.stride(ofValue: Element.self))
        })
    }
}
