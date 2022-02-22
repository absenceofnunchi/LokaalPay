//
//  TransactionCoreData+CoreDataProperties.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-21.
//
//

import Foundation
import CoreData


extension TransactionCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionCoreData> {
        return NSFetchRequest<TransactionCoreData>(entityName: "TransactionCoreData")
    }

    @NSManaged public var data: Data?
    @NSManaged public var id: String?

}

extension TransactionCoreData : Identifiable {

}
