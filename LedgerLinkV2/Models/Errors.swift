//
//  Errors.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import Foundation

enum WalletError: Error {
    case walletRetrievalError
    case walletDeleteError
    case walletSaveError
    case walletCreateError
    case walletAddressFetchError
    case hexConversionError
    case walletCountError
    case walletEncodeError
    case failureToFetchOldPassword
    case failureToRegeneratePassword
}

enum TxError: Error {
    case encodingError
    case generalError(String)
    case walletError(WalletError)
}

public enum NodeError: Error {
    case encodingError
    case rlpEncodingError
    case decodingError
    case merkleTreeBuildError
    case compressionError
    case treeSearchError
    case notFound
    case hashingError
    case generalError(String)
}


