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
    private var validatedOperations: [TimestampedOperation] = [] /// validated transactions to be added to the queue and executed in order
    private var validatedTransactions: [TreeConfigurableTransaction] = [] /// validated transactions to be added to the upcoming block
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

    struct TimestampedOperation {
        let timestamp: Date
        let operation: AsyncOperation
    }
    
    /// Block number parameter is to be used for sending out to peer nodes.
    /// Letting other nodes know about the current block number is to ensure that your and other nodes are up-to-date.
    /// If your node or other nodes are behind, then a request to provide the discrepency is made.
    func createBlock(completion: @escaping (LightBlock) -> Void) {
        Deferred {
            Future<Bool, NodeError> { [weak self] promise in
                guard let sorted = self?.validatedOperations.sorted (by: { $0.timestamp < $1.timestamp }) else {
                    promise(.failure(.generalError("Unable to sort the timestamped operations")))
                    return
                }
                let operations = sorted.compactMap { $0.operation }
                self?.queue.addOperations(operations, waitUntilFinished: true)
                promise(.success(true))
            }
            .eraseToAnyPublisher()
        }
        .flatMap({ (_) -> AnyPublisher<FullBlock?, NodeError> in
            Future<FullBlock?, NodeError> { promise in
                Node.shared.localStorage.getLatestBlock { (block: FullBlock?, error: NodeError?) in
                    if let error = error {
                        promise(.failure(error))
                    }
                    
                    promise(.success(block))
                }
            }
            .eraseToAnyPublisher()
        })
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
    
    func addValidatedTransaction(_ rlpData: Data) {
        guard let treeConfigTx = try? TreeConfigurableTransaction(rlpTransaction: rlpData) else { return }
        
        let transactionHash = treeConfigTx.id
        /// Validate the transaction by checking for duplicates in the waiting pool
        let duplicates = validatedTransactions.filter ({ $0.id == transactionHash })
        guard duplicates.count == 0 else {
            return
        }
        
        /// Validate the transaction by checking for duplicates in the blockchain
        Node.shared.fetch(transactionHash) { [weak self] (txs: [EthereumTransaction]?, error: NodeError?) in
            if let _ = error {
                return
            }
            
            
            /// No matching transaction exists in Core Data so proceed to process the transaction
            guard let txs = txs, txs.count == 0  else {
                return
            }
            
            self?.validatedTransactions.append(treeConfigTx)
        }
    }
    
    func addValidatedTransaction(_ transaction: EthereumTransaction) {
        guard let treeConfigTx = try? TreeConfigurableTransaction(data: transaction) else { return }

        let transactionHash = treeConfigTx.id
        /// Validate the transaction by checking for duplicates in the waiting pool
        let duplicates = validatedTransactions.filter ({ $0.id == transactionHash })
        guard duplicates.count == 0 else {
            return
        }
        
        /// Validate the transaction by checking for duplicates in the blockchain
        Node.shared.fetch(transactionHash) { [weak self] (txs: [EthereumTransaction]?, error: NodeError?) in
            if let _ = error {
                return
            }
            
            
            /// No matching transaction exists in Core Data so proceed to process the transaction
            guard let txs = txs, txs.count == 0  else {
                return
            }
            
            self?.validatedTransactions.append(treeConfigTx)
        }
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
    
    /// Process the transactions received from peers according to the contract methods.
    func processTransaction(_ data: Data, peerID: MCPeerID) {
        
        do {
            let decoded = try JSONDecoder().decode(ContractMethod.self, from: data)
            switch decoded {
                case .createAccount(let rlpData):
                    NetworkManager.shared.relayTransaction(data: data, peerID: peerID)
                    validateTransaction(rlpData) { [weak self] (result, error) in
                        if let transaction = result.0,
                           let extraData = result.1 {
                            let createAccount = CreateAccount(extraData: extraData)
                            let timestamp = extraData.timestamp
                            /// Add the operations to be sorted according to the timestamp and to be executed in order
                            self?.validatedOperations.append(TimestampedOperation(timestamp: timestamp, operation: createAccount))
                            /// Add the transactions to be added to the upcoming block
                            guard let treeConfigTx = try? TreeConfigurableTransaction(data: transaction) else { return }
                            self?.validatedTransactions.append(treeConfigTx)
                        }
                    }
                    break
                case .transferValue(let rlpData):
                    NetworkManager.shared.relayTransaction(data: data, peerID: peerID)
                    validateTransaction(rlpData) { [weak self] (result, error) in
                        if let transaction = result.0,
                           let extraData = result.1 {
                            let transferValueOperation = TransferValueOperation(transaction: transaction)
                            let timestamp = extraData.timestamp
                            /// Add the operations to be sorted according to the timestamp and to be executed in order
                            self?.validatedOperations.append(TimestampedOperation(timestamp: timestamp, operation: transferValueOperation))
                            /// Add the transactions to be added to the upcoming block
                            guard let treeConfigTx = try? TreeConfigurableTransaction(data: transaction) else { return }
                            self?.validatedTransactions.append(treeConfigTx)
                        }
                    }
                    break
                case .blockchainDownloadRequest(let blockNumber):
                    /// Blockchain request by the sender. Therefore, send the requested blockchain.
                    NetworkManager.shared.sendBlockchain(blockNumber, format: "number > %i", peerID: peerID)
                    break
                case .blockchainDownloadResponse(let data):
                    /// Parse the requested blockchain
                    /// Non-transactions don't have to go through the queue such as the blockchain data sent from peers as a response to the request to update the local blockchain
                    /// Blockchain data received from peers to update the local blockchain.  This means your device has requested the blockchain info from another peer either during the creation of wallet or during the contract method execution.
                    parsePacket(packet)
                    break
                case .sendBlock(let data):
                    /// Light blocks sent from peers on a regular interval
                    parseBlock(decoded)
                    break
            }
        } catch {
            print("error in didReceive", error)
        }
    }
    
    /// What is a valid transaction?
    ///  1. The recovered public key should match the sender.
    ///  2. The transaction should not already exist in the blockchain.
    ///  3. The transaction should not already exist among validated transaction pool to be added to the upcoming block (no duplicted allowed).
    private func validateTransaction(_ rlpData: Data, completion: @escaping ((EthereumTransaction?, TransactionExtraData?), NodeError?) -> Void)  {
        /// 1. Validate the transaction by recovering the public key.
        guard let decodedTx = EthereumTransaction.fromRaw(rlpData),// RLP -> EthereumTransaction
              let publicKey = decodedTx.recoverPublicKey(),
              let senderAddress = Web3.Utils.publicToAddressString(publicKey),
              let senderAddressToBeCompared = decodedTx.sender?.address,
              senderAddress == senderAddressToBeCompared.lowercased(), // If the two info are different, discard the transaction.
              let decodedExtraData = try? JSONDecoder().decode(TransactionExtraData.self, from: decodedTx.data),
              let compressed = rlpData.compressed else {
                  completion((nil, nil), .generalError("Unable to validate the transaction"))
                  return
              }
        
        let transactionHash = compressed.sha256().toHexString()
        /// 2. Validate the transaction by checking for duplicates in the waiting pool
        let duplicates = validatedTransactions.filter ({ $0.id == transactionHash })
        guard duplicates.count == 0 else {
            completion((nil, nil), .generalError("Duplicate transaction exists"))
            return
        }
        
        /// 3. Validate the transaction by checking for duplicates in the blockchain
        Node.shared.fetch(transactionHash) { (txs: [EthereumTransaction]?, error: NodeError?) in
            if let error = error {
                print("fetch error", error)
                completion((nil, nil), error)
                return
            }
            
            
            /// No matching transaction exists in Core Data so proceed to process the transaction
            guard let txs = txs, txs.count == 0  else {
                completion((nil, nil), .generalError("Duplicate transaction exists in the blockchain"))
                return
            }
            
            completion((decodedTx, decodedExtraData), nil)
        }
    }
    
    /// Parses Packet which consists of an array of TreeConfigAccts, TreeConfigTxs, and lightBlocks.
    /// The packets are sent as a response to a request for a portion of or a full blockchain by peers
    func parsePacket(_ packet: Packet) {
        /// Calculate the blocks that don't exist locally and save them.
        if let blocks = packet.blocks, blocks.count > 0 {
            Node.shared.localStorage.getLatestBlock { (block: LightBlock?, error: NodeError?) in
                if let error = error {
                    print(error)
                    return
                }
                
                if let block = block {
                    /// Only save the blocks that are greater in its block number than then the already existing blocks.
                    let nonExistingBlocks = blocks.filter { $0.number > block.number }
                    /// There is a chance that the local blockchain size might have increased during the transfer. If so, ignore the received block
                    if nonExistingBlocks.count > 0 {
                        Node.shared.saveSync(nonExistingBlocks) { error in
                            if let error = error {
                                print(error)
                                return
                            }
                        }
                    }
                } else {
                    /// no local blockchain exists yet because it's a brand new account
                    /// delete potentially existing ones since no transactions could've/should've been occured
                    Node.shared.deleteAll(of: .blockCoreData)
                    Node.shared.saveSync(blocks) { error in
                        if let error = error {
                            print("block save error", error)
                            return
                        }
                    }
                }
            }
        }
        
        /// Save the transactions.
        if let transactions = packet.transactions, transactions.count > 0 {
            Node.shared.saveSync(transactions) { error in
                if let error = error {
                    print("transaction save error", error)
                    return
                }
            }
        }
        
        /// Save the accounts.
        if let accounts = packet.accounts, accounts.count > 0 {
            Node.shared.saveSync(accounts) { error in
                if let error = error {
                    print("accounts save error", error)
                    return
                }
            }
        }
    }
    
    func parseBlock(_ block: LightBlock) {
        /// Receive the block sent from peers, compare against the local block's number and add the greater one to Core Data
        Node.shared.addUnvalidatedBlock(block)
    }
}

#if DEBUG
extension Node {
    func exposeValidateTransaction(_ rlpData: Data, completion: @escaping ((EthereumTransaction?, TransactionExtraData?), NodeError?) -> Void) {
        return validateTransaction(rlpData, completion: completion)
    }
}
#endif
