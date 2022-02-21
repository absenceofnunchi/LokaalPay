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
/// Asynchronous Core Data operations using closure

extension LocalStorage {
    func saveState(_ account: Account, completion: @escaping (NodeError?) -> Void) throws {
        let treeConfigAccount = try TreeConfigurableAccount(data: account)
        try saveState(treeConfigAccount, completion: completion)
    }
    
    func saveState(_ account: TreeConfigurableAccount, completion: @escaping (NodeError?) -> Void) throws {
        /// Halt if the item already exists
        try deleteAccount(account.id) { [weak self] (error) in
            if let error = error {
                completion(error)
            }
            
            guard let self = self,
                  let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.stateCoreData.rawValue, into: self.context) as? StateCoreData else { return }
            entity.id = account.id
            entity.data = account.data
            
            do {
                try self.context.save()
                completion(nil)
            } catch {
                completion(.generalError("Block save error"))
            }
        }
    }
    
    func getAccount(_ addressString: String, completion: @escaping (Account?, NodeError?) -> Void) throws {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        return getAccount(address, completion: completion)
    }
    
    func getAccount(_ address: EthereumAddress, completion: @escaping (Account?, NodeError?) -> Void) {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", address.address)
        
        container.performBackgroundTask { context in
            do {
                let results = try context.fetch(request)
                guard let result = results.first,
                      let data = result.data else {
                          completion(nil, NodeError.generalError("Parsing error"))
                          return
                      }
                
                completion(try Account(data), nil)
            } catch {
                completion(nil, NodeError.generalError("Unable to fetch blocks"))
            }
        }
    }
    
    func getAccount(_ addressString: String, completion: @escaping (TreeConfigurableAccount?, NodeError?) -> Void) throws {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        return getAccount(address, completion: completion)
    }
    
    func getAccount(_ address: EthereumAddress, completion: @escaping (TreeConfigurableAccount?, NodeError?) -> Void) {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", address.address)
        
        container.performBackgroundTask { context in
            do {
                let results = try context.fetch(request)
                guard let result = results.first,
                      let data = result.data,
                      let id = result.id else {
                          completion(nil, NodeError.generalError("Parsing error"))
                          return
                      }
                
                completion(TreeConfigurableAccount(id: id, data: data), nil)
            } catch {
                completion(nil, NodeError.generalError("Unable to fetch blocks"))
            }
        }
    }
    
    func getAllAccounts(completion: @escaping ([TreeConfigurableAccount]?, NodeError?) -> Void) {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        do {
            let results = try context.fetch(request)
            let accountArr: [TreeConfigurableAccount] = results.compactMap {
                guard let id = $0.id,
                      let data = $0.data else {
                          return nil
                      }
                return TreeConfigurableAccount(id: id, data: data)
            }
            completion(accountArr, nil)
        } catch {
            completion(nil, .generalError("Unable to fetch blocks"))
        }
    }
    
    func getAllAccounts(completion: @escaping ([Account]?, NodeError?) -> Void) {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        do {
            let results = try context.fetch(request)
            let accountArr: [Account] = results.compactMap {
                guard let data = $0.data else {
                    return nil
                }
                return try? Account(data)
            }
            completion(accountArr, nil)
        } catch {
            completion(nil, .generalError("Unable to fetch blocks"))
        }
    }
    
    func deleteAccount(_ address: EthereumAddress, completion: @escaping (NodeError?) -> Void) {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", address.address)
        
        do {
            let result = try context.fetch(request)
            for item in result {
                context.delete(item)
            }
            
            try context.save()
            completion(nil)
        } catch {
            completion(NodeError.generalError("Block deletion error"))
        }
    }
    
    func deleteAccount(_ addressString: String, completion: @escaping (NodeError?) -> Void) throws {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        deleteAccount(address, completion: completion)
    }
    
    func deleteAllAccounts(completion: @escaping (NodeError?) -> Void) {
        let request: NSFetchRequest<StateCoreData> = StateCoreData.fetchRequest()
        do {
            let result = try context.fetch(request)
            for item in result {
                context.delete(item)
            }
            
            try context.save()
            completion(nil)
        } catch {
            completion(NodeError.generalError("Block deletion error"))
        }
    }
}

/// Asynchronous state operations
@available(iOS 15.0.0, *)
extension LocalStorage {
    func saveStateAsync(_ account: Account) async throws {
        let treeConfigAccount = try TreeConfigurableAccount(data: account)
        try await saveStateAsync(treeConfigAccount)
    }
    
    func saveStateAsync(_ account: TreeConfigurableAccount) async throws {
        /// Halt if the item already exists
        try await deleteAccountAsync(account.id)
        guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.stateCoreData.rawValue, into: self.context) as? StateCoreData else { return }
        entity.id = account.id
        entity.data = account.data
        
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "saveStateContext"
        taskContext.transactionAuthor = "stateSaver"
        
        /// - Tag: performAndWait
        try await taskContext.perform {
            do {
                try self.context.save()
            } catch {
                throw NodeError.generalError("Block save error")
            }
        }
    }
    
    func saveStatesAsync(_ accounts: [Account]) async throws {
        let treeConfigAccounts: [TreeConfigurableAccount] = accounts.compactMap ({ try? TreeConfigurableAccount(data: $0) })
        try await saveStatesAsync(treeConfigAccounts)
    }
    
    func saveStatesAsync(_ accounts: [TreeConfigurableAccount]) async throws {
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "saveStateContext"
        taskContext.transactionAuthor = "stateSaver"
        
        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            guard let batchInsertRequest = self.newBatchInsertRequest(with: accounts) else { return }
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
    
    func getAllAccountsAsync() async throws -> [TreeConfigurableAccount]? {
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
    
    func getAllAccountsAsync() async throws -> [Account]? {
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
    
    func deleteAccountAsync(_ address: EthereumAddress) async throws {
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
    
    func deleteAccountAsync(_ addressString: String) async throws {
        guard let address = EthereumAddress(addressString) else {
            throw NodeError.generalError("Unable to parse the address")
        }
        try await deleteAccountAsync(address)
    }
    
    func deleteAllAccountsAsync() async throws {
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
            guard let result = results.first,
                  let data = result.data else {
                      throw NodeError.generalError("Parsing error")
                  }
            
            return try Account(data)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
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
