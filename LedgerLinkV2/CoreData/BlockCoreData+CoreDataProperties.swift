//
//  BlockCoreData+CoreDataProperties.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-02.
//
//

import Foundation
import CoreData


extension BlockCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlockCoreData> {
        return NSFetchRequest<BlockCoreData>(entityName: "BlockCoreData")
    }

    @NSManaged public var data: Data?
    @NSManaged public var id: String?
    @NSManaged public var number: Int32
    @NSManaged public var transactions: NSSet?
    @NSManaged public var states: NSSet?
    @NSManaged public var receipts: NSSet?

}

// MARK: Generated accessors for transactions
extension BlockCoreData {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: TransactionCoreData)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: TransactionCoreData)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

// MARK: Generated accessors for states
extension BlockCoreData {

    @objc(addStatesObject:)
    @NSManaged public func addToStates(_ value: StateCoreData)

    @objc(removeStatesObject:)
    @NSManaged public func removeFromStates(_ value: StateCoreData)

    @objc(addStates:)
    @NSManaged public func addToStates(_ values: NSSet)

    @objc(removeStates:)
    @NSManaged public func removeFromStates(_ values: NSSet)

}

// MARK: Generated accessors for receipts
extension BlockCoreData {

    @objc(addReceiptsObject:)
    @NSManaged public func addToReceipts(_ value: ReceiptCoreData)

    @objc(removeReceiptsObject:)
    @NSManaged public func removeFromReceipts(_ value: ReceiptCoreData)

    @objc(addReceipts:)
    @NSManaged public func addToReceipts(_ values: NSSet)

    @objc(removeReceipts:)
    @NSManaged public func removeFromReceipts(_ values: NSSet)

}

extension BlockCoreData : Identifiable {

}
