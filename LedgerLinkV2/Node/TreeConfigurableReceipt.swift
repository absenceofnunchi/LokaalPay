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
    var id: String // Receipt hash
    var data: Data // RLP encoded then compressed TransactionReceipt
    
    public init(data: TransactionReceipt) throws {
        guard let encoded = data.encode() else {
            throw NodeError.encodingError
        }
        
        guard let compressed = encoded.compressed else {
            throw NodeError.compressionError
        }
        
        self.id = compressed.sha256().toHexString()
        self.data = compressed
    }
    
    public func decode() -> TransactionReceipt? {
        guard let decompressed = data.decompressed else {
            return nil
        }
        
        do {
            return try TransactionReceipt.fromRaw(decompressed)
        } catch {
            return nil
        }
    }
    
    public static func < (lhs: TreeConfigurableReceipt, rhs: TreeConfigurableReceipt) -> Bool {
        return lhs.id < rhs.id
    }
}
