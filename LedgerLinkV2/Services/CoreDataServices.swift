//
//  CoreDataServices.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import UIKit
import CoreData
import BigInt

final class LocalStorage {
    static let shared = LocalStorage()
    var coreDataStack: CoreDataStack!
    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext!
    
    init() {
        coreDataStack = CoreDataStack()
        container = coreDataStack.persistentContainer
        context = container.viewContext
    }
    
    enum EntityName: String {
        case walletCoreData = "WalletCoreData"
        case blockCoreData = "BlockCoreData"
    }
}

// MARK: - Wallets

extension LocalStorage {
    func getWallet() throws -> KeyWalletModel? {
        let requestWallet: NSFetchRequest<WalletCoreData> = WalletCoreData.fetchRequest()
        
        do {
            let results = try context.fetch(requestWallet)
            guard let result = results.first else { return nil }
            return KeyWalletModel.fromCoreData(crModel: result)
        } catch {
            throw WalletError.walletRetrievalError
        }
    }
    
    func saveWallet(wallet: KeyWalletModel, completion: @escaping (WalletError?) throws -> Void) {
        container.performBackgroundTask { [weak self](context) in
            
            self?.deleteWallet { (error) throws in
                if let error = error {
                    try completion(error)
                }
                
                guard let entity = NSEntityDescription.insertNewObject(forEntityName: EntityName.walletCoreData.rawValue, into: context) as? WalletCoreData else { return }
                entity.address = wallet.address
                entity.data = wallet.data
                
                do {
                    try context.save()
                    try completion(nil)
                } catch {
                    try completion(.walletSaveError)
                }
            }
        }
    }
    
    func deleteWallet(completion: @escaping (WalletError?) throws -> Void) {
        let requestWallet: NSFetchRequest<WalletCoreData> = WalletCoreData.fetchRequest()
        
        do {
            let result = try context.fetch(requestWallet)
            for item in result {
                context.delete(item)
            }
            
            try context.save()
            try completion(nil)
        } catch {
            try? completion(.walletDeleteError)
        }
    }
}

// MARK: - Blocks
/// Operations for saving and fetching blocks.  All blocks are saved as light blocks.
extension LocalStorage {
    /// Fetch a light block by its block hash
    func getBlock(id: String) throws -> LightBlock? {
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
    func getBlock(id: String) throws -> FullBlock? {
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
    func getBlock(number: BigUInt) throws -> LightBlock? {
        let convertedNumber = UInt32(number)
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "number == %i", convertedNumber)
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            return LightBlock.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    /// Fetch a full block by its block number
    func getBlock(number: BigUInt) throws -> FullBlock? {
        let convertedNumber = Int32(number)
        print("convertedNumber", convertedNumber)
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "number == %i", convertedNumber)
        
        do {
            let results = try context.fetch(requestBlock)
            print("results", results)
            guard let result = results.first else { return nil }
            return LightBlock.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }

    /// Fetch the latest full block
    func getLatestBlock() throws -> FullBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        let allElementsCount = try context.count(for: requestBlock)
        requestBlock.fetchLimit = 1
        requestBlock.fetchOffset = allElementsCount - 1
        requestBlock.returnsObjectsAsFaults = false
        
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
        let allElementsCount = try context.count(for: requestBlock)
        requestBlock.fetchLimit = 1
        requestBlock.fetchOffset = allElementsCount - 1
        requestBlock.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            let block: LightBlock? = LightBlock.fromCoreData(crModel: result)
            return block
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
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
    
    /// Save an array of full blocks
    @available(iOS 15.0.0, *)
    func saveBlocks(blocks: [FullBlock], completion: @escaping (NodeError?) throws -> Void) async throws {
        try await context.perform { [weak self] in // runs asynchronously
            while(true) { // loop through each batch of inserts. Your implementation may vary.
                try autoreleasepool { // auto release objects after the batch save
                    
                    for block in blocks {
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

extension LocalStorage {
    
}

// MARK: - Core Data stack

/*
 The Core Data instantiation is out of AppDelegate because there are many cases involving closures that require moving back and forth from the background thread.
 */
class CoreDataStack: NSObject {
    let moduleName = "LedgerLinkV2"
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: moduleName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var applicationDocumentsDirectory: URL = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let persistenStoreURL = self.applicationDocumentsDirectory.appendingPathComponent("\(moduleName).sqlite")
        
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistenStoreURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption : true])
        } catch {
            fatalError("Persistent Store error: \(error)")
        }
        return coordinator
    }()
    
    lazy var context: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        return context
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: moduleName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
