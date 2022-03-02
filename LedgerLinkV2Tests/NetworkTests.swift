//
//  NetworkTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-24.
//

import XCTest
import web3swift
import BigInt
@testable import LedgerLinkV2

final class NetworkTests: XCTestCase {
    
    func test_createNewBlock() {
        Node.shared.deleteAll()
        for i in 0...5 {
            Node.shared.createBlock { (lightBlock: LightBlock) in
                XCTAssertEqual(lightBlock.number, Int32(i + 1))
                
                Node.shared.fetch(lightBlock.id) { (fetchedBlocks: [LightBlock]?, error: NodeError?) in
                    if let error = error {
                        XCTAssertNil(error)
                    }
                    
                    XCTAssertTrue(fetchedBlocks!.count > 0)
                    if let blocks = fetchedBlocks, let block = blocks.first {
                        XCTAssertEqual(block, lightBlock)
                    }
                }
            }
        }
        Node.shared.deleteAll()
    }
    
    /// Attempt to validate a non-signed data. Should fail.
    func test_transactionValidation() {
        let transaction = transactions[0]
        Node.shared.saveSync([transaction]) { error in
            if let error = error {
                XCTAssertNil(error)
            }
            
            guard let rlpData = transaction.encode() else {
                fatalError()
            }
            
            Node.shared.exposeValidateTransaction(rlpData) { result, error in
                if case .generalError(let msg) = error {
                    XCTAssertEqual(msg, "Unable to validate the transaction")
                }
                
                Node.shared.deleteAll()
            }
        }
    }
    
    /// Create a transaction and successfully validate it
    func test_transactionValidation2() {
        let originalSender = addresses[0]
        let transaction = EthereumTransaction(nonce: BigUInt(100), to: originalSender, value: BigUInt(10), data: Data())
        
        KeysService().createNewWallet(password: "1") { (keyWalletModel, error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            guard let keyWalletModel = keyWalletModel else {
                fatalError()
            }
            
            Node.shared.localStorage.saveWallet(wallet: keyWalletModel, completion: { (error) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                do {
                    // Create a public signature
                    let tx = EthereumTransaction.createLocalTransaction(nonce: transaction.nonce, to: transaction.to, value: transaction.value!, data: transaction.data)
                    guard let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: KeysService().keystoreManager(), transaction: tx, from: originalSender, password: "1") else {
                        fatalError("Unable to sign transaction")
                    }
                    
                    guard let encodedSig = signedTx.encode(forSignature: false) else {
                        fatalError("Unable to RLP-encode the signed transaction")
                    }
                    
                    let decoded = EthereumTransaction.fromRaw(encodedSig)
                    guard let publicKey = decoded?.recoverPublicKey() else { return }
                    let senderAddress = Web3.Utils.publicToAddressString(publicKey)
                    XCTAssertEqual(originalSender.address, senderAddress)
                    
                    Node.shared.exposeValidateTransaction(encodedSig) { result, error in
                        if let error = error {
                            fatalError(error.localizedDescription)
                        }
                        
                        guard let fetchedTx = result.0 else {
                            fatalError()
                        }
                        
                        XCTAssertEqual(fetchedTx.nonce, transaction.nonce)
                        XCTAssertEqual(fetchedTx.to, transaction.to)
                        XCTAssertEqual(fetchedTx.value, transaction.value)
                        XCTAssertEqual(fetchedTx.data, transaction.data)
                    }
                } catch {
                    XCTAssertNil(error)
                }
            })
        }
    }
    
    /// Create a transaction and fail to validate due to duplicates
    func test_transactionValidation3() {
        let originalSender = addresses[0]
        let transaction = EthereumTransaction(nonce: BigUInt(100), to: originalSender, value: BigUInt(10), data: Data())
        Node.shared.addValidatedTransaction(transaction) /// Add first to create a duplicate
        
        KeysService().createNewWallet(password: "1") { (keyWalletModel, error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            guard let keyWalletModel = keyWalletModel else {
                fatalError()
            }
            
            Node.shared.localStorage.saveWallet(wallet: keyWalletModel, completion: { (error) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                do {
                    // Create a public signature
                    let tx = EthereumTransaction.createLocalTransaction(nonce: transaction.nonce, to: transaction.to, value: transaction.value!, data: transaction.data)
                    guard let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: KeysService().keystoreManager(), transaction: tx, from: originalSender, password: "1") else {
                        fatalError("Unable to sign transaction")
                    }
                    
                    guard let encodedSig = signedTx.encode(forSignature: false) else {
                        fatalError("Unable to RLP-encode the signed transaction")
                    }
                    
                    let decoded = EthereumTransaction.fromRaw(encodedSig)
                    guard let publicKey = decoded?.recoverPublicKey() else { return }
                    let senderAddress = Web3.Utils.publicToAddressString(publicKey)
                    XCTAssertEqual(originalSender.address, senderAddress)
                    
                    Node.shared.exposeValidateTransaction(encodedSig) { result, error in
                        if let error = error {
                            fatalError(error.localizedDescription)
                        }
                        
                        guard let fetchedTx = result.0 else {
                            fatalError()
                        }
                        
                        XCTAssertEqual(fetchedTx.nonce, transaction.nonce)
                        XCTAssertEqual(fetchedTx.to, transaction.to)
                        XCTAssertEqual(fetchedTx.value, transaction.value)
                        XCTAssertEqual(fetchedTx.data, transaction.data)
                    }
                    
                } catch {
                    fatalError(error.localizedDescription)
                }
            })
        }
    }
    
    func test_test() {
        KeysService().createNewWallet(password: "1") { (keyWalletModel, error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            guard let keyWalletModel = keyWalletModel else {
                fatalError()
            }
         
            print("error", error)
            print("key", keyWalletModel)
        }
    }
}
