//
//  NodeDB.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-10.
//

/*
 Abstract:
 Node database adds and searches transactions, state, and receipts in memory as opposed to NodeCD which utilizes Core Data.
 Also create a block and adds it to the blockchain.
 */

import Foundation
import CryptoKit
import web3swift
import BigInt

final class NodeDB: NodeConfigurable {
    static let shared = NodeDB()
    private(set) var transactionTrie = Tree<TreeConfigurableTransaction>()
    private(set) var stateTrie = Tree<TreeConfigurableAccount>()
    private(set) var receiptTrie = Tree<TreeConfigurableReceipt>()

    init() { }

    func search(_ data: TreeConfigurableAccount) -> TreeConfigurableAccount? {
        return stateTrie.search(for: data)
    }
    
    func search(_ data: Account) throws -> TreeConfigurableAccount? {
        let treeConfigAccount = try TreeConfigurableAccount(data: data)
        return stateTrie.search(for: treeConfigAccount)
    }
    
    /// for seraching states only using the address data.
    func search(_ addressString: String) -> Account? {
        guard let treeConfigAccount =  stateTrie.search(address: addressString) else {
            return nil
        }
        
        return treeConfigAccount.decode()
    }
    
    func search(_ data: TreeConfigurableTransaction) -> TreeConfigurableTransaction? {
        return transactionTrie.search(for: data)
    }
    
    func search(_ data: TreeConfigurableReceipt) -> TreeConfigurableReceipt? {
        return receiptTrie.search(for: data)
    }
    
    func addData(_ data: TreeConfigurableAccount) {
        stateTrie.deleteAndUpdate(data)
    }
    
    func addData(_ data: Account) throws {
        let treeConfigAccount = try TreeConfigurableAccount(data: data)
        stateTrie.deleteAndUpdate(treeConfigAccount)
    }
    
    func addData(_ data: [TreeConfigurableAccount]) {
        stateTrie.deleteAndUpdate(data)
    }
    
    func addData(_ data: TreeConfigurableTransaction) {
        transactionTrie.insert(data)
    }
    
    func addData(_ data: [TreeConfigurableTransaction]) {
        transactionTrie.insert(data)
    }
    
    func addData(_ data: TreeConfigurableReceipt) {
        receiptTrie.insert(data)
    }
    
    func addData(_ data: [TreeConfigurableReceipt]) {
        receiptTrie.insert(data)
    }
    
    func transfer(_ treeConfigTransaction: TreeConfigurableTransaction) throws {
        guard let decoded = treeConfigTransaction.decode() else {
            return
        }
        
        try transfer(treeConfigTransaction, decoded: decoded)
    }
    
    func transfer(_ encoded: TreeConfigurableTransaction, decoded: EthereumTransaction) throws {
        /// Search for an existing account to transfer from and substract the amount to transfer from the balance. If it doesn't exist, abort the transfer operation.
        guard let result = stateTrie.search(address: encoded.id),
              let existingAccount = result.decode(),
              let transferAmount = decoded.value else { return }
        
        let newBalance = existingAccount.balance - transferAmount
        let updatedAccount = Account(address: existingAccount.address, nonce: existingAccount.nonce, balance: newBalance, codeHash: existingAccount.codeHash, storageRoot: existingAccount.storageRoot)
        let treeConfigAccount = try TreeConfigurableAccount(data: updatedAccount)
        stateTrie.deleteAndUpdate(treeConfigAccount)
        
        /// Search for the account to transfer to. If it exists, update the existing balance. If it doesn't, create a new account with a new balance.
        if let result = stateTrie.search(address: decoded.to.address),
           let existingAccount = result.decode(),
           let transferAmount = decoded.value {
            let newBalance = existingAccount.balance + transferAmount
            let updatedAccount = Account(address: existingAccount.address, nonce: existingAccount.nonce, balance: newBalance, codeHash: existingAccount.codeHash, storageRoot: existingAccount.storageRoot)
            let treeConfigAccount = try TreeConfigurableAccount(data: updatedAccount)
            stateTrie.deleteAndUpdate(treeConfigAccount)
        } else {
            guard let value = decoded.value else { return }
            let newAccount = Account(address: decoded.to, nonce: BigUInt(0), balance: value)
            let treeConfigAccount = try TreeConfigurableAccount(data: newAccount)
            stateTrie.deleteAndUpdate(treeConfigAccount)
        }
    }
    
    func getMyAccount() throws -> Account? {
        let localStorage = LocalStorage()
        let wallet = try localStorage.getWallet()
        guard let address = wallet?.address else { return nil }
        let result = search(address)
        return result
    }
}

extension NodeDB {
    enum RootHash {
        case state
        case receipt
        case transaction
    }
    
    private func getRootHash(for rootHash: RootHash) -> Data? {
        switch rootHash {
            case .state:
                let stateRoot = stateTrie.rootHash
                guard case .Node(hash: let stateHash, datum: _, left: _, right: _) = stateRoot else {
                    return nil
                }
                
                return stateHash
            case .receipt:
                let receiptRoot = receiptTrie.rootHash
                guard case .Node(hash: let stateHash, datum: _, left: _, right: _) = receiptRoot else {
                    return nil
                }
                
                return stateHash
            case .transaction:
                let transactionRoot = transactionTrie.rootHash
                guard case .Node(hash: let stateHash, datum: _, left: _, right: _) = transactionRoot else {
                    return nil
                }
                
                return stateHash
        }
    }
    
    #if DEBUG
    func exposeRootHash(for rootHash: RootHash) -> Data? {
        return getRootHash(for: rootHash)
    }
    #endif
    
    func createBlock() throws {
        guard let latestBlock: FullBlock = try LocalStorage.shared.getLatestBlock(),
              let txRoot = getRootHash(for: .transaction),
              let stateRoot = getRootHash(for: .state),
              let receiptRoot = getRootHash(for: .receipt) else { return }
        
        let transactions = transactionTrie.getAllNodes()
//        let compressed = transactions.compressed
        
//        let block = ChainBlock(number: latestBlock.number, parentHash: latestBlock.hash, nonce: nil, transactionsRoot: txRoot, stateRoot: stateRoot, receiptsRoot: receiptRoot, transactions: <#T##[TreeConfigurableTransaction]#>, uncles: <#T##[Data]?#>)
    }
}
