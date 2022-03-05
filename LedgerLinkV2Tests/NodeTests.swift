//
//  NodeTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-24.
//

import XCTest
import web3swift
import BigInt

@testable import LedgerLinkV2

final class NodeTests: XCTestCase {

    func test_createNewBlock() {
        Node.shared.deleteAll()
        for i in 0...5 {
            Node.shared.createBlock { (lightBlock: LightBlock) in
                XCTAssertEqual(lightBlock.number, Int32(i + 1))
                
                Node.shared.fetch(.lightBlockId(lightBlock.id)) { (fetchedBlocks: [LightBlock]?, error: NodeError?) in
                    if let error = error {
                        XCTAssertNil(error)
                    }
                    
                    XCTAssertTrue(fetchedBlocks!.count > 0)
                    if let blocks = fetchedBlocks, let block = blocks.first {
                        print("block", block as Any)
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
                    let tx = EthereumTransaction.createLocalTransaction(nonce: transaction.nonce, to: transaction.to, value: transaction.value!, data: transaction.data, chainID: BigUInt(11111))
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
                        
                        print("fetchedTx.nonce", fetchedTx.nonce)
                        print("transaction.nonce", transaction.nonce)
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
                    let tx = EthereumTransaction.createLocalTransaction(nonce: transaction.nonce, to: transaction.to, value: transaction.value!, data: transaction.data, chainID: BigUInt(11111))
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
    
    func test_test20() {
        
        let accountCreationTx = Vectors.accountCreationTx
        guard let data = accountCreationTx?.encode() else { return }
        let method = ContractMethod.createAccount(data)
        guard let encoded = try? JSONEncoder().encode(method) else { return }
        guard let decoded = try? JSONDecoder().decode(ContractMethod.self, from: encoded) else { return }
        guard case .createAccount(let data) = decoded else { return }
        
        Node.shared.exposeValidateTransaction(data) { result, error in
            if let error = error {
                print(error)
                fatalError(error.localizedDescription)
            }
            
            print("result", result)
        }

        let operation = Node.shared.validatedOperations
        let account = Node.shared.validatedAccounts
        print("operation", operation)
        print("account", account)
    }
    
    func test_test30() {
        
        Node.shared.localStorage.getLatestBlock { (block: LightBlock?, error: NodeError?) in
            if let error = error {
                print(error)
                fatalError(error.localizedDescription)
            }
            
            if let block = block {
                print(block)
                
                do {
                    /// local blockchain may or may not exists
                    let blockNumber = Int32(block.number)
                    let contractMethod = ContractMethod.blockchainDownloadRequest(blockNumber)
                    let data = try JSONEncoder().encode(contractMethod)
                    print("data", data)
//                    self.sendData(data: data, peers: peerIDs, mode: .reliable)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func test_multSet() {
        var multiSet = Multiset<FullBlock>()
        multiSet.add(blocks[0])
        multiSet.add(blocks[1])
        multiSet.add(blocks[2])
        multiSet.add(blocks[3])
        
        XCTAssertEqual(multiSet.count, 4)
        XCTAssertEqual(multiSet.allItems.count, 4)
        
        /// Check that each item's count is 1
        for item in multiSet.allItems {
            XCTAssertEqual(multiSet.count(for: item), 1)
        }
        
        /// Check that an item is properly removed
        multiSet.remove(blocks[0])
        XCTAssertEqual(multiSet.count, 3)
        XCTAssertEqual(multiSet.allItems.count, 3)
        
        /// check that adding a block from the same miner and same number is prevented
        multiSet.add(blocks[1])
        XCTAssertEqual(multiSet.count, 3)
        XCTAssertEqual(multiSet.allItems.count, 3)
        XCTAssertEqual(multiSet.count(for: blocks[1]), 1)
        
        /// check that adding a block with the same number, but with a different miner is treated like a different block
        var newBlock = blocks[1]
        newBlock.miner = "Different miner"
        multiSet.add(newBlock)
        XCTAssertEqual(multiSet.count, 4)
        XCTAssertEqual(multiSet.allItems.count, 4)
        XCTAssertEqual(multiSet.count(for: blocks[1]), 2)
        
        let maxItem = multiSet.maxItem()
        XCTAssertEqual(maxItem, blocks[1])
    }
    
    func test_relationalSave() {
        for block in blocks {
            relationalSave(block)
        }
    }
    
    func relationalSave(_ block: FullBlock) {
        Node.shared.deleteAll()
        Node.shared.localStorage.saveRelationalBlock(block: block) { error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            Node.shared.fetch(.lightBlockId(block.hash.toHexString()), completion: { (fetchedBlocks: [FullBlock]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                /// Confirm that the block has indeed been saved
                if let fetchedBlocks = fetchedBlocks, let fetchedBlock = fetchedBlocks.first {
                    XCTAssertEqual(block, fetchedBlock)
                }
                
                Node.shared.localStorage.getAllTransactionsAsync { (fetchedTxs: [TreeConfigurableTransaction]?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                    
                    XCTAssertNotNil(fetchedTxs)
                    if let fetchedTxs = fetchedTxs {
                        XCTAssertEqual(fetchedTxs, block.transactions)
                    }
                }
                
                let fetchedAccts: [TreeConfigurableAccount]? = try? Node.shared.localStorage.getAllAccounts()
                XCTAssertEqual(block.accounts, fetchedAccts)
                
                Node.shared.fetch { (accts: [TreeConfigurableAccount]?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                    
                    if let accts = accts {
                        XCTAssertEqual(block.accounts, accts)
                    }
                }
            })
        }
    }
    
    func test_verify_blocks() {
        guard let genesisBlock = try? FullBlock(number: BigUInt(0), parentHash: binaryHashes[0], transactionsRoot: binaryHashes[0], stateRoot: binaryHashes[0], receiptsRoot: binaryHashes[0], miner: addresses[0].address, transactions: treeConfigurableTransactions, accounts: treeConfigurableAccounts) else { fatalError("blocks vector error") }
        
        guard let newBlock = try? FullBlock(number: BigUInt(1), parentHash: genesisBlock.hash, transactionsRoot: binaryHashes[0], stateRoot: binaryHashes[0], receiptsRoot: binaryHashes[0], miner: addresses[0].address, transactions: treeConfigurableTransactions, accounts: treeConfigurableAccounts) else { fatalError("blocks vector error") }
        
        /// Save the genesis block
        Node.shared.saveSync([genesisBlock]) { error in
            if let error = error {
                print(error as Any)
                fatalError(error.localizedDescription)
            }
            
            /// Add the new block to the unvalidated pool
            Node.shared.addUnvalidatedBlock(newBlock)
            
            /// Verify the new block
            Node.shared.verifyBlock()
        }
        
        guard let lightNode0 = try? LightBlock(data: genesisBlock),
              let lightNode1 = try? LightBlock(data: newBlock) else {
            return
        }
        
        let isValid = Node.shared.isBlockchainValid([lightNode0, lightNode1])
        print("isValid", isValid)
    }
    
    func test_fetch() {
        Node.shared.saveSync([transactions[0]]) { error in
            if let error = error {
                print(error)
                fatalError()
            }
            
            Node.shared.fetch(.treeConfigTxId(transactions[0].hash!.toHexString())) { (results: [EthereumTransaction]?, error: NodeError?) in
                if let error = error {
                    print(error)
                    fatalError()
                }
                
                if let results = results {
                    print(results)
                }
            }
        }
    }
    
    func test_test() {
        var sortedBlocks = lightBlocks
        quicksortDutchFlag(&sortedBlocks, low: 0, high: blocks.count - 1)
        print(sortedBlocks)
    }
    
    func test_get() {
        verifyValidator { isTrue in
            print(isTrue)
        }
    }
    
    func verifyValidator(completion: @escaping (Bool) -> Void) {
        guard let genesisBlock = try? FullBlock(number: BigUInt(0), parentHash: binaryHashes[0], transactionsRoot: binaryHashes[0], stateRoot: binaryHashes[0], receiptsRoot: binaryHashes[0], miner: addresses[0].address, transactions: treeConfigurableTransactions, accounts: treeConfigurableAccounts) else { fatalError("blocks vector error") }
        
        /// Get the genesis block
        try! Node.shared.localStorage.saveBlock(block: genesisBlock) { error in
            if let error = error {
                print(error)
            }
            
            Node.shared.localStorage.getBlock(Int32(0)) { block, error in
                if let error = error {
                    print(error as Any)
                    completion(false)
                    return
                }
                
                if let block = block {
                    print(block)
                }
            }
            
//            Node.shared.localStorage.getBlock(from: Int32(0), format: "number == %i") { (blocks: FullBlock?, error: NodeError?) in
//                if let error = error {
//                    print(error as Any)
//                    completion(false)
//                    return
//                }
//
//                print("blocks", blocks as Any)
//
//                guard let blocks = blocks, let genesisBlock = blocks.first else {
//                    completion(false)
//                    return
//                }
//
//                print("genesisBlock", genesisBlock)
//                completion(true)
//            }
        }
    }
    
    func test_100() {
        let address = EthereumAddress("0x18cD9fDa7d584401D04E30bf73FB0013EfE65bb0")!
        var tx = EthereumTransaction(nonce: BigUInt(0), to: address, value: BigUInt(100), data: Data())
        tx.UNSAFE_setChainID(BigUInt(111111))
        
        print(tx.intrinsicChainID)
    }
}
