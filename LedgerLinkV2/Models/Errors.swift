//
//  Errors.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import Foundation

public enum NodeError: Error {
    case encodingError
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
    case rlpEncodingError
    case decodingError
    case merkleTreeBuildError
    case compressionError
    case treeSearchError
    case notFound
    case hashingError
    case generalError(String)
}
