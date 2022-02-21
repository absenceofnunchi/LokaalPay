//
//  TransactionCoreData+CoreDataProperties.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-20.
//
//

import Foundation
import CoreData


extension TransactionCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionCoreData> {
        return NSFetchRequest<TransactionCoreData>(entityName: "TransactionCoreData")
    }

    @NSManaged public var id: String?
    @NSManaged public var data: Data?

}

extension TransactionCoreData : Identifiable {

}
