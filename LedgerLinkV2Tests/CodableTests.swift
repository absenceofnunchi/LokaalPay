//
//  CodableTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-14.
//

import XCTest
import web3swift
import BigInt
@testable import LedgerLinkV2

class CodableTests: XCTestCase {
    func test_receipts() throws {
        /// full receipt including the contract address.
        for i in 0 ..< treeConfigurableReceipts.count {
            let receipt = treeConfigurableReceipts[i]
            guard let decoded = receipt.decode() else {
                throw NodeError.decodingError
            }
            
            /// Compared the decoded receipts against the original receipts
            let vectorReceipt = receipts[i]
            XCTAssertEqual(decoded.blockHash, vectorReceipt.blockHash)
            XCTAssertEqual(decoded.blockNumber, vectorReceipt.blockNumber)
            XCTAssertEqual(decoded.transactionHash, vectorReceipt.transactionHash)
            XCTAssertEqual(decoded.contractAddress, vectorReceipt.contractAddress)
            XCTAssertEqual(decoded.cumulativeGasUsed, vectorReceipt.cumulativeGasUsed)
            XCTAssertEqual(decoded.gasUsed, vectorReceipt.gasUsed)
        }
        
        /// partical receipts excluding the contract address
        var originalReceiptArr = [TransactionReceipt]()
        var encodedArr = [Data]()
        let binaryHashes = Vectors.binaryHashes
        for i in 0 ..< binaryHashes.count {
            let receipt = TransactionReceipt(transactionHash: binaryHashes[i], blockHash: Data(), blockNumber: BigUInt(i), transactionIndex: BigUInt(i), contractAddress: nil, cumulativeGasUsed: BigUInt(i), gasUsed: BigUInt(i), logs: [EventLog](), status: .ok, logsBloom: nil)

            originalReceiptArr.append(receipt)
            guard let encoded = receipt.encode() else {
                throw NodeError.encodingError
            }
            encodedArr.append(encoded)
        }
        
        for i in 0 ..< encodedArr.count {
            guard let decoded = try TransactionReceipt.fromRaw(encodedArr[i]) else {
                throw NodeError.decodingError
            }
            
            let originalReceipt = originalReceiptArr[i]
            XCTAssertEqual(decoded.blockHash, originalReceipt.blockHash)
            XCTAssertEqual(decoded.blockNumber, originalReceipt.blockNumber)
            XCTAssertEqual(decoded.transactionHash, originalReceipt.transactionHash)
            XCTAssertEqual(decoded.contractAddress, originalReceipt.contractAddress)
            XCTAssertEqual(decoded.cumulativeGasUsed, originalReceipt.cumulativeGasUsed)
            XCTAssertEqual(decoded.gasUsed, originalReceipt.gasUsed)
        }
    }
    
    /// Test with a minimal initializer since it makes a difference to RLP encoding/decoding
    func test_single_account() {
        let account = Account(address: EthereumAddress("0x139b782cE2da824b98b6Af358f725259799D2f74")!, nonce: BigUInt(10))
        guard let encodedAccount = account.encode() else { fatalError("account encoding error")}
        guard let compressed = encodedAccount.compressed else { fatalError("compression error")}
        guard let decompressed = compressed.decompressed else { fatalError("decompression error")}
        guard let decoded = Account.fromRaw(decompressed) else { fatalError("decoded error")}
        guard let treeConfig = try? TreeConfigurableAccount(data: account) else { fatalError("treeConfig error") }
        guard let originalAccount = treeConfig.decode() else { fatalError("decode error") }

        XCTAssertEqual(account, decoded)
        XCTAssertEqual(account, originalAccount)
        XCTAssertEqual(decoded, originalAccount)
    }
    
    func test_accounts() {
        for i in 0 ..< accounts.count {
            let account = accounts[i]
            guard let encodedAccount = account.encode() else { fatalError("account encoding error")}
            guard let compressed = encodedAccount.compressed else { fatalError("compression error")}
            guard let decompressed = compressed.decompressed else { fatalError("decompression error")}
            guard let decoded = Account.fromRaw(decompressed) else { fatalError("decoded error")}
            guard let treeConfig = try? TreeConfigurableAccount(data: account) else { fatalError("treeConfig error") }
            guard let originalAccount = treeConfig.decode() else { fatalError("decode error") }
            
            XCTAssertEqual(account, decoded)
            XCTAssertEqual(account, originalAccount)
            XCTAssertEqual(decoded, originalAccount)
        }
    }
    
    func test_transactions() {
        for i in 0 ..< transactions.count {
            let transaction = transactions[i]
            guard let encoded = transaction.encode() else { fatalError("account encoding error")}
            guard let compressed = encoded.compressed else { fatalError("compression error")}
            guard let decompressed = compressed.decompressed else { fatalError("decompression error")}
            guard let decoded = EthereumTransaction.fromRaw(decompressed) else { fatalError("decoded error")}
            guard let treeConfig = try? TreeConfigurableTransaction(data: transaction) else { fatalError("treeConfig error") }
            guard let originalTransaction = treeConfig.decode() else { fatalError("decode error") }
            
            XCTAssertEqual(transaction.nonce, decoded.nonce)
            XCTAssertEqual(transaction.gasLimit, decoded.gasLimit)
            XCTAssertEqual(transaction.gasPrice, decoded.gasPrice)
            XCTAssertEqual(transaction.value, decoded.value)
            XCTAssertEqual(transaction.to, decoded.to)
            
            XCTAssertEqual(transaction.nonce, originalTransaction.nonce)
            XCTAssertEqual(transaction.gasLimit, originalTransaction.gasLimit)
            XCTAssertEqual(transaction.gasPrice, originalTransaction.gasPrice)
            XCTAssertEqual(transaction.value, originalTransaction.value)
            XCTAssertEqual(transaction.to, originalTransaction.to)
        }
    }
    
    func test_blocks() {
        for block in blocks {
            var encoded: Data
            do {
                encoded = try JSONEncoder().encode(block)
            } catch {
                fatalError("encoding error")
            }
            
            guard let compressed = encoded.compressed else { fatalError("compression error") }
            guard let decompressed = compressed.decompressed else { fatalError("decompression error") }
            
            var decoded: FullBlock
            do {
                decoded = try JSONDecoder().decode(FullBlock.self, from: decompressed)
            } catch {
                fatalError("decoding error")
            }
  
            XCTAssertEqual(decoded.number, block.number)
            XCTAssertEqual(decoded.hash, block.hash)
            XCTAssertEqual(decoded.parentHash, block.parentHash)
            XCTAssertEqual(decoded.nonce, block.nonce)
            XCTAssertEqual(decoded.transactionsRoot, block.transactionsRoot)
            XCTAssertEqual(decoded.stateRoot, block.stateRoot)
            XCTAssertEqual(decoded.receiptsRoot, block.receiptsRoot)
            XCTAssertEqual(decoded.size, block.size)
            XCTAssertTrue(abs(decoded.timestamp.timeIntervalSince(block.timestamp)) < 1)
            XCTAssertEqual(decoded.transactions, block.transactions)
            XCTAssertEqual(decoded, block)
        }
    }
}
