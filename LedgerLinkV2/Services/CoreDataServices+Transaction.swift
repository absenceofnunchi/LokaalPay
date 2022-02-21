//
//  CoreDataServices+Transaction.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-21.
//

import Foundation
import CoreData
import web3swift

// MARK: - Transaction

@available(iOS 15.0.0, *)
extension LocalStorage {
    func saveTransactionAsync(_ transaction: EthereumTransaction) async throws {
        let treeConfigTransaction = try TreeConfigurableTransaction(data: transaction)
        try await saveTransactionAsync(treeConfigTransaction)
    }
    
    func saveTransactionAsync(_ transaction: TreeConfigurableTransaction) async throws {
        /// Halt if the item already exists
        try await deleteTransactionAsync(transaction.id)
        guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.transactionCoreData.rawValue, into: self.context) as? TransactionCoreData else { return }
        entity.id = transaction.id
        entity.data = transaction.data
        
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "saveTransactionContext"
        taskContext.transactionAuthor = "transactionSaver"
        
        /// - Tag: performAndWait
        try await taskContext.perform {
            do {
                try self.context.save()
            } catch {
                throw NodeError.generalError("Block save error")
            }
        }
    }
    
    func saveTransactionAsync(_ transactions: [EthereumTransaction]) async throws {
        let treeConfigTransactions: [TreeConfigurableTransaction] = transactions.compactMap ({ try? TreeConfigurableTransaction(data: $0) })
        try await saveTransactionAsync(treeConfigTransactions)
    }
    
    func saveTransactionAsync(_ transactions: [TreeConfigurableTransaction]) async throws {
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "saveTransactionContext"
        taskContext.transactionAuthor = "transactionSaver"
        
        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            guard let batchInsertRequest = self.newBatchInsertRequest(with: transactions) else { return }
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }
            print("Failed to execute batch insert request.")
            throw NodeError.generalError("Batch insert error")
        }
        
        print("Successfully inserted data.")
    }
    
    func getAllTransactionsAsync() async throws -> [TreeConfigurableAccount]? {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        do {
            let results = try context.fetch(request)
            let accountArr: [TreeConfigurableAccount] = try results.compactMap {
                guard let id = $0.id,
                      let data = $0.data else {
                          throw NodeError.generalError("Parsing error")
                      }
                return TreeConfigurableAccount(id: id, data: data)
            }
            return accountArr
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func getAllTransactionsAsync() async throws -> [Account]? {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        do {
            let results = try context.fetch(request)
            let accountArr: [Account] = results.compactMap {
                guard let data = $0.data else {
                    return nil
                }
                return try? Account(data)
            }
            return accountArr
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func deleteTransactionAsync(_ address: EthereumAddress) async throws {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", address.address)
        
        try await context.perform { [weak self] in // runs asynchronously
            do {
                guard let result = try self?.context.fetch(request) else {
                    return
                }
                
                for item in result {
                    self?.context.delete(item)
                }
                
                try self?.context.save()
            } catch {
                throw NodeError.generalError("Block deletion error")
            }
        }
    }
    
    func deleteTransactionAsync(_ addressString: String) async throws {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        try await deleteTransactionAsync(address)
    }
    
    func deleteAllTransactionsAsync() async throws {
        try await context.perform { [weak self] in // runs asynchronously
            let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
            do {
                guard let result = try self?.context.fetch(request) else {
                    return
                }
                
                for item in result {
                    self?.context.delete(item)
                }
                
                try self?.context.save()
            } catch {
                throw NodeError.generalError("Block deletion error")
            }
        }
    }
}
