//
//  StateCoreData+CoreDataProperties.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-21.
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

}

extension StateCoreData : Identifiable {

}
