//
//  NodeTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-24.
//

import XCTest
import web3swift
import BigInt
import Combine
import MultipeerConnectivity

@testable import LedgerLinkV2

final class NodeTests: XCTestCase {
    var storage = Set<AnyCancellable>()
    
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
            
            Node.shared.fetch(block.hash.toHexString(), completion: { (fetchedBlocks: [FullBlock]?, error: NodeError?) in
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
    
    func test_test1000() {
        let a = [1, 2, 3]
        let p = a.prefix(10)
        print(p)
    }
    
    var retainer: FullBlock!

//    func test_createBlock() {
//        Node.shared.deleteAll()
//        Deferred {
//            Future<Bool, NodeError> { promise in
//                guard let oldBlock = try? FullBlock(number: BigUInt(0), parentHash: binaryHashes[0], transactionsRoot: binaryHashes[0], stateRoot: binaryHashes[0], receiptsRoot: binaryHashes[0], miner: addresses[0].address, transactions: treeConfigurableTransactions, accounts: treeConfigurableAccounts) else { fatalError("blocks vector error") }
//                
//                guard let newBlock = try? FullBlock(number: BigUInt(1), parentHash: oldBlock.hash, transactionsRoot: binaryHashes[0], stateRoot: binaryHashes[0], receiptsRoot: binaryHashes[0], miner: addresses[0].address, transactions: treeConfigurableTransactions, accounts: treeConfigurableAccounts) else { fatalError("blocks vector error") }
//                Node.shared.addUnvalidatedBlock(newBlock)
//
//                Node.shared.saveSync([oldBlock]) { error in
//                    if let error = error {
//                        print("initial error", error as Any)
//                        promise(.failure(error))
//                        return
//                    }
//
//                    promise(.success(true))
//                }
//            }
//            .eraseToAnyPublisher()
//        }
//        .sink { completion in
//            print("completion", completion)
//
//        } receiveValue: { _ in
//            self.createBlock { block in
//                print("final block", block)
//            }
//        }
//        .store(in: &storage)
//    }
    
    func test_createBlock2() {
        Node.shared.mintGenesisBlock { error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            Node.shared.createBlock { block in
                print(block)

                print("unvalid", Node.shared.unvalidatedBlocks)
            }
        }
    }

    
//    func createBlock(completion: @escaping (LightBlock) -> Void) {
//
//        Deferred {
//            /// Select the majority block from a pool of pending blocks
//            Future<FullBlock?, NodeError> { promise in
//                Node.shared.localStorage.getLatestBlock { (lastBlock: FullBlock?, error: NodeError?) in
//                    if let error = error {
//                        promise(.failure(error))
//                        return
//                    }
//
//                    /// No last block exists which means the new block is about to be the genesis block.
//                    guard let lastBlock = lastBlock else {
//                        promise(.success(nil))
//                        return
//                    }
//
//                    /// Select the block from the pool with the most tally
//                    guard let newBlock = Node.shared.unvalidatedBlocks.maxItem() else {
//                        promise(.failure(NodeError.generalError("Unable to determine the new block to be added")))
//                        return
//                    }
//
//                    print("BigUInt(newBlock.number)", BigUInt(newBlock.number))
//                    print("(lastBlock.number + 1)", (lastBlock.number + 1))
//                    print("BigUInt(newBlock.number) == (lastBlock.number + 1)", BigUInt(newBlock.number) == (lastBlock.number + 1))
//                    print("newBlock.parentHash", newBlock.parentHash)
//                    print("lastBlock.hash", lastBlock.hash)
//                    print("(newBlock.parentHash == lastBlock.hash)", (newBlock.parentHash == lastBlock.hash))
//                    if BigUInt(newBlock.number) == (lastBlock.number + 1) && (newBlock.parentHash == lastBlock.hash) {
//                        print("correct block!")
//                        /// The correct block to be saved
//                        /// Save the transactions, accounts, and a block in a relational way
//                        Node.shared.localStorage.saveRelationalBlock(block: newBlock) { error in
//                            if let error = error {
//                                promise(.failure(error))
//                            } else {
//                                promise(.success(newBlock))
//                            }
//                        }
//                    } else {
//                        print("incorrect block!")
//                    }
//                }
//            }
//            .eraseToAnyPublisher()
//        }
//        .flatMap({ (lastBlock) -> AnyPublisher<FullBlock?, NodeError> in
//            Node.shared.unvalidatedBlocks.removeAll()
//
//            /// The newly saved block becomes the last block for the next block.
//            /// Execute all the transactions in order by sorting them by the timestamp first and adding them to a queue
//            return Future<FullBlock?, NodeError> { promise in
//                let sorted = Node.shared.validatedOperations.sorted (by: { $0.timestamp < $1.timestamp })
//                let operations = sorted.compactMap { $0.operation }
//                Node.shared.queue.addOperations(operations, waitUntilFinished: true)
//                Node.shared.validatedOperations.removeAll()
//                promise(.success(lastBlock))
//            }
//            .eraseToAnyPublisher()
//        })
//        .flatMap({ (lastBlock) -> AnyPublisher<LightBlock, NodeError> in
//            Future<LightBlock, NodeError> { promise in
//
//                /// Create the stateRoot and transactionRoot from the validated data using the Merkle tree.
//                let accountArr = Node.shared.validatedAccounts.map { $0.data }
//                let txDataArr = Node.shared.validatedTransactions.map { $0.data }
//
//                do {
//                    /// Use default data if no validated transactions or account exist to create the merkle root hash
//                    let defaultString = "0x0000000000000000000000000000000000000000"
//                    guard let defaultData = defaultString.data(using: .utf8) else {
//                        promise(.failure(NodeError.generalError("Unable to create a new block")))
//                        return
//                    }
//
//                    let accArr = accountArr.count > 0 ? accountArr : [defaultData]
//                    guard case .Node(hash: let stateRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: accArr) else {
//                        fatalError()
//                    }
//
//                    let txArr = txDataArr.count > 0 ? txDataArr : [defaultData]
//                    guard case .Node(hash: let transactionsRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: txArr) else {
//                        fatalError()
//                    }
//
//                    var blockNumber: BigUInt!
//                    var parentHash: Data!
//
//                    /// Use the previous block if it exists
//                    if let lastBlock = lastBlock {
//                        blockNumber = lastBlock.number
//                        parentHash = lastBlock.hash
//                    } else {
//                        /// Last block doesn't exist which means the current block is a genesis block
//                        blockNumber = BigUInt(0)
//                        parentHash = Data()
//                    }
//
//                    print("transactionsRoot", transactionsRoot as Any)
//                    /// Create a new block
//                    let newBlock = try FullBlock(number: blockNumber + 1, parentHash: parentHash, nonce: nil, transactionsRoot: transactionsRoot, stateRoot: stateRoot, receiptsRoot: Data(), extraData: nil, gasLimit: nil, gasUsed: nil, miner: addresses[0].address, transactions: Node.shared.validatedTransactions, accounts: Node.shared.validatedAccounts)
//                    print("newBlock", newBlock as Any)
//                    Node.shared.addUnvalidatedBlock(newBlock)
//                    self.retainer = newBlock
//
//                    let lightBlock = try LightBlock(data: newBlock)
//                    promise(.success(lightBlock))
//                } catch {
//                    promise(.failure(.generalError("Unable to create a new block")))
//                }
//            }
//            .eraseToAnyPublisher()
//        })
//        .sink { completion in
//            switch completion {
//                case .finished:
//                    guard let retainer = self.retainer else {
//                        print("didn't work")
//                        return
//                    }
//                    let int = Node.shared.unvalidatedBlocks[retainer]
//                    print("int-------", int as Any)
//                    print("block created")
//                case .failure(let error):
//                    print("block creation error", error)
//            }
//        } receiveValue: { (block) in
//            Node.shared.validatedTransactions.removeAll()
//            Node.shared.validatedAccounts.removeAll()
//            completion(block)
//        }
//        .store(in: &storage)
//    }
}
