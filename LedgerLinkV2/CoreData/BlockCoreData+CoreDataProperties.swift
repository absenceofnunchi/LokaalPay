//
//  BlockCoreData+CoreDataProperties.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-21.
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

}

extension BlockCoreData : Identifiable {

}
