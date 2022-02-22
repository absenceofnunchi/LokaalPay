////
////  CoreDataServices+Transaction.swift
////  LedgerLinkV2
////
////  Created by J C on 2022-02-21.
////
//
//import Foundation
//import CoreData
//import web3swift
//
//// MARK: - Transaction
//
//@available(iOS 15.0.0, *)
//extension LocalStorage {
//    func saveTransactionAsync(_ transaction: EthereumTransaction) async throws {
//        let treeConfigTransaction = try TreeConfigurableTransaction(data: transaction)
//        try await saveTransactionAsync(treeConfigTransaction)
//    }
//    
//    func saveTransactionAsync(_ transaction: TreeConfigurableTransaction) async throws {
//        /// Halt if the item already exists
//        try await deleteTransactionAsync(transaction.id)
//        guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.transactionCoreData.rawValue, into: self.context) as? TransactionCoreData else { return }
//        entity.id = transaction.id
//        entity.data = transaction.data
//        
//        let taskContext = newTaskContext()
//        // Add name and author to identify source of persistent history changes.
//        taskContext.name = "saveTransactionContext"
//        taskContext.transactionAuthor = "transactionSaver"
//        
//        /// - Tag: performAndWait
//        try await taskContext.perform {
//            do {
//                try self.context.save()
//            } catch {
//                throw NodeError.generalError("Block save error")
//            }
//        }
//    }
//    
//    func saveTransactionsAsync(_ transactions: [EthereumTransaction]) async throws {
//        let treeConfigTransactions: [TreeConfigurableTransaction] = transactions.compactMap ({ try? TreeConfigurableTransaction(data: $0) })
//        try await saveTransactionsAsync(treeConfigTransactions)
//    }
//    
//    func saveTransactionsAsync(_ transactions: [TreeConfigurableTransaction]) async throws {
//        let taskContext = newTaskContext()
//        // Add name and author to identify source of persistent history changes.
//        taskContext.name = "saveTransactionContext"
//        taskContext.transactionAuthor = "transactionSaver"
//        
//        /// - Tag: performAndWait
//        try await taskContext.perform {
//            // Execute the batch insert.
//            /// - Tag: batchInsertRequest
//            let batchInsertRequest = self.newBatchInsertRequest(with: transactions)
//            if let fetchResult = try? taskContext.execute(batchInsertRequest),
//               let batchInsertResult = fetchResult as? NSBatchInsertResult,
//               let success = batchInsertResult.result as? Bool, success {
//                return
//            }
//            print("Failed to execute batch insert request.")
//            throw NodeError.generalError("Batch insert error")
//        }
//        
//        print("Successfully inserted data.")
//    }
//    
//    func getTransaction(_ rlpEncodedData: Data, completion: @escaping (EthereumTransaction?, NodeError?) -> Void) throws {
//        guard let compressed = rlpEncodedData.compressed else {
//            throw NodeError.generalError("Unable to parse the address")
//        }
//        let hexString = compressed.sha256().toHexString()
//        return getTransaction(hexString, completion: completion)
//    }
//    
//    func getTransaction(_ hexString: String, completion: @escaping (EthereumTransaction?, NodeError?) -> Void) {
//        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
//        request.predicate = NSPredicate(format: "id == %@", hexString)
//        
//        container.performBackgroundTask { context in
//            do {
//                let results = try context.fetch(request)
//                guard let result = results.first,
//                      let data = result.data,
//                      let decompressed = data.decompressed,
//                      let decoded = EthereumTransaction.fromRaw(decompressed) else {
//                          completion(nil, NodeError.generalError("Parsing error"))
//                          return
//                      }
//                
//                completion(decoded, nil)
//            } catch {
//                completion(nil, NodeError.generalError("Unable to fetch blocks"))
//            }
//        }
//    }
//    
//    func getTransaction(_ rlpEncodedData: Data, completion: @escaping (TreeConfigurableTransaction?, NodeError?) -> Void) throws {
//        guard let compressed = rlpEncodedData.compressed else {
//            throw NodeError.generalError("Unable to parse the address")
//        }
//        let hexString = compressed.sha256().toHexString()
//        return getTransaction(hexString, completion: completion)
//    }
//    
//    func getTransaction(_ hexString: String, completion: @escaping (TreeConfigurableTransaction?, NodeError?) -> Void) {
//        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
//        request.predicate = NSPredicate(format: "id == %@", hexString)
//        
//        container.performBackgroundTask { context in
//            do {
//                let results = try context.fetch(request)
//                guard let result = results.first,
//                      let data = result.data,
//                      let id = result.id else {
//                          completion(nil, NodeError.generalError("Parsing error"))
//                          return
//                      }
//                
//                completion(TreeConfigurableTransaction(id: id, data: data), nil)
//            } catch {
//                completion(nil, NodeError.generalError("Unable to fetch blocks"))
//            }
//        }
//    }
//    
//    func getAllTransactionsAsync() async throws -> [TreeConfigurableTransaction]? {
//        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
//        do {
//            let results = try context.fetch(request)
//            let convertedArr: [TreeConfigurableTransaction] = try results.compactMap {
//                guard let id = $0.id,
//                      let data = $0.data else {
//                          throw NodeError.generalError("Parsing error")
//                      }
//                return TreeConfigurableTransaction(id: id, data: data)
//            }
//            return convertedArr
//        } catch {
//            throw NodeError.generalError("Unable to fetch blocks")
//        }
//    }
//    
//    func getAllTransactionsAsync() async throws -> [EthereumTransaction]? {
//        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
//        do {
//            let results = try context.fetch(request)
//            let convertedArr: [EthereumTransaction] = try results.compactMap {
//                guard let data = $0.data,
//                      let decompressed = data.decompressed,
//                      let decoded = EthereumTransaction.fromRaw(decompressed) else {
//                          throw NodeError.generalError("Parsing error")
//                }
//                return decoded
//            }
//            return convertedArr
//        } catch {
//            throw NodeError.generalError("Unable to fetch blocks")
//        }
//    }
//    
//    func deleteTransactionAsync(_ hexString: String) async throws {
//        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
//        request.predicate = NSPredicate(format: "id == %@", hexString)
//        
//        try await context.perform { [weak self] in // runs asynchronously
//            do {
//                guard let result = try self?.context.fetch(request) else {
//                    return
//                }
//                
//                for item in result {
//                    self?.context.delete(item)
//                }
//                
//                try self?.context.save()
//            } catch {
//                throw NodeError.generalError("Block deletion error")
//            }
//        }
//    }
//    
//    func deleteTransactionAsync(_ transaction: EthereumTransaction) async throws {
//        guard let encoded = transaction.encode(),
//              let compressed = encoded.compressed else {
//            throw NodeError.generalError("Unable to parse the address")
//        }
//        let hexString = compressed.sha256().toHexString()
//        try await deleteTransactionAsync(hexString)
//    }
//    
//    func deleteAllTransactionsAsync() async throws {
//        try await context.perform { [weak self] in // runs asynchronously
//            let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
//            do {
//                guard let result = try self?.context.fetch(request) else {
//                    return
//                }
//                
//                for item in result {
//                    self?.context.delete(item)
//                }
//                
//                try self?.context.save()
//            } catch {
//                throw NodeError.generalError("Block deletion error")
//            }
//        }
//    }
//}
