//
//  TreeConfigurableAccount.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-11.
//

/*
 Abstract:
 Configured to be Codable (to be hashed thorough Hashable), Hashable (for Merkle tree), and Comparable (for Red Black tree).
 The "id" property is address to be searchable by the address in Red Black tree.
 The "account" property is RLP seriaalized to be compact and to be space efficient.
 RLP encoding is more space efficient than the "lzfse" compression.
 */

import Foundation
import BigInt
import web3swift

public struct TreeConfigurableAccount: LightConfigurable {
    typealias T = Account
    var id: String /// Address
    var data: Data /// RLP encoded and compressed Account
    var dictionaryValue: [String: Any] {
        [
            "id": id,
            "data": data
        ]
    }
    
    /// Account is already RLP encoded
    public init(address: String, rlpAccount: Data) throws {
        guard let compressed = rlpAccount.compressed else {
            throw NodeError.compressionError
        }
        
        self.id = address
        self.data = compressed
    }

    /// id: Address string, data: rlp encoded data
    init(id: String, data: Data) {
        self.id = id
        self.data = data
    }
    
    init(data: Account) throws {
        guard let encoded = data.encode() else {
            throw NodeError.encodingError
        }
        
        guard let compressed = encoded.compressed else {
            throw NodeError.compressionError
        }
        
        self.id = data.address.address
        self.data = compressed
    }

    public func decode() -> Account? {
        guard let decompressed = data.decompressed else {
            return nil
        }
        
        return Account.fromRaw(decompressed)
    }
}

extension TreeConfigurableAccount: Equatable {
    public static func < (lhs: TreeConfigurableAccount, rhs: TreeConfigurableAccount) -> Bool {
        return lhs.id < rhs.id
//        return lhs.id.hashValue < rhs.id.hashValue
    }
    
    /// The model will only be compared against the addresses in the Red Black tree.
    /// This means even if other attributes like the balance and nonce, etc are different, two models would be considered a single account.
    /// This is to prevent duplicate accounts as well as to only search by the account number when searched in the tree.
    /// When searched and updated in the tree, account A with a balance of 10 can be used to search an account A with a balance of 0.
    public static func == (lhs: TreeConfigurableAccount, rhs: TreeConfigurableAccount) -> Bool {
        return lhs.id == rhs.id
    }
}
