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

protocol NodeConfigurable {
    func search(_ data: TreeConfigurableAccount) -> TreeConfigurableAccount?
    func search(_ data: Account) throws -> TreeConfigurableAccount?
    /// for seraching states only using the address data.
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

//final class NodeCD: NodeConfigurable {
//    func search(_ data: TreeConfigurableAccount) -> TreeConfigurableAccount? {
//        return stateTrie.search(for: data)
//    }
//    
//    func search(_ data: Account) throws -> TreeConfigurableAccount? {
//        let treeConfigAccount = try TreeConfigurableAccount(data: data)
//        return stateTrie.search(for: treeConfigAccount)
//    }
//    
//    /// for seraching states only using the address data.
//    func search(_ addressString: String) -> Account? {
//        guard let treeConfigAccount =  stateTrie.search(address: addressString) else {
//            return nil
//        }
//        
//        return treeConfigAccount.decode()
//    }
//    
//    func search(_ data: TreeConfigurableTransaction) -> TreeConfigurableTransaction? {
//        return transactionTrie.search(for: data)
//    }
//    
//    func search(_ data: TreeConfigurableReceipt) -> TreeConfigurableReceipt? {
//        return receiptTrie.search(for: data)
//    }
//    
//    func addData(_ data: TreeConfigurableAccount) {
//        stateTrie.deleteAndUpdate(data)
//    }
//    
//    func addData(_ data: Account) throws {
//        let treeConfigAccount = try TreeConfigurableAccount(data: data)
//        stateTrie.deleteAndUpdate(treeConfigAccount)
//    }
//    
//    func addData(_ data: [TreeConfigurableAccount]) {
//        stateTrie.deleteAndUpdate(data)
//    }
//    
//    func addData(_ data: TreeConfigurableTransaction) {
//        transactionTrie.insert(data)
//    }
//    
//    func addData(_ data: [TreeConfigurableTransaction]) {
//        transactionTrie.insert(data)
//    }
//    
//    func addData(_ data: TreeConfigurableReceipt) {
//        receiptTrie.insert(data)
//    }
//    
//    func addData(_ data: [TreeConfigurableReceipt]) {
//        receiptTrie.insert(data)
//    }
//    
//    func transfer(_ treeConfigTransaction: TreeConfigurableTransaction) throws {
//        guard let decoded = treeConfigTransaction.decode() else {
//            return
//        }
//        
//        try transfer(treeConfigTransaction, decoded: decoded)
//    }
//    
//    func transfer(_ encoded: TreeConfigurableTransaction, decoded: EthereumTransaction) throws {
//        /// Search for an existing account to transfer from and substract the amount to transfer from the balance. If it doesn't exist, abort the transfer operation.
//        guard let result = stateTrie.search(address: encoded.id),
//              let existingAccount = result.decode(),
//              let transferAmount = decoded.value else { return }
//        
//        let newBalance = existingAccount.balance - transferAmount
//        let updatedAccount = Account(address: existingAccount.address, nonce: existingAccount.nonce, balance: newBalance, codeHash: existingAccount.codeHash, storageRoot: existingAccount.storageRoot)
//        let treeConfigAccount = try TreeConfigurableAccount(data: updatedAccount)
//        stateTrie.deleteAndUpdate(treeConfigAccount)
//        
//        /// Search for the account to transfer to. If it exists, update the existing balance. If it doesn't, create a new account with a new balance.
//        if let result = stateTrie.search(address: decoded.to.address),
//           let existingAccount = result.decode(),
//           let transferAmount = decoded.value {
//            let newBalance = existingAccount.balance + transferAmount
//            let updatedAccount = Account(address: existingAccount.address, nonce: existingAccount.nonce, balance: newBalance, codeHash: existingAccount.codeHash, storageRoot: existingAccount.storageRoot)
//            let treeConfigAccount = try TreeConfigurableAccount(data: updatedAccount)
//            stateTrie.deleteAndUpdate(treeConfigAccount)
//        } else {
//            guard let value = decoded.value else { return }
//            let newAccount = Account(address: decoded.to, nonce: BigUInt(0), balance: value)
//            let treeConfigAccount = try TreeConfigurableAccount(data: newAccount)
//            stateTrie.deleteAndUpdate(treeConfigAccount)
//        }
//    }
//    
//    func getMyAccount() throws -> Account? {
//        let localStorage = LocalStorage()
//        let wallet = try localStorage.getWallet()
//        guard let address = wallet?.address else { return nil }
//        let result = search(address)
//        return result
//    }
//}
