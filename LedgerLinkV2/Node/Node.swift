//
//  NodeCD.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-20.
//

/*
 Abstract:
 Node Core Data saves and queries TreeConfigurableAccounts, TreeConfigurableTransactions, and TreeConfigurableReceipts.
 It also creates a new block. It performs the same tasks as NodeDB except not in-memory, but with Core Data.
 */

import Foundation
import web3swift
import Combine
import BigInt
import MultipeerConnectivity

protocol NodeConfigurable {
    func search(_ data: TreeConfigurableAccount) -> TreeConfigurableAccount?
    func search(_ data: Account) throws -> TreeConfigurableAccount?
    func search(_ addressString: String) -> Account?
    func search(_ data: TreeConfigurableTransaction) -> TreeConfigurableTransaction?
    func search(_ data: TreeConfigurableReceipt) -> TreeConfigurableReceipt?
    func addData(_ data: TreeConfigurableAccount)
    func addData(_ data: Account) throws
    func addData(_ data: [TreeConfigurableAccount])
    func addData(_ data: TreeConfigurableTransaction)
    func addData(_ data: [TreeConfigurableTransaction])
    func addData(_ data: TreeConfigurableReceipt)
    func addData(_ data: [TreeConfigurableReceipt])
    func transfer(_ treeConfigTransaction: TreeConfigurableTransaction) throws
    func transfer(_ encoded: TreeConfigurableTransaction, decoded: EthereumTransaction) throws
    func getMyAccount() throws -> Account?
}

@available(iOS 15.0.0, *)
final class Node {
    static let shared = Node()
    let localStorage = LocalStorage()
    var storage = Set<AnyCancellable>()
    private var validatedTransactions: [Date: EthereumTransaction] = [:] /// validated transactions to be added to the queue as well as to be added to a block
    private var validatedAccounts: [TreeConfigurableAccount] = []
    private var unvalidatedBlocks: [LightBlock] = [] /// The light blocks received from peers to be validated prior to sending out a new one. Validating entails checking the number and the parent hash.
    private let queue = OperationQueue()
    
    func save<T: LightConfigurable>(_ element: T, completion: @escaping (NodeError?) -> Void) async {
        await localStorage.save(element, completion: completion)
    }
    
    func save<T>(_ element: T, completion: @escaping (NodeError?) -> Void) async {
        await localStorage.save(element, completion: completion)
    }
    
    func save<T: LightConfigurable>(_ elements: [T], completion: @escaping (NodeError?) -> Void) async {
        await localStorage.save(elements, completion: completion)
    }
    
    func save<T>(_ element: [T], completion: @escaping (NodeError?) -> Void) async {
        await localStorage.save(element, completion: completion)
    }
    
    func saveSync<T>(_ elements: [T], completion: @escaping (NodeError?) -> Void) {
        localStorage.saveSync(elements, completion: completion)
    }
    
    func saveSync<T: LightConfigurable>(_ elements: [T], completion: @escaping (NodeError?) -> Void) {
        localStorage.saveSync(elements, completion: completion)
    }
    
    func fetch<T: CoreDatable>(_ predicateString: String? = nil, completion: @escaping ([T]?, NodeError?) -> Void) {
        localStorage.fetch(predicateString, completion: completion)
    }
    
    func delete<T: CoreDatable>(_ element: T) {
        localStorage.delete(element)
    }
    
    func deleteAll(of entity: LocalStorage.EntityName) {
        localStorage.deleteAll(of: entity)
    }
    
    func deleteAll() {
        localStorage.deleteAll()
    }
    
