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

public struct TreeConfigurableTransaction: TreeConfigurable {
    typealias T = EthereumTransaction
    var id: Data // transaction hash
    var data: Data // RLP encoded EthereumTransaction
    
    /// Transaction is already RLP encoded such as when received from another device.
    public init(rlpTransaction: Data) {
        let hash = rlpTransaction.sha3(.keccak256)
        self.id = hash

        
        self.data = rlpTransaction
    }
    
    public init(data: EthereumTransaction) throws {
        guard let encoded = data.encode() else {
            throw NodeError.encodingError
        }
        
        self.init(rlpTransaction: encoded)
    }
    
    func decode() -> EthereumTransaction? {
        return EthereumTransaction.fromRaw(data)
    }
    
    func getTransaction() -> EthereumTransaction? {
        guard let decompressed = data.decompressed else { return nil }
        let ethereumTransaction = EthereumTransaction.fromRaw(decompressed)
        return ethereumTransaction
    }
    
    static public func < (lhs: TreeConfigurableTransaction, rhs: TreeConfigurableTransaction) -> Bool {
        return lhs.id.toHexString() < rhs.id.toHexString()
    }
    
    static public func == (lhs: TreeConfigurableTransaction, rhs: TreeConfigurableTransaction) -> Bool {
        return lhs.id == rhs.id
    }
}
