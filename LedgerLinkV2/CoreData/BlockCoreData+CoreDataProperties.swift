//
//  BlockCoreData+CoreDataProperties.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-18.
//
//

import Foundation
import CoreData


extension BlockCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BlockCoreData> {
        return NSFetchRequest<BlockCoreData>(entityName: "BlockCoreData")
    }

    @NSManaged public var id: Data?
    @NSManaged public var number: Data?
    @NSManaged public var data: Data?

}

extension BlockCoreData : Identifiable {

}
