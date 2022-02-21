//
//  ReceiptCoreData+CoreDataProperties.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-20.
//
//

import Foundation
import CoreData


extension ReceiptCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReceiptCoreData> {
        return NSFetchRequest<ReceiptCoreData>(entityName: "ReceiptCoreData")
    }

    @NSManaged public var id: String?
    @NSManaged public var data: Data?

}

extension ReceiptCoreData : Identifiable {

}
