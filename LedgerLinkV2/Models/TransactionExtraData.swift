//
//  TransactionExtraData.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-17.
//

/*
 Abstract:
 Used for sending and receiving transaction parameters such as the contract method.
 */

import Foundation

struct TransactionExtraData: Codable {
    var contractMethod: Data
    var account: Account? = nil
}
