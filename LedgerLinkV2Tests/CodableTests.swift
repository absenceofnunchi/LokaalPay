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
    let treeConfigurableReceipts = Vectors.treeConfigurableReceipts
    let vectorReceipts = Vectors.receipts
    
    func test_receipts() throws {
        /// full receipt including the contract address.
        for i in 0 ..< treeConfigurableReceipts.count {
            let receipt = treeConfigurableReceipts[i]
            guard let decoded = receipt.decode() else {
                throw NodeError.decodingError
            }
            
            /// Compared the decoded receipts against the original receipts
            let vectorReceipt = vectorReceipts[i]
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
}
