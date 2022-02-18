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

public struct TreeConfigurableAccount: TreeConfigurable {
    typealias T = Account
    var id: Data /// Address
    var data: Data /// RLP encoded Account
    
    /// Account is already RLP encoded
    public init(id: Data, rlpAccount: Data) {
        self.id = id
        self.data = rlpAccount
    }
    
    public init(data: Account) throws {
        self.id = data.address.addressData
        
        guard let encodedAccount = data.encode() else {
            throw NodeError.encodingError
        }
        self.data = encodedAccount
    }

    public init(toCompress account: Account) throws {
        self.id = account.address.addressData
        
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(account)
            guard let compressed = encoded.compressed else {
                throw NodeError.compressionError
            }
            self.data = compressed
        } catch {
            throw NodeError.encodingError
        }
    }
    
    public func decode() -> Account? {
        return Account.fromRaw(data)
    }
    
    public func getAccountFromCompressed() -> Account? {
        guard let decompressed = try? (data as NSData).decompressed(using: .lzfse) else {
            return nil
        }
        let data = Data(referencing: decompressed)
        
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(Account.self, from: data)
            return decoded
        } catch {
            return nil
        }
    }
}

extension TreeConfigurableAccount: Equatable {
    public static func < (lhs: TreeConfigurableAccount, rhs: TreeConfigurableAccount) -> Bool {
        return lhs.id.toHexString() < rhs.id.toHexString()
//        return lhs.id.hashValue < rhs.id.hashValue
    }
    
    /// The model will only be compared against the addresses in the Red Black tree.
    /// This means even if other attributes like the balance and nonce, etc are different, two models would be considered a single account.
    /// This is to prevent duplicate accounts as well as to only search by the account number when searched in the tree.
    /// When searched and updated in the tree, account A with a balance of 10 can be used to search an account A with a balance of 0.
    public static func == (lhs: TreeConfigurableAccount, rhs: TreeConfigurableAccount) -> Bool {
        return lhs.id.toHexString() == rhs.id.toHexString()
    }
}
