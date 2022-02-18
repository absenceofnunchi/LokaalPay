//
//  ContractMethods.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-16.
//

import Foundation

enum ContractMethods: String {
    case transferValue
    case blockchainDownloadRequest
    case blockchainDownloadResponse
    
    var data: Data? {
        switch self {
            case .transferValue:
                return Data(self.rawValue.utf8)
            case .blockchainDownloadRequest:
                return Data(self.rawValue.utf8)
            case .blockchainDownloadResponse:
                return Data(self.rawValue.utf8)
        }
    }
}
