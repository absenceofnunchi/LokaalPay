//
//  ContractMethods.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-16.
//

import Foundation

enum ContractMethods: String {
    case transferValue
    case createAccount
    case blockchainDownloadRequest
    case blockchainDownloadResponse
    
    var data: Data? {
        return Data(self.rawValue.utf8)
    }
}