    /*
     1. Subtract the value from the sender's balance.
     2. Add the value to the recipient's balance.
     3. Update both accounts with the updated balances to Core Data.
     */
    func transfer(transaction: EthereumTransaction) {
        guard let address = transaction.sender?.address else { return }
        
        Deferred {
            /// Sender's account. Subtract the value from the sender's balance
            Future<Account, NodeError> { [weak self] promise in
                self?.fetch(address) { (accounts: [Account]?, error: NodeError?) in
                    if let error = error {
                        promise(.failure(error))
                    }
                    
                    guard let accounts = accounts,
                          var account = accounts.first else {
                              promise(.failure(NodeError.generalError("Unable to find the account")))
                        return
                    }
                    
                    guard let value = transaction.value,
                          account.balance >= value else {
                              promise(.failure(NodeError.generalError("Not enough balance")))
                        return
                    }
                    
                    account.balance -= value
                    promise(.success(account))
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap { [weak self] (sender) -> AnyPublisher<[Account], NodeError> in
            /// Recipient's account. Add the value to the balance
            Future<[Account], NodeError> { promise in
                self?.fetch(transaction.to.address) { (accounts: [Account]?, error: NodeError?) in
                    if let error = error {
                        promise(.failure(error))
                    }
                    
                    /// If the account exists, update the amount. If not, create a new one.
                    if let accounts = accounts,
                       var recipient = accounts.first,
                       let value = transaction.value {
                        recipient.balance += value
                        let finalAccounts = [sender, recipient]
                        promise(.success(finalAccounts))
                    } else {
                        let password = Int.random(in: 1000...9999)
                        guard let newWallet = try? EthereumKeystoreV3(password: "\(password)") else {
                            promise(.failure(.generalError("Unable to generate a new address")))
                            return
                        }
                        
                        guard let address = newWallet.addresses?.first else {
                            promise(.failure(.generalError("Unable to generate a new address")))
                            return
                        }
                        
                        guard let value = transaction.value else {
                            promise(.failure(.generalError("Unable to generate get the sent balance")))
                            return
                        }
                        
                        let recipient = Account(address: address, nonce: 0, balance: value)
                        let finalAccounts = [sender, recipient]
                        promise(.success(finalAccounts))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        .sink(receiveCompletion: { completion in
            switch completion {
                case .failure(let error):
                    print("error in transfer value", error)
                    break
                case .finished:
                    print("finished in transfer value")
                    break
            }
        }, receiveValue: { [weak self] (accounts) in
            /// Accounts to be added to a block
            self?.addValidatedAccounts(accounts)
            
            /// Save both accounts with the updated balances
            Node.shared.saveSync(accounts, completion: { error in
                if let error = error {
                    print(error)
                }
                print("Save both accounts with the updated balances")
            })
        })
        .store(in: &storage)
    }
    
    func getMyAccount(completion: @escaping (Account?, NodeError?) -> Void) {
        do {
            let wallet = try localStorage.getWallet()
            guard let address = wallet?.address else { return }
            fetch(address) { (accounts: [Account]?, error: NodeError?) in
                if let _ = error {
                    completion(nil, NodeError.generalError("Unable to fetch the wallet"))
                }
                
                if let accounts = accounts, let account = accounts.first {
                    completion(account, nil)
                }
            }
        } catch {
            completion(nil, NodeError.generalError("Unable to fetch the address"))
        }
    }
    
    func executeTransactions() {
        
    }
    
    /// Block number parameter is to be used for sending out to peer nodes.
    /// Letting other nodes know about the current block number is to ensure that your and other nodes are up-to-date.
    /// If your node or other nodes are behind, then a request to provide the discrepency is made.
    func createBlock(completion: @escaping (LightBlock) -> Void) {
        Deferred {
            Future<FullBlock?, NodeError> { promise in
                Node.shared.localStorage.getLatestBlock { (block: FullBlock?, error: NodeError?) in
                    if let error = error {
                        promise(.failure(error))
                    }

                    promise(.success(block))
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap({ [weak self] (lastBlock) -> AnyPublisher<LightBlock, NodeError> in
            Future<LightBlock, NodeError> { promise in
                guard let self = self else {
                    promise(.failure(NodeError.generalError("Unable to create a new block")))
                    return
                }
                
                /// Create the stateRoot and transactionRoot from the validated data using the Merkle tree.
                let accountArr = self.validatedAccounts.map { $0.data }
                let txDataArr = self.validatedTransactions.map { $0.data }
                do {
                    /// Use default data if no validated transactions or account exist to create the merkle root hash
                    let defaultString = "0x0000000000000000000000000000000000000000"
                    guard let defaultData = defaultString.data(using: .utf8) else {
                        promise(.failure(NodeError.generalError("Unable to create a new block")))
                        return
                    }
                    
                    let accArr = accountArr.count > 0 ? accountArr : [defaultData]
                    guard case .Node(hash: let stateRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: accArr) else {
                        fatalError()
                    }
                    
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
                    let newBlock = try FullBlock(number: blockNumber + 1, parentHash: parentHash, nonce: nil, transactionsRoot: transactionsRoot, stateRoot: stateRoot, receiptsRoot: Data(), extraData: nil, gasLimit: nil, gasUsed: nil, transactions: self.validatedTransactions, accounts: self.validatedAccounts)
                    
                    let lightBlock = try LightBlock(data: newBlock)
                    promise(.success(lightBlock))
                } catch {
                    promise(.failure(.generalError("Unable to create a new block")))
                }
            }
            .eraseToAnyPublisher()
        })
        .flatMap { (newBlock) -> AnyPublisher<LightBlock, NodeError> in
            Future<LightBlock, NodeError> { promise in
                Node.shared.saveSync([newBlock]) { [weak self] error in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    self?.validatedTransactions.removeAll()
                    self?.validatedAccounts.removeAll()
                    
                    promise(.success(newBlock))
                }
            }
            .eraseToAnyPublisher()
        }
        .sink { completion in
            switch completion {
                case .finished:
                    print("block created")
                case .failure(let error):
                    print("block creation error", error)
            }
        } receiveValue: { (block) in
            completion(block)
        }
        .store(in: &storage)
    }
    
    func validateBlock(_ lastBlock: LightBlock) {
        /// Select the block with the largest number
        
        var blockSet = Multiset<LightBlock>()
        unvalidatedBlocks.forEach { blockSet.add($0) }
        
        
        unvalidatedBlocks.sort { $0.number < $1.number }
        guard let largestBlock = unvalidatedBlocks.last else { return }
        
        if largestBlock.number == lastBlock.number + 1 {
            
        } else if largestBlock.number > lastBlock.number + 1 {
            
        }
    }
    
    func addValidatedTransaction(_ rlpData: Data) {
        guard let treeConfigTx = try? TreeConfigurableTransaction(rlpTransaction: rlpData) else { return }
        validatedTransactions.append(treeConfigTx)
    }
    
    func addValidatedTransaction(_ transaction: EthereumTransaction) {
        guard let treeConfigTx = try? TreeConfigurableTransaction(data: transaction) else { return }
        validatedTransactions.append(treeConfigTx)
    }
    
    func addValidatedAccount(_ account: Account) {
        guard let treeConfigAcct = try? TreeConfigurableAccount(data: account) else { return }
        validatedAccounts.append(treeConfigAcct)
    }
    
    func addValidatedAccounts(_ accounts: [Account]) {
        accounts.forEach { addValidatedAccount($0) }
    }
    
    func addUnvalidatedBlock(_ block: LightBlock) {
        unvalidatedBlocks.append(block)
    }
    
    func processTransaction(_ data: Data, peerID: MCPeerID) {
        
        do {
            let decoded = try JSONDecoder().decode(ContractMethod.self, from: data)
            print("decoded in didReceive", decoded)
            switch decoded {
                case .createAccount(let rlpData):
                    NetworkManager.shared.relay(data: data, peerID: peerID)
                    validateTransaction(rlpData) { [weak self] (tx, extraData) in
                        //            let contractMethodOperation = ContractMethodOperation()
                        //            self?.queue.addOperations([contractMethodOperation], waitUntilFinished: true)
                        //            print("Operation finished with: \(contractMethodOperation.result!)")
                        if let extraData = extraData,
                           let tx = tx {
                            
                        }
                    }
                    break
                case .transferValue(let rlpData):
                    NetworkManager.shared.relay(data: data, peerID: peerID)
                    validateTransaction(rlpData) { (tx, extraData) in
                        if let extraData = extraData,
                           let tx = tx {
                            
                        }
                    }
                    break
                case .blockchainDownloadRequest(let blockNumber):
                    break
                case .blockchainDownloadResponse(let data):
                    break
            }
        } catch {
            print("error in didReceive", error)
        }
    }
    
    func validateTransaction(_ rlpData: Data, completion: @escaping (EthereumTransaction?, TransactionExtraData?) -> Void)  {
        /// Validate the transaction by recovering the public key.
        guard let decodedTx = EthereumTransaction.fromRaw(rlpData),// RLP -> EthereumTransaction
              let publicKey = decodedTx.recoverPublicKey(),
              let senderAddress = Web3.Utils.publicToAddressString(publicKey),
              let senderAddressToBeCompared = decodedTx.sender?.address,
              senderAddress == senderAddressToBeCompared.lowercased(), // If the two info are different, discard the transaction.
              let decodedExtraData = try? JSONDecoder().decode(TransactionExtraData.self, from: decodedTx.data),
              let compressed = rlpData.compressed else {
                  completion(nil, nil)
                  return
              }
        
        /// Check if the transaction already exists. Abort if it already exists.
        Node.shared.fetch(compressed.sha256().toHexString()) { (txs: [TreeConfigurableTransaction]?, error: NodeError?) in
            if let error = error {
                print("fetch error", error)
                completion(nil, nil)
                return
            }
            
            print("no fetched tx should exist", txs as Any)
            
            /// No matching transaction exists in Core Data so proceed to process the transaction
            guard let txs = txs, txs.count == 0  else {
                completion(nil, nil)
                return
            }
            
            
            completion(decodedTx, decodedExtraData)
        }
    }
}
