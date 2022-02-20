//
//  CoreDataServices.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import UIKit
import CoreData

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
                
                guard let entity = NSEntityDescription.insertNewObject(forEntityName: "WalletCoreData", into: context) as? WalletCoreData else { return }
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

extension LocalStorage {
//    func getBlock(id: Data) throws -> BlockModel? {
//        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
//        requestBlock.predicate = NSPredicate(format: "id = '%@'", id as NSData)
//
//        do {
//            let results = try context.fetch(requestBlock)
//            guard let result = results.first else { return nil }
//            return BlockModel.fromCoreData(crModel: result)
//        } catch {
//            throw NodeError.generalError("Unable to fetch blocks")
//        }
//    }
//
    func getBlock(id: String) throws -> LightBlock? {
        print("id", id)
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        print("requestBlock", requestBlock)
        do {
            let results = try context.fetch(requestBlock)
            print("results", results)
            guard let result = results.first else { return nil }
            return BlockModel.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func getBlock(id: String) throws -> ChainBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        requestBlock.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            print("result", result)
            return BlockModel.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
//
//    func getBlock(number: Data) throws -> BlockModel? {
//        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
//        requestBlock.predicate = NSPredicate(format: "id == '%@'", number as NSData)
//
//        do {
//            let results = try context.fetch(requestBlock)
//            guard let result = results.first else { return nil }
//            return BlockModel.fromCoreData(crModel: result)
//        } catch {
//            throw NodeError.generalError("Unable to fetch blocks")
//        }
//    }
//
    func getLatestBlock() throws -> BlockModel? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        let allElementsCount = try context.count(for: requestBlock)
        requestBlock.fetchLimit = 1
        requestBlock.fetchOffset = allElementsCount - 1
        requestBlock.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            return BlockModel.fromCoreData(crModel: result)
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func getLatestBlock() throws -> LightBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        let allElementsCount = try context.count(for: requestBlock)
        requestBlock.fetchLimit = 1
        requestBlock.fetchOffset = allElementsCount - 1
        requestBlock.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            let block: LightBlock? = BlockModel.fromCoreData(crModel: result)
            return block
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func getLatestBlock() throws -> ChainBlock? {
        let requestBlock: NSFetchRequest<BlockCoreData> = BlockCoreData.fetchRequest()
        let allElementsCount = try context.count(for: requestBlock)
        requestBlock.fetchLimit = 1
        requestBlock.fetchOffset = allElementsCount - 1
        requestBlock.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(requestBlock)
            guard let result = results.first else { return nil }
            let block: ChainBlock? = BlockModel.fromCoreData(crModel: result)
            return block
        } catch {
            throw NodeError.generalError("Unable to fetch blocks")
        }
    }
    
    func saveBlock(block: BlockModel, completion: @escaping (NodeError?) throws -> Void) throws {
        guard let entity = NSEntityDescription.insertNewObject(forEntityName: "BlockCoreData", into: context) as? BlockCoreData else { return }
        entity.id = block.id
        entity.number = block.number.serialize()
        entity.data = block.data
        
        do {
            try context.save()
            try completion(nil)
        } catch {
            try completion(NodeError.generalError("Block save error"))
        }
    }
}

// MARK: - Core Data stack


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
