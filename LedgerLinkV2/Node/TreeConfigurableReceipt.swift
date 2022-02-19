//
//  TreeConfigurableReceipt.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-12.
//

import Foundation
import web3swift

public struct TreeConfigurableReceipt: LightConfigurable {
    typealias T = TransactionReceipt
    var id: Data // Receipt hash
    var data: Data // RLP encoded TransactionReceipt
    
    public init(data: TransactionReceipt) throws {
        guard let encoded = data.encode() else {
            throw NodeError.encodingError
        }
        
        self.data = encoded
        self.id = encoded.sha256()
    }
    
    public func decode() -> TransactionReceipt? {
        do {
            return try TransactionReceipt.fromRaw(data)
        } catch {
            return nil
        }
    }
    
    public static func < (lhs: TreeConfigurableReceipt, rhs: TreeConfigurableReceipt) -> Bool {
        return lhs.id.toHexString() < rhs.id.toHexString()
    }
}
