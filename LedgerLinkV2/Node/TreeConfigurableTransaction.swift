//
//  TreeConfigurableTransaction.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-10.
//

/*
 Abstract:
 Converts the RLP encoded data to a transaction hash as well as a compressed version of the data.
 Conforms to TreeConfigurable which are hashable, comparable, and Codable.
 All of this ensures that it can be stored in the Merkle tree and the Red Black tree, searchable, and compact.
 */

import Foundation
import web3swift

public struct TreeConfigurableTransaction: LightConfigurable, PropertyLoopable {
    typealias T = EthereumTransaction
    var id: String // transaction hash
    var data: Data // RLP encoded and compressed EthereumTransaction
    
    public init(id: String, data: Data) {
        self.id = id
        self.data = data
    }
    
    /// Transaction is already RLP encoded such as when received from another device.
    public init(rlpTransaction: Data) throws {
        guard let compressed = rlpTransaction.compressed else {
            throw NodeError.compressionError
        }
        
        self.id = compressed.sha256().toHexString()
        self.data = compressed
    }
    
    public init(data: EthereumTransaction) throws {
        guard let encoded = data.encode() else {
            throw NodeError.encodingError
        }
        
        try self.init(rlpTransaction: encoded) 
    }
    
    
    func decode() -> EthereumTransaction? {
        guard let decompressed = data.decompressed else {
            return nil
        }
        
        return EthereumTransaction.fromRaw(decompressed)
    }
    
    static public func < (lhs: TreeConfigurableTransaction, rhs: TreeConfigurableTransaction) -> Bool {
        return lhs.id < rhs.id
    }
    
    static public func == (lhs: TreeConfigurableTransaction, rhs: TreeConfigurableTransaction) -> Bool {
        return (lhs.id == rhs.id && lhs.data == rhs.data)
    }
}
