//
//  CoreDataServices+Block.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-21.
//

import Foundation
import CoreData
import BigInt

// MARK: - Blocks
/// Operations for saving and fetching blocks.  All blocks are saved as light blocks.
extension LocalStorage {
    /// Fetch a light block by its block hash
    func getBlock(_ id: String) throws -> LightBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            return LightBlock.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    /// Fetch a full block by its block hash
    func getBlock(_ id: String) throws -> FullBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            return LightBlock.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    /// Fetch a light block by its block number
    func getBlock(_ number: Int32) throws -> LightBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "number == %i", number)
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            return LightBlock.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    /// Fetch a full block by its block number
    func getBlock(_ number: Int32) throws -> FullBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "number == %i", number)
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            return LightBlock.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func getBlock(_ number: Int32, completion: @escaping (FullBlock?, NodeError?) -> Void) {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "number == %i", number)
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else {
                completion(nil, nil)
                return
            }
            let block: FullBlock? = LightBlock.fromCoreData(crModel: result)
            completion(block, nil)
        } catch {
            completion(nil, NodeError.generalError("Unable to fetch blocks"))
        }
    }
    
    func getBlocks(_ number: Int32, format: String = "number == %i", completion: @escaping ([LightBlock]?, NodeError?) -> Void) {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: format, number)
        
        do {
            let results = try context.fetch(requestBlock)
            let blocks: [LightBlock] = results.compactMap { LightBlock.fromCoreData(crModel: $0) }
            completion(blocks, nil)
        } catch {
            completion(nil, NodeError.generalError("Unable to fetch blocks"))
        }
    }
    
    
    func getBlocks(from number: Int32, format: String, completion: @escaping ([LightBlock]?, NodeError?) -> Void) {
        guard number >= 0 else {
            completion(nil, .generalError("The block number has to be greater than 0"))
            return
        }
        
        let fetchRequest = NSFetchRequest<BlockCoreData>(entityName: EntityName.blockCoreData.rawValue)
        fetchRequest.predicate = NSPredicate(format: format, number)

        // Initialize Asynchronous Fetch Request
        let asynchronousFetchRequest = NSAsynchronousFetchRequest<BlockCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            guard let results = asynchronousFetchResult.finalResult else { return }
            let blocks: [LightBlock] = results.compactMap { (element: BlockCoreData) in
                return LightBlock.fromCoreData(crModel: element)
            }
            
            completion(blocks, nil)
        }
        
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
    }
    
    func getBlocks(from number: Int32, format: String, completion: @escaping ([FullBlock]?, NodeError?) -> Void) {
        guard number >= 0 else {
            completion(nil, .generalError("The block number has to be greater than 0"))
            return
        }
        
        let fetchRequest = NSFetchRequest<BlockCoreData>(entityName: EntityName.blockCoreData.rawValue)
        fetchRequest.predicate = NSPredicate(format: format, number)
        
        // Initialize Asynchronous Fetch Request
        let asynchronousFetchRequest = NSAsynchronousFetchRequest<BlockCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            guard let results = asynchronousFetchResult.finalResult else { return }
            let blocks: [FullBlock] = results.compactMap { (element: BlockCoreData) in
                return LightBlock.fromCoreData(crModel: element)
            }
            
            completion(blocks, nil)
        }
        
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
    }
    
    /// Fetch the latest full block
    func getLatestBlock() throws -> FullBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.fetchLimit = 1
        requestBlock.returnsObjectsAsFaults = false
        let sortDescriptor = NSSortDescriptor(key: "number", ascending: false)
        requestBlock.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            return LightBlock.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    /// Fetch the latest light block
    func getLatestBlock() throws -> LightBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.fetchLimit = 1
        requestBlock.returnsObjectsAsFaults = false
        let sortDescriptor = NSSortDescriptor(key: "number", ascending: false)
        requestBlock.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            return LightBlock.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func getLatestBlock(completion: @escaping (LightBlock?, NodeError?) -> Void) {
        let fetchRequest = NSFetchRequest<BlockCoreData>(entityName: EntityName.blockCoreData.rawValue)
        fetchRequest.fetchLimit = 1
        let sortDescriptor = NSSortDescriptor(key: "number", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
                
        // Initialize Asynchronous Fetch Request
        let asynchronousFetchRequest = NSAsynchronousFetchRequest<BlockCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            guard let results = asynchronousFetchResult.finalResult else { return }
            let blocks: [LightBlock] = results.compactMap { (element: BlockCoreData) in
                return LightBlock.fromCoreData(crModel: element)
            }
            
            completion(blocks.first, nil)
        }
        
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
    }
    
    func getLatestBlock(completion: @escaping (FullBlock?, NodeError?) -> Void) {
        let fetchRequest = NSFetchRequest<BlockCoreData>(entityName: EntityName.blockCoreData.rawValue)
        fetchRequest.fetchLimit = 1
        let sortDescriptor = NSSortDescriptor(key: "number", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Asynchronous Fetch Request
        let asynchronousFetchRequest = NSAsynchronousFetchRequest<BlockCoreData>(fetchRequest: fetchRequest) { (asynchronousFetchResult) -> Void in
            guard let results = asynchronousFetchResult.finalResult else { return }
            let blocks: [FullBlock] = results.compactMap { (element: BlockCoreData) in
                return LightBlock.fromCoreData(crModel: element)
            }
            
            if blocks.count == 0 {
                completion(nil, nil)
            } else {
                completion(blocks.first, nil)
            }
        }
        
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
    }
    
    /// Fetch all blocks in a full block form
    func getAllBlocks() throws -> [FullBlock] {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        
        do {
            let results = try context.fetch(requestBlock)
            return results.compactMap { LightBlock.fromCoreData(crModel: $0) }
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    /// Fetch all blocks in a full block blockchain form
    func getAllBlocks() throws -> Blockchain<FullBlock> {
        let blocks: [FullBlock] = try getAllBlocks()
        var blockChain = Blockchain<FullBlock>()
        blockChain.append(contentsOf: blocks)
        return blockChain
    }
    
    /// Fetch all blocks in a light block form
    func getAllBlocks() throws -> [LightBlock] {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        
        do {
            let results = try context.fetch(requestBlock)
            return results.compactMap { LightBlock.fromCoreData(crModel: $0) }
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    /// Fetch all blocks in a light block blockchain form
    func getAllBlocks() throws -> Blockchain<LightBlock> {
        let blocks: [LightBlock] = try getAllBlocks()
        var blockChain = Blockchain<LightBlock>()
        blockChain.append(contentsOf: blocks)
        return blockChain
    }
    
    /// Save block using a light block
    /// Block should searchable by the ID, which is the block hash, as well as the block number.
    func saveBlock(block: LightBlock, completion: @escaping (NodeError?) throws -> Void) throws {
        /// Halt if a block already exists
        if let existingBlock: LightBlock = try getBlock(block.id), existingBlock == block {
            return
        }
        
        guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.blockCoreData.rawValue, into: context) as? BlockCoreData else { return }
        let number = Int32(block.number)
        entity.id = block.id
        entity.number = number
        entity.data = block.data
        
        do {
            try context.save()
            try completion(nil)
        } catch {
            try completion(NodeError.generalError("Block save error"))
        }
    }
    
    /// Save block using a full block
    func saveBlock(block: FullBlock, completion: @escaping (NodeError?) throws -> Void) throws {
        let lightBlock = try LightBlock(data: block)
        try saveBlock(block: lightBlock, completion: completion)
    }
    
    func saveRelationalBlock(block: LightBlock, completion: @escaping (NodeError?) -> Void) {
        guard let fullBlock = block.decode() else {
            completion(.generalError("Unable conver the light block."))
            return
        }
        saveRelationalBlock(block: fullBlock, completion: completion)
    }
    
    /// Save a block with all the transactions and accounts in a one-to-many relational way
    func saveRelationalBlock(block: FullBlock, completion: @escaping (NodeError?) -> Void) {
        /// Halt if a block already exists
        let existingBlock: LightBlock? = try? getBlock(block.hash.toHexString())
        if existingBlock != nil {
            completion(NodeError.generalError("Block already exists"))
            return
        }
        
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "saveTransactionContext"
        taskContext.transactionAuthor = "transactionSaver"
        
        taskContext.performAndWait {
            do {
                let blockObject = BlockCoreData(context: taskContext)
                let lightBlock = try LightBlock(data: block)
                blockObject.id = lightBlock.id
                let number = Int32(lightBlock.number)
                blockObject.number = number
                blockObject.data = lightBlock.data
                
                if let transactions = block.transactions {
                    for tx in transactions {
                        let transactionObject = TransactionCoreData(context: taskContext)
                        transactionObject.id = tx.id
                        transactionObject.data = tx.data
                        blockObject.addToTransactions(transactionObject)
                    }
                }
                
                /// TODO: either fetch the existing accounts and delete them prior to saving the new ones
                /// or when the accounts are normally fetched, fetch the accounts that is tied to the lastest block only.
                if let accounts = block.accounts {
                    for account in accounts {
                        let stateObject = StateCoreData(context: taskContext)
                        stateObject.id = account.id
                        stateObject.data = account.data
                        blockObject.addToStates(stateObject)
                    }
                }
                
                try taskContext.save()
                completion(nil)
            } catch {
                completion(NodeError.generalError("Block save error"))
            }
        }
    }
    
    /// Save an array of full blocks
    @available(iOS 15.0.0, *)
    func saveBlocks(blocks: [FullBlock], completion: @escaping (NodeError?) throws -> Void) async throws {
        /// Only save blocks that don't already exist
        var newBlocks = blocks
        try blocks.forEach {
            guard let existingBlock: FullBlock = try getBlock($0.hash.toHexString()) else { return }
            newBlocks.removeAll(where: { $0 == existingBlock })
        }
        
        try await context.perform { [weak self] in // runs asynchronously
            while(true) { // loop through each batch of inserts. Your implementation may vary.
                try autoreleasepool { // auto release objects after the batch save
                    
                    for block in newBlocks {
                        let lightBlock = try LightBlock(data: block)
                        try self?.saveBlock(block: lightBlock, completion: completion)
                    }
                }
                
                // only save once per batch insert
                do {
                    try self?.context.save()
                } catch {
                    print(error)
                }
                
                self?.context.reset()
            }
        }
    }
    
    /// Delete a block using the block hash
    /// For deleting erroneous blocks?
    func deleteBlock(id: String, completion: @escaping (NodeError?) throws -> Void) {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let result = try context.fetch(requestBlock)
            for item in result {
                context.delete(item)
            }
            
            try context.save()
            try completion(nil)
        } catch {
            try? completion(NodeError.generalError("Block deletion error"))
        }
    }
    
    /// Delete a block using a block number
    /// For deleting erroneous blocks?
    func deleteBlock(number: BigUInt, completion: @escaping (NodeError?) throws -> Void) {
        let convertedNumber = Int32(number)
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "number == %@", convertedNumber as CVarArg)
        
        do {
            let result = try context.fetch(requestBlock)
            for item in result {
                context.delete(item)
            }
            
            try context.save()
            try completion(nil)
        } catch {
            try? completion(NodeError.generalError("Block deletion error"))
        }
    }
    
    func deleteAllBlocks(completion: @escaping (NodeError?) throws -> Void) {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        
        do {
            let result = try context.fetch(requestBlock)
            for item in result {
                context.delete(item)
            }
            
            try context.save()
            try completion(nil)
        } catch {
            try? completion(NodeError.generalError("Block deletion error"))
        }
    }
}
