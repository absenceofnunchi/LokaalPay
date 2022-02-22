//
//  CoreDataServices.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import Foundation
import CoreData
import BigInt
import web3swift

final class LocalStorage {
    static let shared = LocalStorage()
    var coreDataStack: CoreDataStack!
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!

    init() {
        coreDataStack = CoreDataStack()
        container = coreDataStack.persistentContainer
        context = container.viewContext
    }
    
    enum EntityName: String {
        case walletCoreData = "WalletCoreData"
        case blockCoreData = "BlockCoreData"
        case stateCoreData = "StateCoreData"
        case transactionCoreData = "TransactionCoreData"
        case receiptCoreData = "ReceiptCoreData"

        static let stateDescription = StateCoreData.entity()
        static let transactionDescription = TransactionCoreData.entity()
    }
    
    func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    @available(iOS 14.0, *)
    func newBatchInsertRequest(with accounts: [TreeConfigurableAccount]) -> NSBatchInsertRequest {
        var index = 0
        let total = accounts.count

        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: EntityName.stateDescription, dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: accounts[index].dictionaryValue)
            index += 1
            return false
        })
        return batchInsertRequest
    }
    
    @available(iOS 14.0, *)
    func newBatchInsertRequest(with transactions: [TreeConfigurableTransaction]) -> NSBatchInsertRequest {
        var index = 0
        let total = transactions.count
        
        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: TransactionCoreData.entity(), dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: transactions[index].dictionaryValue)
            index += 1
            return false
        })
        return batchInsertRequest
    }
//    
//    @available(iOS 14.0, *)
//    func newBatchInsertRequest(with receipts: [TreeConfigurableReceipt]) -> NSBatchInsertRequest {
//        var index = 0
//        let total = receipts.count
//        
//        // Provide one dictionary at a time when the closure is called.
//        let batchInsertRequest = NSBatchInsertRequest(entity: ReceiptCoreData.entity(), dictionaryHandler: { dictionary in
//            guard index < total else { return true }
//            dictionary.addEntries(from: receipts[index].dictionaryValue)
//            index += 1
//            return false
//        })
//        return batchInsertRequest
//    }
//    
//    func newBatchInsertRequest<T: LightConfigurable>(with elements: [T]) -> NSBatchInsertRequest? {
//        var index = 0
//        let total = elements.count
//
//        var entity: NSEntityDescription!
//        switch elements[0] {
//            case is TreeConfigurableAccount:
//                entity = StateCoreData.entity()
//                break
//            case is TreeConfigurableTransaction:
//                entity = TransactionCoreData.entity()
//                break
//            case is TreeConfigurableReceipt:
//                entity = ReceiptCoreData.entity()
//                break
//            default:
//                break
//        }
//        print("TransactionCoreData.entity()", TransactionCoreData.entity())
//        print("entity", entity)
//        guard let entity = entity else { return nil }
//
//        // Provide one dictionary at a time when the closure is called.
//        let batchInsertRequest = NSBatchInsertRequest(entity: entity, dictionaryHandler: { dictionary in
//            guard index < total else { return true }
//            dictionary.addEntries(from: elements[index].dictionaryValue)
//            index += 1
//            return false
//        })
//        return batchInsertRequest
//    }
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



// MARK: - Core Data stack

/*
 The Core Data instantiation is out of AppDelegate because there are many cases involving closures that require moving back and forth from the background thread.
 */
class CoreDataStack: NSObject {
    let moduleName = "LedgerLinkV2"
//
//    lazy var applicationDocumentsDirectory: URL = {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
//    }()
//
//    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
//        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
//
//        let persistenStoreURL = self.applicationDocumentsDirectory.appendingPathComponent("\(moduleName).sqlite")
//
//        do {
//            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistenStoreURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption : true])
//        } catch {
//            fatalError("Persistent Store error: \(error)")
//        }
//        return coordinator
//    }()
//
//    lazy var context: NSManagedObjectContext = {
//        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//
//        context.persistentStoreCoordinator = self.persistentStoreCoordinator
//        return context
//    }()
    
//    lazy var persistentContainer: NSPersistentContainer = {
//        /*
//         The persistent container for the application. This implementation
//         creates and returns a container, having loaded the store for the
//         application to it. This property is optional since there are legitimate
//         error conditions that could cause the creation of the store to fail.
//         */
//        let container = NSPersistentContainer(name: moduleName)
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//
//                /*
//                 Typical reasons for an error here include:
//                 * The parent directory does not exist, cannot be created, or disallows writing.
//                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                 * The device is out of space.
//                 * The store could not be migrated to the current model version.
//                 Check the error message to determine what the actual problem was.
//                 */
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//
//        guard let description = container.persistentStoreDescriptions.first else {
//            fatalError("Failed to retrieve a persistent store description.")
//        }
//
//        // Enable persistent store remote change notifications
//        /// - Tag: persistentStoreRemoteChange
//        description.setOption(true as NSNumber,
//                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
//
//        // Enable persistent history tracking
//        /// - Tag: persistentHistoryTracking
//        description.setOption(true as NSNumber,
//                              forKey: NSPersistentHistoryTrackingKey)
//
//
//        // This sample refreshes UI by consuming store changes via persistent history tracking.
//        /// - Tag: viewContextMergeParentChanges
//        container.viewContext.automaticallyMergesChangesFromParent = false
//        container.viewContext.name = "viewContext"
//        /// - Tag: viewContextMergePolicy
//        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//        container.viewContext.undoManager = nil
//        container.viewContext.shouldDeleteInaccessibleFaults = true
//
//        return container
//    }()
    var persistentContainer: NSPersistentContainer!
    
    override init() {
        super.init()
//        guard let modelURL = Bundle.main.url(forResource: moduleName, withExtension: "momd"),
//              let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
//            return
//        }
//        self.persistentContainer = NSPersistentContainer(name: moduleName, managedObjectModel: managedObjectModel)
        self.persistentContainer = NSPersistentContainer(name: moduleName)
        self.persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        guard let description = self.persistentContainer.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber,
                              forKey: NSPersistentHistoryTrackingKey)
        
        
        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = false
        self.persistentContainer.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.persistentContainer.viewContext.undoManager = nil
        self.persistentContainer.viewContext.shouldDeleteInaccessibleFaults = true
    }
    
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
    
    struct ManagedObjectModels {
        static let StateCoreData: NSManagedObjectModel = {
            return buildModel(named: "StateCoreData")
        }()
        
        static let TransactionCoreData: NSManagedObjectModel = {
            return buildModel(named: "TransactionCoreData")
        }()
        
        private static func buildModel(named: String) -> NSManagedObjectModel {
            let url = Bundle.main.url(forResource: named, withExtension: "momd")!
            let managedObjectModel = NSManagedObjectModel.init(contentsOf: url)
            return managedObjectModel!
        }
    }
}

public extension NSManagedObject {
    convenience init(usedContext: NSManagedObjectContext) {
        let name = String(describing: type(of: self))
        let entity = NSEntityDescription.entity(forEntityName: name, in: usedContext)!
        self.init(entity: entity, insertInto: usedContext)
    }
}
