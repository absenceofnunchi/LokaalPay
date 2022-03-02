//
//  StateCoreData+CoreDataProperties.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-02.
//
//

import Foundation
import CoreData


extension StateCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StateCoreData> {
        return NSFetchRequest<StateCoreData>(entityName: "StateCoreData")
    }

    @NSManaged public var data: Data?
    @NSManaged public var id: String?
    @NSManaged public var ofBlock1: BlockCoreData?

}

extension StateCoreData : Identifiable {

}
