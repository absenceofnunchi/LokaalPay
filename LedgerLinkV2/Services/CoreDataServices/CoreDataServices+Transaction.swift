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
    
    func saveTransactionsAsync(_ transactions: [EthereumTransaction]) async throws {
        let treeConfigTransactions: [TreeConfigurableTransaction] = transactions.compactMap ({ try? TreeConfigurableTransaction(data: $0) })
        try await saveTransactionsAsync(treeConfigTransactions)
    }
    
    func saveTransactionsAsync(_ transactions: [TreeConfigurableTransaction]) async throws {
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "saveTransactionContext"
        taskContext.transactionAuthor = "transactionSaver"
        
        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            guard let batchInsertRequest = self.newBatchInsertRequest(with: transactions) else {
                return
            }
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
    
    func getTransaction(_ rlpEncodedData: Data, completion: @escaping (EthereumTransaction?, NodeError?) -> Void) throws {
        guard let compressed = rlpEncodedData.compressed else {
            throw NodeError.generalError("Unable to parse the address")
        }
        let hexString = compressed.sha256().toHexString()
        return getTransaction(hexString, completion: completion)
    }
    
    func getTransaction(_ hexString: String, completion: @escaping (EthereumTransaction?, NodeError?) -> Void) {
        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", hexString)
        
        container.performBackgroundTask { context in
            do {
                let results = try context.fetch(request)
                guard let result = results.first,
                      let data = result.data,
                      let decompressed = data.decompressed,
                      let decoded = EthereumTransaction.fromRaw(decompressed) else {
                          completion(nil, NodeError.generalError("Parsing error"))
                          return
                      }
                
                completion(decoded, nil)
            } catch {
                completion(nil, NodeError.generalError("Unable to fetch blocks"))
            }
        }
    }
    
    func getTransaction(_ rlpEncodedData: Data, completion: @escaping (TreeConfigurableTransaction?, NodeError?) -> Void) throws {
        guard let compressed = rlpEncodedData.compressed else {
            throw NodeError.generalError("Unable to parse the address")
        }
        let hexString = compressed.sha256().toHexString()
        return getTransaction(hexString, completion: completion)
    }
    
    func getTransaction(_ hexString: String, completion: @escaping (TreeConfigurableTransaction?, NodeError?) -> Void) {
        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", hexString)
        
        container.performBackgroundTask { context in
            do {
                let results = try context.fetch(request)
                guard let result = results.first,
                      let data = result.data,
                      let id = result.id else {
                          completion(nil, NodeError.generalError("Parsing error"))
                          return
                      }
                
                completion(TreeConfigurableTransaction(id: id, data: data), nil)
            } catch {
                completion(nil, NodeError.generalError("Unable to fetch blocks"))
            }
        }
    }
    
    func getAllTransactionsAsync() async throws -> [TreeConfigurableTransaction]? {
        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
        do {
            let results = try context.fetch(request)
            let convertedArr: [TreeConfigurableTransaction] = try results.compactMap {
                guard let id = $0.id,
                      let data = $0.data else {
                          throw NodeError.generalError("Parsing error")
                      }
                return TreeConfigurableTransaction(id: id, data: data)
            }
            return convertedArr
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func getAllTransactionsAsync() async throws -> [EthereumTransaction]? {
        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
        do {
            let results = try context.fetch(request)
            let convertedArr: [EthereumTransaction] = try results.compactMap {
                guard let data = $0.data,
                      let decompressed = data.decompressed,
                      let decoded = EthereumTransaction.fromRaw(decompressed) else {
                          throw NodeError.generalError("Parsing error")
                }
                return decoded
            }
            return convertedArr
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func deleteTransactionAsync(_ hexString: String) async throws {
        let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", hexString)
        
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
    
    func deleteTransactionAsync(_ transaction: EthereumTransaction) async throws {
        guard let encoded = transaction.encode(),
              let compressed = encoded.compressed else {
            throw NodeError.generalError("Unable to parse the address")
        }
        let hexString = compressed.sha256().toHexString()
        try await deleteTransactionAsync(hexString)
    }
    
    func deleteAllTransactionsAsync() async throws {
        try await context.perform { [weak self] in // runs asynchronously
            let request: NSFetchRequest<TransactionCoreData> = TransactionCoreData.fetchRequest()
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

// MARK: - Generics

@available(iOS 15.0.0, *)
extension LocalStorage {
    func save<T: LightConfigurable>(_ element: T, completion: @escaping (NodeError?) -> Void) async {
        switch element {
            case is TreeConfigurableAccount:
                guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.stateCoreData.rawValue, into: self.context) as? StateCoreData else { return }
                entity.id = element.id
                entity.data = element.data
                break
            case is TreeConfigurableTransaction:
                guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.transactionCoreData.rawValue, into: self.context) as? TransactionCoreData else { return }
                entity.id = element.id
                entity.data = element.data
                break
            case is TreeConfigurableReceipt:
                guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.receiptCoreData.rawValue, into: self.context) as? ReceiptCoreData else { return }
                entity.id = element.id
                entity.data = element.data
                break
            default:
                break
                
        }

        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "save"
        taskContext.transactionAuthor = "Saver"
        
        /// delete request
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", element.id)
        
        /// - Tag: perform
        await taskContext.perform {
            
            do {
                /// deletion
                let results = try taskContext.fetch(request)
                for result in results {
                    taskContext.delete(result)
                }
                
                /// Delete if a duplicate exists and update a new one
                try taskContext.save()
            } catch {
                completion(NodeError.generalError("Block save error"))
            }
        }
    }
    
    func save<T>(_ element: T, completion: @escaping (NodeError?) -> Void) async {
        if let account = element as? Account {
            do {
                let treeConfigAccount = try TreeConfigurableAccount(data:account)
                await save(treeConfigAccount, completion: completion)
            } catch {
                completion(NodeError.generalError("Unable to prepare state to save"))
            }
        } else if let transaction = element as? EthereumTransaction {
            do {
                let treeConfigTransaction = try TreeConfigurableTransaction(data: transaction)
                await save(treeConfigTransaction, completion: completion)
            } catch {
                completion(NodeError.generalError("Unable to prepare transaction to save"))
            }
        } else if let receipt = element as? TransactionReceipt {
            do {
                let treeConfigReceipt = try TreeConfigurableReceipt(data: receipt)
                await save(treeConfigReceipt, completion: completion)
            } catch {
                completion(NodeError.generalError("Unable to prepare receipt to save"))
            }
        } else {
            completion(NodeError.generalError("Wrong type"))
        }
    }
    
    func save<T: LightConfigurable>( _ elements: [T], completion: @escaping (NodeError?) -> Void) async {
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "saveTransactionContext"
        taskContext.transactionAuthor = "transactionSaver"
        
        do {
            /// - Tag: performAndWait
            try await taskContext.perform {
                // Execute the batch insert.
                /// - Tag: batchInsertRequest
                guard let batchInsertRequest = self.newBatchInsertRequest(with: elements) else {
                    completion(NodeError.generalError("Unable to create a request"))
                    return
                }
                if let fetchResult = try? taskContext.execute(batchInsertRequest),
                   let batchInsertResult = fetchResult as? NSBatchInsertResult,
                   let success = batchInsertResult.result as? Bool, success {
                    return
                }
                print("Failed to execute batch insert request.")
                throw NodeError.generalError("Batch insert error")
            }
            
            print("Successfully inserted data.")
        } catch {
            completion(NodeError.generalError("Unable to save"))
        }
    }
    
    func save<T>(_ elements: [T], completion: @escaping (NodeError?) -> Void) async {
        if let accounts = elements as? [Account] {
            do {
                let results = try accounts.compactMap { try TreeConfigurableAccount(data: $0) }
                await save(results, completion: completion)
            } catch {
                completion(NodeError.generalError("Unable to prepare state to save"))
            }
        } else if let transactions = elements as? [EthereumTransaction] {
            do {
                let results = try transactions.compactMap { try TreeConfigurableTransaction(data: $0) }
                await save(results, completion: completion)
            } catch {
                completion(NodeError.generalError("Unable to prepare transaction to save"))
            }
        } else if let receipts = elements as? [TransactionReceipt] {
            do {
                let results = try receipts.compactMap { try TreeConfigurableReceipt(data: $0) }
                await save(results, completion: completion)
            } catch {
                completion(NodeError.generalError("Unable to prepare receipt to save"))
            }
        } else {
            completion(NodeError.generalError("Wrong type"))
        }
    }
    
    func save<T: LightConfigurable>(_ elements: [T], completion: @escaping (NodeError?) -> Void)  {
        guard elements.count > 0 else { return }
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "stateContext"
        taskContext.transactionAuthor = "stateSaver"
        
        do {
            /// - Tag: perform
            try taskContext.performAndWait { [weak self] in
                // Execute the batch insert.
                /// - Tag: batchInsertRequest
                guard let batchInsertRequest = self?.newBatchInsertRequest(with: elements) else { return }
                if let fetchResult = try? taskContext.execute(batchInsertRequest),
                   let batchInsertResult = fetchResult as? NSBatchInsertResult,
                   let success = batchInsertResult.result as? Bool, success {
                    return
                }
                print("Failed to execute batch insert request.")
                throw NodeError.generalError("Batch insert error")
            }
            
            print("Successfully inserted data.")
        } catch {
            completion(NodeError.generalError("Unable to save"))
        }
    }
    
    enum CoreDataType {
        case account
        case transaction
        case receipt
        case treeConfigAcct
        case treeConfigTx
        case treeConfigReceipt
    }
    
    func fetchAll<T: CoreDatable>(of type: CoreDataType, completion: @escaping ([T]?, NodeError?) -> Void) {
        switch type {
            case .account:
                let fetchRequest = NSFetchRequest<StateCoreData>(entityName: EntityName.stateCoreData.rawValue)
                // Initialize Asynchronous Fetch Request
                let asynchronousFetchRequest = NSAsynchronousFetchRequest<StateCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
                    guard let results = asynchronousFetchResult.finalResult else { return }
                    let accounts: [Account] = results.compactMap { (element: StateCoreData) in
                        guard let data = element.data else { return nil }
                        do {
                            return try Account(data)
                        } catch {
                            return nil
                        }
                    }

                    completion(accounts as? [T], nil)
                }
                
                do {
                    // Execute Asynchronous Fetch Request
                    let _ = try context.execute(asynchronousFetchRequest) as? NSPersistentStoreAsynchronousResult
                } catch {
                    let fetchError = error as NSError
                    print("\(fetchError), \(fetchError.userInfo)")
                    completion(nil, NodeError.generalError("Unable to fetch data"))
                }
                break
            case .transaction:
                let fetchRequest = NSFetchRequest<TransactionCoreData>(entityName: EntityName.transactionCoreData.rawValue)
                // Initialize Asynchronous Fetch Request
                let asynchronousFetchRequest = NSAsynchronousFetchRequest<TransactionCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
                    guard let results = asynchronousFetchResult.finalResult else { return }
                    let transactions: [EthereumTransaction] = results.compactMap { (element: TransactionCoreData) in
                        guard let data = element.data,
                              let decompressed = data.decompressed,
                              let decoded = EthereumTransaction.fromRaw(decompressed) else { return nil }
                        
                        return decoded
                    }
                    
                    completion(transactions as? [T], nil)
                }
                
                do {
                    // Execute Asynchronous Fetch Request
                    let _ = try context.execute(asynchronousFetchRequest) as? NSPersistentStoreAsynchronousResult
                } catch {
                    let fetchError = error as NSError
                    print("\(fetchError), \(fetchError.userInfo)")
                    completion(nil, NodeError.generalError("Unable to fetch data"))
                }
                break
            case .receipt:
                let fetchRequest = NSFetchRequest<ReceiptCoreData>(entityName: EntityName.receiptCoreData.rawValue)
                // Initialize Asynchronous Fetch Request
                let asynchronousFetchRequest = NSAsynchronousFetchRequest<ReceiptCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
                    guard let results = asynchronousFetchResult.finalResult else { return }
                    let receipts: [TransactionReceipt] = results.compactMap { (element: ReceiptCoreData) in
                        guard let data = element.data,
                              let decompressed = data.decompressed,
                              let decoded = try? TransactionReceipt.fromRaw(decompressed) else { return nil }
                        
                        return decoded
                    }
                    
                    completion(receipts as? [T], nil)
                }
                
                do {
                    // Execute Asynchronous Fetch Request
                    let _ = try context.execute(asynchronousFetchRequest) as? NSPersistentStoreAsynchronousResult
                } catch {
                    let fetchError = error as NSError
                    print("\(fetchError), \(fetchError.userInfo)")
                    completion(nil, NodeError.generalError("Unable to fetch data"))
                }
                break
            case .treeConfigAcct:
                let fetchRequest = NSFetchRequest<StateCoreData>(entityName: EntityName.stateCoreData.rawValue)
                // Initialize Asynchronous Fetch Request
                let asynchronousFetchRequest = NSAsynchronousFetchRequest<StateCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
                    guard let results = asynchronousFetchResult.finalResult else { return }
                    let accounts: [Account] = results.compactMap { (element: StateCoreData) in
                        guard let data = element.data else { return nil }
                        do {
                            return try Account(data)
                        } catch {
                            return nil
                        }
                    }
                    
                    completion(accounts as? [T], nil)
                }
                
                do {
                    // Execute Asynchronous Fetch Request
                    let _ = try context.execute(asynchronousFetchRequest) as? NSPersistentStoreAsynchronousResult
                } catch {
                    let fetchError = error as NSError
                    print("\(fetchError), \(fetchError.userInfo)")
                    completion(nil, NodeError.generalError("Unable to fetch data"))
                }
                break
            case .treeConfigTx:
                break
            case .treeConfigReceipt:
                break
        }
    }
    
//    enum DeleteMenu {
//        case account
//        case transaction
//        case receipt
//        case all
//
//        var value: String {
//            switch self {
//                case .account:
//                    return EntityName.stateCoreData.rawValue
//                case .transaction:
//                    return EntityName.transactionCoreData.rawValue
//                case .receipt:
//                    return EntityName.receiptCoreData.rawValue
//                case .all:
//                    return nil
//            }
//        }
//    }
//
    func deleteAll(of entity: EntityName) async throws {
        coreDataStack.saveContext()

        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity.rawValue)
        
        // Initialize Batch Delete Request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        // Configure Batch Update Request
        batchDeleteRequest.resultType = .resultTypeCount
        
        do {
            // Execute Batch Request
            guard let batchDeleteResult = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult else {
                return
            }
            
            print("The batch delete request has deleted \(batchDeleteResult.result!) records.")
            
            // Reset Managed Object Context
            context.reset()
            
        } catch {
            let updateError = error as NSError
            print("\(updateError), \(updateError.userInfo)")
        }
    }
}

protocol CoreDatable { }
extension LightConfigurable { }
extension Account: CoreDatable { }
extension EthereumTransaction: CoreDatable { }
extension TransactionReceipt: CoreDatable { }

