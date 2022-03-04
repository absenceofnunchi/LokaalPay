//
//  Node+CreateBlock.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-03.
//

import Foundation
import Combine
import BigInt

extension Node {
    /// Creating a block requires multiple steps.
    /// Process the last block by choosing one from the pool.
    
    func doBlock() {
        verifyValidator { isValidator in
            if isValidator {
                
            } else {
                
            }
        }
    }
    
    func verifyValidator(completion: @escaping (Bool) -> Void) {
        /// Get the genesis block
        Node.shared.localStorage.getBlocks(from: Int32(0), format: "number == %i") { (blocks: [FullBlock]?, error: NodeError?) in
            if let error = error {
                print(error as Any)
                completion(false)
                return
            }
            
            guard let blocks = blocks, let genesisBlock = blocks.first else {
                completion(false)
                return
            }
            
            Node.shared.getMyAccount { account, error in
                if let error = error {
                    print(error as Any)
                    completion(false)
                    return
                }
                
                if let myAddressString = account?.address.address, myAddressString == genesisBlock.miner {
                    /// If my address matches the miner of the genesis block, it means I'm the host/validator.
                    /// Proceed to mint a new block
                    
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    /// The validator/host of the blockchain executes the transactions and creates a new block to be propagated.
    func createBlock(completion: @escaping (LightBlock) -> Void) {
        
        Deferred {
            /// Execute all the pending transactions in the pool of validated operations in order by sorting them according to the timestamp first and adding them to a queue
            /// Validated operations simply mean transactions that have been validated through verifying the public signature and then wrapping them in the asynchronous Operation.
            Future<Bool, NodeError> { [weak self] promise in
                guard let sorted = self?.validatedOperations.sorted (by: { $0.timestamp < $1.timestamp }) else {
                    promise(.failure(.generalError("Unable to sort the timestamped operations")))
                    return
                }
                let operations = sorted.compactMap { $0.operation }
                self?.queue.addOperations(operations, waitUntilFinished: true)
                /// Remove all the transactions from the pool of validated operations once they're executed.
                self?.validatedOperations.removeAll()
                promise(.success(true))
            }
        }
        .flatMap({ [weak self] (lastBlock) -> AnyPublisher<LightBlock, NodeError> in
            Future<LightBlock, NodeError> { promise in
                guard let self = self else {
                    promise(.failure(NodeError.generalError("Unable to create a new block")))
                    return
                }
                
                /// Create the stateRoot and transactionRoot from the validated accounts and transactions respectively using the Merkle tree.
                /// Validated accounts mean they have been verfiied through public signature and then necessary updates have been made such a new account creation or a value transfer (TreeConfiguredAccount).
                /// Validated transaactions mean they have been verified through public signature and then executed (TreeConfiguredTransaction).
                /// The difference between validated transactions and validate operations is that the latter have been wrapped in Operation to be executed in order.
                /// Former is the pure transaction structure to be added to the new block.
                let accountArr = self.validatedAccounts.map { $0.data }
                let txDataArr = self.validatedTransactions.map { $0.data }
                
                /// Fetch your own account to register yourself as the miner of the block.
                self.getMyAccount { account, error in
                    if let error = error {
                        promise(.failure(error))
                    }
                    
                    guard let account = account else {
                        return
                    }
                    
                    do {
                        /// Use default data if no validated transactions or account exist to create the merkle root hash
                        let defaultString = "0x0000000000000000000000000000000000000000"
                        guard let defaultData = defaultString.data(using: .utf8) else {
                            promise(.failure(NodeError.generalError("Unable to create a new block")))
                            return
                        }
                        
                        /// Create a state root hash
                        let accArr = accountArr.count > 0 ? accountArr : [defaultData]
                        guard case .Node(hash: let stateRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: accArr) else {
                            fatalError()
                        }
                        
                        /// Create a transaction root hash
                        let txArr = txDataArr.count > 0 ? txDataArr : [defaultData]
                        guard case .Node(hash: let transactionsRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: txArr) else {
                            fatalError()
                        }
                        
                        /// Fetch the last block to increment the block number and to register the block hash as the parent hash of the new block.
                        guard let fetchedBlock: LightBlock = try Node.shared.localStorage.getLastestBlockSync(),
                              let lastBlock = fetchedBlock.decode() else {
                            promise(.failure(.generalError("Unable to fetch the latsest block")))
                            return
                        }
                        
                        let blockNumber = lastBlock.number
                        let parentHash = lastBlock.hash
                        
                        /// Create a new block
                        let newBlock = try FullBlock(number: blockNumber + 1, parentHash: parentHash, nonce: nil, transactionsRoot: transactionsRoot, stateRoot: stateRoot, receiptsRoot: Data(), extraData: nil, gasLimit: nil, gasUsed: nil, miner: account.address.address, transactions: self.validatedTransactions, accounts: self.validatedAccounts)
                        
                        /// The newly created block becomes the unvalidated block to be sent out and be verified next against a pool of other candidates on the next clock cycle.
                        self.addUnvalidatedBlock(newBlock)
                        
                        let lightBlock = try LightBlock(data: newBlock)
                        promise(.success(lightBlock))
                        
                    } catch {
                        promise(.failure(.generalError("Unable to create a new block")))
                    }
                }
            }
            .eraseToAnyPublisher()
        })
        .sink { completion in
            switch completion {
                case .finished:
                    print("block created")
                case .failure(let error):
                    print("block creation error", error)
            }
        } receiveValue: { [weak self] (block) in
            self?.validatedTransactions.removeAll()
            self?.validatedAccounts.removeAll()
            completion(block)
        }
        .store(in: &storage)
    }
    
    
    func verifyBlock() {
        
    }
    
    func createBlock1(completion: @escaping (LightBlock) -> Void) {
        
        Deferred {
            /// Select the majority block from a pool of pending blocks
            Future<FullBlock?, NodeError> { [weak self] promise in
                /// Select the new block from the pool of unvalidated blocks with the most tally.  There should be at least one block created locally
                print("self?.unvalidatedBlocks", self?.unvalidatedBlocks)
                guard let newBlock = self?.unvalidatedBlocks.maxItem() else {
                    promise(.failure(NodeError.generalError("Unable to determine the new block to be added")))
                    return
                }
                
                let blockNumber = Int32(newBlock.number - 1)
                Node.shared.localStorage.getBlocks(from: blockNumber, format: "number == %i") { (lastBlocks: [FullBlock]?, error: NodeError?) in
                    if let error = error {
                        print("fetch error", error)
                        promise(.failure(.generalError("Unable to fetch last block")))
                    }
                    
                    if let lastBlocks = lastBlocks {
                        for lastBlock in lastBlocks {
                            print("newBlock.number", newBlock.number)
                            print("lastBlock.number", lastBlock.number)
                            print("newBlock.parentHash", newBlock.parentHash)
                            print("lastBlock.hash", lastBlock.hash)
                            
                            print("unvalidatedBlocks", self?.unvalidatedBlocks as Any)
                            print("newBlock.number == (lastBlock.number + 1))", newBlock.number == (lastBlock.number + 1))
                            print("(newBlock.parentHash == lastBlock.hash)", (newBlock.parentHash == lastBlock.hash))
                            print("newBlock.parentHash", newBlock.parentHash.toHexString())
                            print("lastBlock.hash", lastBlock.hash.toHexString())
                            
                            if newBlock.parentHash == lastBlock.hash {
                                /// Correct block to be saved
                                /// Save the transactions, accounts, and a block in a relational way
                                Node.shared.localStorage.saveRelationalBlock(block: newBlock) { error in
                                    /// Now that a valid block has been selected remove all old blocks
                                    self?.clearUnvalidatedBlocks()
                                    
                                    if let error = error {
                                        promise(.failure(error))
                                    } else {
                                        promise(.success(newBlock))
                                    }
                                    return
                                }
                            }
                        }
                    }
                    /// We could send a request for a specific block that meets the predicate, i.e. a block whose hash matches the parent hash of the new block.
                    /// This request could search Core Data of peers and upon locating the specific block, we could fetch only the blocks from that point onward.
                    /// This obviates the need to fetch the entire blockchain.
                    /// If the specific block is not located, then fetch the entire blockchain as as last resort.                    
                    NetworkManager.shared.requestBlockchainFromAllPeers(upto: 1) { error in
                        if let error = error {
                            print("request all error", error)
                            promise(.failure(error))
                        } else {
                            promise(.failure(.generalError("Incorrect block")))
                        }
                    }
                }
            }
        }
        .flatMap({ (lastBlock) -> AnyPublisher<FullBlock?, NodeError> in
            /// The newly saved block becomes the last block for the next block.
            /// Execute all the pending transactions in the pool of validated operations in order by sorting them according to the timestamp first and adding them to a queue
            /// Validated operations simply mean transactions that have been validated through verifying the public signature and then wrapping them in the asynchronous Operation.
            return Future<FullBlock?, NodeError> { [weak self] promise in
                guard let sorted = self?.validatedOperations.sorted (by: { $0.timestamp < $1.timestamp }) else {
                    promise(.failure(.generalError("Unable to sort the timestamped operations")))
                    return
                }
                let operations = sorted.compactMap { $0.operation }
                self?.queue.addOperations(operations, waitUntilFinished: true)
                /// Remove all the transactions from the pool of validated operations once they're executed.
                self?.validatedOperations.removeAll()
                promise(.success(lastBlock))
            }
            .eraseToAnyPublisher()
        })
        .flatMap({ [weak self] (lastBlock) -> AnyPublisher<LightBlock, NodeError> in
            Future<LightBlock, NodeError> { promise in
                guard let self = self else {
                    promise(.failure(NodeError.generalError("Unable to create a new block")))
                    return
                }
                
                /// Create the stateRoot and transactionRoot from the validated accounts and transactions respectively using the Merkle tree.
                /// Validated accounts mean they have been verfiied through public signature and then necessary updates have been made such a new account creation or a value transfer (TreeConfiguredAccount).
                /// Validated transaactions mean they have been verified through public signature and then executed (TreeConfiguredTransaction).
                /// The difference between validated transactions and validate operations is that the latter have been wrapped in Operation to be executed in order.
                /// Former is the pure transaction structure to be added to the new block.
                let accountArr = self.validatedAccounts.map { $0.data }
                let txDataArr = self.validatedTransactions.map { $0.data }
                
                /// Fetch your own account to register yourself as the miner of the block.
                /// This is important in order to prevent duplicate transactions sent by the same miner in the pool of unvalidated blocks.
                self.getMyAccount { account, error in
                    if let error = error {
                        promise(.failure(error))
                    }
                    
                    guard let account = account else {
                        return
                    }
                    
                    do {
                        /// Use default data if no validated transactions or account exist to create the merkle root hash
                        let defaultString = "0x0000000000000000000000000000000000000000"
                        guard let defaultData = defaultString.data(using: .utf8) else {
                            promise(.failure(NodeError.generalError("Unable to create a new block")))
                            return
                        }
                        
                        /// Create a state root hash
                        let accArr = accountArr.count > 0 ? accountArr : [defaultData]
                        guard case .Node(hash: let stateRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: accArr) else {
                            fatalError()
                        }
                        
                        /// Create a transaction root hash
                        let txArr = txDataArr.count > 0 ? txDataArr : [defaultData]
                        guard case .Node(hash: let transactionsRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: txArr) else {
                            fatalError()
                        }
                        
                        var blockNumber: BigUInt!
                        var parentHash: Data!
                        
                        /// Use the previous block if it exists
                        if let lastBlock = lastBlock {
                            blockNumber = lastBlock.number
                            parentHash = lastBlock.hash
                        } else {
                            /// Last block doesn't exist which means the current block is a genesis block
                            blockNumber = BigUInt(0)
                            parentHash = Data()
                        }
                        
                        /// Create a new block
                        let newBlock = try FullBlock(number: blockNumber + 1, parentHash: parentHash, nonce: nil, transactionsRoot: transactionsRoot, stateRoot: stateRoot, receiptsRoot: Data(), extraData: nil, gasLimit: nil, gasUsed: nil, miner: account.address.address, transactions: self.validatedTransactions, accounts: self.validatedAccounts)
                        
                        /// The newly created block becomes the unvalidated block to be sent out and be verified next against a pool of other candidates on the next clock cycle.
                        self.addUnvalidatedBlock(newBlock)
                        
                        let lightBlock = try LightBlock(data: newBlock)
                        promise(.success(lightBlock))
                        
                    } catch {
                        promise(.failure(.generalError("Unable to create a new block")))
                    }
                }
            }
            .eraseToAnyPublisher()
        })
        .sink { completion in
            switch completion {
                case .finished:
                    print("block created")
                case .failure(let error):
                    print("block creation error", error)
            }
        } receiveValue: { [weak self] (block) in
            self?.validatedTransactions.removeAll()
            self?.validatedAccounts.removeAll()
            completion(block)
        }
        .store(in: &storage)
    }

}
