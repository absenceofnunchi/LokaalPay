//
//  WalletCoreData+CoreDataProperties.swift
//  
//
//  Created by J C on 2022-02-06.
//
//

import Foundation
import CoreData


extension WalletCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WalletCoreData> {
        return NSFetchRequest<WalletCoreData>(entityName: "WalletCoreData")
    }

    @NSManaged public var address: String?
    @NSManaged public var data: Data?

}
