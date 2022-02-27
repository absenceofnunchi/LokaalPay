//
//  CoreDataServices+State.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-21.
//

import Foundation
import CoreData
import web3swift

// MARK: - State
/// Synchronous state operations
extension LocalStorage {
    func saveState(_ account: Account) throws {
        let treeConfigAccount = try TreeConfigurableAccount(data: account)
        try saveState(treeConfigAccount)
    }
    
    func saveState(_ account: TreeConfigurableAccount) throws {
        /// Halt if the item already exists
        try deleteAccount(account.id)
        guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.stateCoreData.rawValue, into: self.context) as? StateCoreData else { return }
        entity.id = account.id
        entity.data = account.data
        
        do {
            try self.context.save()
        } catch {
            throw NodeError.generalError("Block save error")
        }
    }
    
    func getAccount(_ addressString: String) throws -> Account? {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        return try getAccount(address)
    }
    
    func getAccount(_ address: EthereumAddress) throws -> Account? {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", address.address)
        
        do {
            let results = try context.fetch(request)
            print("results", results as Any)
            guard let result = results.first else {
                throw NodeError.generalError("Parsing error")
            }
            
            guard let data = result.data else {
                throw NodeError.generalError("Parsing error2")
            }
            
//            guard let result = results.first,
//                  let data = result.data else {
//                      throw NodeError.generalError("Parsing error")
//                  }
            
            return try Account(data)
        } catch {
            throw NodeError.generalError("Unable to fetch Account")
        }
    }
    
    func getAccount(_ addressString: String) throws -> TreeConfigurableAccount? {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        return try getAccount(address)
    }
    
    func getAccount(_ address: EthereumAddress) throws -> TreeConfigurableAccount? {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", address.address)
        
        do {
            let results = try context.fetch(request)
            guard let result = results.first,
                  let data = result.data,
                  let id = result.id else {
                      throw NodeError.generalError("Parsing error")
                  }
            
            return TreeConfigurableAccount(id: id, data: data)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func getAllAccounts() throws -> [TreeConfigurableAccount]? {
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
    
    func getAllAccounts() throws -> [Account]? {
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
    
    func getAllAccountsSync(completion: @escaping ([TreeConfigurableAccount]?, NodeError?) -> Void) {
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "stateContext"
        taskContext.transactionAuthor = "stateSaver"
        
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()

        /// - Tag: perform
        taskContext.performAndWait {
            do {
                let results = try context.fetch(request)
                let accountArr: [TreeConfigurableAccount] = results.compactMap {
                    guard let data = $0.data else {
                        return nil
                    }
                    guard let acct = try? Account(data) else {
                        return nil
                    }
                    
                    return try? TreeConfigurableAccount(data: acct)
                }
                completion(accountArr, nil)
            } catch {
                completion(nil, NodeError.generalError("Unable to fetch blocks"))
            }
        }
    }
    
    func deleteAccount(_ address: EthereumAddress) throws {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", address.address)
        
        do {
            let result = try context.fetch(request)
            for item in result {
                context.delete(item)
            }
            
            try context.save()
        } catch {
            throw NodeError.generalError("Block deletion error")
        }
    }
    
    func deleteAccount(_ addressString: String) throws {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        try deleteAccount(address)
    }
    
    func deleteAllAccounts() throws {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        do {
            let result = try context.fetch(request)
            for item in result {
                context.delete(item)
            }
            
            try context.save()
        } catch {
            throw NodeError.generalError("Block deletion error")
        }
    }
}

@available(iOS 15.0.0, *)
extension LocalStorage {
    func saveStateAsync(_ account: Account, completion: @escaping (NodeError?) -> Void) async {
        do {
            let treeConfigAccount = try TreeConfigurableAccount(data: account)
            await saveStateAsync(treeConfigAccount, completion: completion)
        } catch {
            completion(NodeError.generalError("Unabel to instantiate TreeConfigurableAccount"))
        }
    }
    
    func saveStateAsync(_ account: TreeConfigurableAccount, completion: @escaping (NodeError?) -> Void) async {
        /// Halt if the item already exists
        //        do {
        //            try deleteAccount(account.id)
        //        } catch {
        //            completion(NodeError.generalError("Unable to delete the duplicate account"))
        //        }
        
        
        guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.stateCoreData.rawValue, into: self.context) as? StateCoreData else { return }
        entity.id = account.id
        entity.data = account.data
        
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "stateContext"
        taskContext.transactionAuthor = "stateSaver"
        
        /// delete request
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", account.id)
        
        /// - Tag: perform
        await taskContext.perform {
            
            do {
                /// deletion
                let result = try taskContext.fetch(request)
                for item in result {
                    taskContext.delete(item)
                }
                
                /// Delete if a duplicate exists and update a new one
                try taskContext.save()
            } catch {
                completion(NodeError.generalError("Block save error"))
            }
        }
    }
    
    func saveStatesAsync(_ accounts: [Account]) throws {
        let treeConfigAccounts: [TreeConfigurableAccount] = accounts.compactMap ({ try? TreeConfigurableAccount(data: $0) })
        try saveStatesAsync(treeConfigAccounts)
    }
    
    func saveStatesAsync(_ accounts: [TreeConfigurableAccount]) throws {
        guard accounts.count > 0 else { return }
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "stateContext"
        taskContext.transactionAuthor = "stateSaver"
        
        /// - Tag: perform
        try taskContext.performAndWait { [weak self] in
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            guard let batchInsertRequest = self?.newBatchInsertRequest(with: accounts) else { return }
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }
            print("Failed to execute batch insert request.")
            throw NodeError.generalError("Batch insert error")
        }
        
        print("Successfully inserted data.")
        
        //        let taskContext = newTaskContext()
        //        // Add name and author to identify source of persistent history changes.
        //        taskContext.name = "stateContext"
        //        taskContext.transactionAuthor = "stateSaver"
        //        taskContext.perform { // runs asynchronously
        //
        //            while(true) { // loop through each batch of inserts
        //                autoreleasepool {
        //                    for item in accounts {
        //                        guard let newObject = NSEntityDescription.insertNewObject(forEntityName: "StateCoreData", into: taskContext) as? StateCoreData else { return }
        //                        newObject.id = item.id
        //                        newObject.data = item.data
        //                    }
        //                }
        //
        //                // only save once per batch insert
        //                do {
        //                    try taskContext.save()
        //                } catch {
        //                    print(error)
        //                }
        //
        //                taskContext.reset()
        //            }
        //        }
    }
    
    func getAccountAsync(_ addressString: String, completion: @escaping (Account?, NodeError?) -> Void) {
        guard let address = EthereumAddress(addressString) else {
            completion(nil, NodeError.generalError("Unable to parse the address"))
            return
        }
        return getAccountAsync(address, completion: completion)
    }
    
    func getAccountAsync(_ address: EthereumAddress, completion: @escaping (Account?, NodeError?) -> Void) {
        let fetchRequest = NSFetchRequest<StateCoreData>(entityName: EntityName.stateCoreData.rawValue)
        fetchRequest.predicate = NSPredicate(format: "id == %@", address.address)
        
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
            
            completion(accounts.first, nil)
            
            //            if let asynchronousFetchProgress = asynchronousFetchResult.progress {
            //                // Remove Observer
            //                asynchronousFetchProgress.removeObserver(self, forKeyPath: "completedUnitCount")
            //            }
        }
        
        // Create Progress
        //        let progress = Progress(totalUnitCount: 1)
        //
        //        // Become Current
        //        progress.becomeCurrent(withPendingUnitCount: 1)
        
        do {
            // Execute Asynchronous Fetch Request
            let asynchronousFetchResult = try context.execute(asynchronousFetchRequest) as? NSPersistentStoreAsynchronousResult
            
            if let asynchronousFetchProgress = asynchronousFetchResult?.progress {
                asynchronousFetchProgress.addObserver(self, forKeyPath: "completedUnitCount", options: NSKeyValueObservingOptions.new, context: nil)
            }
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
            completion(nil, NodeError.generalError("Unable to fetch data"))
        }
        
        //        progress.resignCurrent()
    }
    
    func getAccountAsync(_ addressString: String, completion: @escaping (TreeConfigurableAccount?, NodeError?) -> Void) throws {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        return getAccountAsync(address, completion: completion)
    }
    
    func getAccountAsync(_ address: EthereumAddress, completion: @escaping (TreeConfigurableAccount?, NodeError?) -> Void) {
        let fetchRequest = NSFetchRequest<StateCoreData>(entityName: EntityName.stateCoreData.rawValue)
        fetchRequest.predicate = NSPredicate(format: "id == %@", address.address)
        
        // Initialize Asynchronous Fetch Request
        let asynchronousFetchRequest = NSAsynchronousFetchRequest<StateCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            guard let results = asynchronousFetchResult.finalResult else { return }
            
            let accounts: [TreeConfigurableAccount] = results.compactMap { (element: StateCoreData) in
                guard let id = element.id,
                      let data = element.data else {
                          return nil
                      }
                return TreeConfigurableAccount(id: id, data: data)
            }
            
            completion(accounts.first, nil)
        }
        
        do {
            // Execute Asynchronous Fetch Request
            let _ = try context.execute(asynchronousFetchRequest)
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
            completion(nil, NodeError.generalError("Unable to fetch data"))
        }
    }
    
    func getAccountsAsync(_ addresses: [EthereumAddress], completion: @escaping ([TreeConfigurableAccount]?, NodeError?) -> Void) async {
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "stateContext"
        taskContext.transactionAuthor = "stateSaver"
        
        /// - Tag: performAndWait
        await taskContext.perform {
            for address in addresses {
                let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", address.address)
                
                do {
                    let results = try taskContext.fetch(request)
                    guard results.count > 0 else {
                        completion(nil, NodeError.generalError("Parsing error"))
                        return
                    }
                    
                    let converted: [TreeConfigurableAccount] = results.compactMap {
                        guard let id = $0.id,
                              let data = $0.data else { return nil }
                        return TreeConfigurableAccount(id: id, data: data)
                    }
                    completion(converted, nil)
                } catch {
                    completion(nil, NodeError.generalError("Unable to fetch blocks"))
                }
            }
        }
    }
    
    func getAllAccountsAsync(completion: @escaping ([TreeConfigurableAccount]?, NodeError?) -> Void) async {
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "stateContext"
        taskContext.transactionAuthor = "stateSaver"
        
        /// - Tag: perform
        await taskContext.perform {
            let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
            do {
                let results = try taskContext.fetch(request)
                let accountArr: [TreeConfigurableAccount] = try results.compactMap {
                    guard let id = $0.id,
                          let data = $0.data else {
                              throw NodeError.generalError("Parsing error")
                          }
                    return TreeConfigurableAccount(id: id, data: data)
                }
                completion(accountArr, nil)
            } catch {
                completion(nil, NodeError.generalError("Unable to fetch blocks"))
            }
        }
    }
    
    func getAllAccountsAsync(completion: @escaping ([Account]?, NodeError?) -> Void) async {
        //        let taskContext = newTaskContext()
        //        // Add name and author to identify source of persistent history changes.
        //        taskContext.name = "stateContext"
        //        taskContext.transactionAuthor = "stateSaver"
        //
        //        /// - Tag: perform
        //        await taskContext.perform {
        //            let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        //            do {
        //                let results = try taskContext.fetch(request)
        //                let accountArr: [Account] = results.compactMap {
        //                    print("fetched address", $0.id as Any)
        //                    guard let data = $0.data else {
        //                        print("nil returned")
        //                        return nil
        //                    }
        //
        ////                    return try? Account(data)
        //                    do {
        //                        return try Account(data)
        //                    } catch {
        //                        print("Account instantiation error", error)
        //                        return nil
        //                    }
        //                }
        //                completion(accountArr, nil)
        //            } catch {
        //                completion(nil, NodeError.generalError("Unable to fetch blocks"))
        //            }
        //        }
        
        
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
            
            completion(accounts, nil)
            
            //            if let asynchronousFetchProgress = asynchronousFetchResult.progress {
            //                // Remove Observer
            //                asynchronousFetchProgress.removeObserver(self, forKeyPath: "completedUnitCount")
            //            }
        }
        
        // Create Progress
        //        let progress = Progress(totalUnitCount: 1)
        //
        //        // Become Current
        //        progress.becomeCurrent(withPendingUnitCount: 1)
        
        do {
            // Execute Asynchronous Fetch Request
            let asynchronousFetchResult = try context.execute(asynchronousFetchRequest) as? NSPersistentStoreAsynchronousResult
            
            if let asynchronousFetchProgress = asynchronousFetchResult?.progress {
                asynchronousFetchProgress.addObserver(self, forKeyPath: "completedUnitCount", options: NSKeyValueObservingOptions.new, context: nil)
            }
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
            completion(nil, NodeError.generalError("Unable to fetch data"))
        }
        
        //        progress.resignCurrent()
    }
    
    func deleteAccountAsync(_ address: EthereumAddress, completion: @escaping (NodeError?) -> Void) async {
        //        let taskContext = newTaskContext()
        //        // Add name and author to identify source of persistent history changes.
        //        taskContext.name = "stateContext"
        //        taskContext.transactionAuthor = "stateSaver"
        //
        //        /// - Tag: perform
        //        await taskContext.perform {
        //            let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        //            request.predicate = NSPredicate(format: "id == %@", address.address)
        //
        //            do {
        //                let result = try taskContext.fetch(request)
        //                for item in result {
        //                    taskContext.delete(item)
        //                }
        //
        //                try taskContext.save()
        //            } catch {
        //                completion(NodeError.generalError("Block deletion error"))
        //            }
        //        }
        // Makes sure changes are saved to be deleted
        coreDataStack.saveContext()
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: EntityName.stateCoreData.rawValue)
        fetchRequest.predicate = NSPredicate(format: "id == %@", address.address)
        
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
    
    func deleteAccountAsync(_ addressString: String, completion: @escaping (NodeError?) -> Void) async throws {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        await deleteAccountAsync(address, completion: completion)
    }
    
    func deleteAllAccountsAsync() async throws {
        //        let taskContext = newTaskContext()
        //        // Add name and author to identify source of persistent history changes.
        //        taskContext.name = "stateContext"
        //        taskContext.transactionAuthor = "stateSaver"
        //
        //        /// - Tag: perform
        //        try await taskContext.perform {
        //            let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        //            do {
        //                let result = try taskContext.fetch(request)
        //                for item in result {
        //                    taskContext.delete(item)
        //                }
        //
        //                try taskContext.save()
        //            } catch {
        //                throw NodeError.generalError("Block deletion error")
        //            }
        //        }
        
        // Makes sure changes are saved to be deleted
        coreDataStack.saveContext()
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: EntityName.stateCoreData.rawValue)
        
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

extension LocalStorage {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "completedUnitCount" {
            if let changes = change, let number = changes[NSKeyValueChangeKey(rawValue: "new")] {
                // Create Status
                let status = "Fetched \(number) Records"
                print(status)
            }
        }
    }
}
