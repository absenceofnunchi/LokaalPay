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
    func createBlock(completion: @escaping (LightBlock) -> Void) {
        Deferred {
            /// Select the majority block from a pool of pending blocks
            Future<FullBlock?, NodeError> { [weak self] promise in
                Node.shared.localStorage.getLatestBlock { (lastBlock: FullBlock?, error: NodeError?) in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    /// Fetch the last block to compare it against the new block.
                    guard let lastBlock = lastBlock else {
                        promise(.success(nil))
                        return
                    }
                    
                    /// Select the new block from the pool of unvalidated blocks with the most tally.  There should be at least one block created locally
                    guard let newBlock = self?.unvalidatedBlocks.maxItem() else {
                        promise(.failure(NodeError.generalError("Unable to determine the new block to be added")))
                        return
                    }
                    
                    print("newBlock.number", newBlock.number)
                    print("lastBlock.number", lastBlock.number)
                    print("newBlock.parentHash", newBlock.parentHash)
                    print("lastBlock.hash", lastBlock.hash)
                    
                    print("unvalidatedBlocks", self?.unvalidatedBlocks as Any)
                    print("newBlock.number == (lastBlock.number + 1))", newBlock.number == (lastBlock.number + 1))
                    print("(newBlock.parentHash == lastBlock.hash)", (newBlock.parentHash == lastBlock.hash))
                    print("newBlock.parentHash", newBlock.parentHash.toHexString())
                    print("lastBlock.hash", lastBlock.hash.toHexString())
                    if (newBlock.number == (lastBlock.number + 1)) && (newBlock.parentHash == lastBlock.hash) {
                        //                        print("correct block!")
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
                        }
                    } else {
                        NetworkManager.shared.requestAllBlockchain { error in
//                            self?.clearUnvalidatedBlocks()
                            if let error = error {
                                print("request all error", error)
                                promise(.failure(error))
                            } else {
                                promise(.failure(.generalError("Incorrect block")))
                            }
                        }
                        
//                        NetworkManager.shared.requestBlockchainFromAllPeers(upto: 1) { error in
//                            /// the requested blockchain should most likely contain the executed transactions so clear the local pool
//                            self?.clearUnvalidatedBlocks()
//                            if let error = error {
//                                promise(.failure(error))
//                            } else {
//                                promise(.failure(.generalError("Incorrect block")))
//                            }
//                        }
                    }
                }
            }
            .eraseToAnyPublisher()
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
