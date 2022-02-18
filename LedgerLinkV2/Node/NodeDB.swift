//
//  NodeDB.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-10.
//

/*
 Abstract:
 A node that adds and searches transactions, state, and receipts.
 */

import Foundation
import CryptoKit
import web3swift
import BigInt

final class NodeDB {
    static let shared = NodeDB()
    private(set) var transactionTrie = Tree<TreeConfigurableTransaction>()
    private(set) var stateTrie = Tree<TreeConfigurableAccount>()
    private(set) var receiptTrie = Tree<TreeConfigurableReceipt>()
    var blockHash: String? {
        return try? getBlockHash()
    }
    
    init() {
        
    }

    func search(_ data: TreeConfigurableAccount) -> TreeConfigurableAccount? {
        return stateTrie.search(for: data)
    }
    
    func search(_ data: Account) throws -> TreeConfigurableAccount? {
        let treeConfigAccount = try TreeConfigurableAccount(data: data)
        return stateTrie.search(for: treeConfigAccount)
    }
    
    /// for seraching states only using the address data.
    func search(_ addressData: Data) -> Account? {
        guard let treeConfigAccount =  stateTrie.search(for: addressData) else {
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
    
    func transfer(_ encoded: TreeConfigurableTransaction, decoded: EthereumTransaction) throws {
        /// Search for an existing account to transfer from and substract the amount to transfer from the balance. If it doesn't exist, abort the transfer operation.
        guard let result = stateTrie.search(for: encoded.id),
              let existingAccount = result.decode(),
              let transferAmount = decoded.value else { return }
        
        let newBalance = existingAccount.balance - transferAmount
        let updatedAccount = Account(address: existingAccount.address, nonce: existingAccount.nonce, balance: newBalance, codeHash: existingAccount.codeHash, storageRoot: existingAccount.storageRoot)
        let treeConfigAccount = try TreeConfigurableAccount(data: updatedAccount)
        stateTrie.deleteAndUpdate(treeConfigAccount)
        
        /// Search for the account to transfer to. If it exists, update the existing balance. If it doesn't, create a new account with a new balance.
        if let result = stateTrie.search(for: decoded.to.addressData),
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
        let addressData = Data(hex: address)
        let result =  search(addressData)
        return result
    }
}

extension NodeDB {
    func getBlockHash() throws -> String {
        guard let stateRoot = stateTrie.rootHash,
              let receiptRoot = receiptTrie.rootHash,
              let txRoot = transactionTrie.rootHash  else {
                  throw NodeError.generalError("Unable to generate the root hashes.")
        }
        
        var hash: String = ""
        if case .Node(hash: let stateHash, datum: _, left: _, right: _) = stateRoot {
            hash += stateHash
        }
        
        if case .Node(hash: let receiptHash, datum: _, left: _, right: _) = receiptRoot {
            hash += receiptHash
        }
        
        if case .Node(hash: let txHash, datum: _, left: _, right: _) = txRoot {
            hash += txHash
        }
        guard let data = hash.data(using: .utf8) else {
            throw NodeError.hashingError
        }
        
        let hashed = SHA256.hash(data: data)
        return hashed.hexStr
    }
    
    func createBlock() {
        let block = Block.pending
    }
}
