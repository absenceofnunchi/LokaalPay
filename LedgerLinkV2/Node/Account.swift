//
//  Account.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-08.
//

import Foundation
import BigInt
import web3swift

public struct Account: Equatable {
    var address: EthereumAddress
    var nonce: BigUInt
    var balance: BigUInt = 0
    var codeHash: String = "0x"
    var storageRoot: String = "0x"
    
    init(_ data: Data) throws {
        guard let decompressed = data.decompressed else {
            throw NodeError.compressionError
        }
        
        guard let account = Account.fromRaw(decompressed) else {
            throw NodeError.decodingError
        }
        
        self.address = account.address
        self.nonce = account.nonce
        self.balance = account.balance
        self.codeHash = account.codeHash
        self.storageRoot = account.storageRoot
    }
    
    init(address: EthereumAddress, nonce: BigUInt, balance: BigUInt = 0, codeHash: String = "0x", storageRoot: String = "0x") {
        self.address = address
        self.nonce = nonce
        self.balance = balance
        self.codeHash = codeHash
        self.storageRoot = storageRoot
    }
}

extension Account: Codable {
    enum CodingKeys: String, CodingKey {
        case address
        case nonce
        case balance
        case codeHash
        case storageRoot
    }
    
    public func encode(to encoder: Encoder) throws {
        var encoder = encoder.container(keyedBy: CodingKeys.self)
        try encoder.encode(address, forKey: .address)
        try encoder.encode(nonce, forKey: .nonce)
        try encoder.encode(balance, forKey: .balance)
        try encoder.encode(codeHash, forKey: .codeHash)
        try encoder.encode(storageRoot, forKey: .storageRoot)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let address: EthereumAddress = try container.decode(EthereumAddress.self, forKey: .address)
        let nonce: BigUInt = try container.decode(BigUInt.self, forKey: .nonce)
        let balance: BigUInt = try container.decode(BigUInt.self, forKey: .balance)
        let codeHash: String = try container.decode(String.self, forKey: .codeHash)
        let storageRoot: String = try container.decode(String.self, forKey: .address)
        
        self.init(address: address, nonce: nonce, balance: balance, codeHash: codeHash, storageRoot: storageRoot)
    }
}

extension Account {
    public func encode() -> Data? {
        let fields = [self.address.addressData, self.nonce, self.balance, self.codeHash, self.storageRoot] as [AnyObject]
        return RLP.encode(fields)
    }
    
    /// The checksum format is for the hash of the code hash and the storage root to be in the 0x + EIP 55 format.
    /// Otherwise, the hash will be lowercased and without 0x
    public static func fromRaw(_ raw: Data, toChecksumFormat: Bool = true) -> Account? {
        guard let totalItem = RLP.decode(raw) else {return nil}
        guard let rlpItem = totalItem[0] else {return nil}

        var address: EthereumAddress
        var nonce, balance: BigUInt
        var codeHash, storageRoot: String
        switch rlpItem.count {
            case 5?:
                switch rlpItem[0]!.content {
                    case .noItem:
                        address = EthereumAddress.contractDeploymentAddress()
                    case .data(let addressData):
                        if addressData.count == 0 {
                            address = EthereumAddress.contractDeploymentAddress()
                        } else if addressData.count == 20 {
                            guard let addr = EthereumAddress(addressData) else {return nil}
                            address = addr
                        } else {
                            return nil
                        }
                    case .list(_, _, _):
                        return nil
                }
                
                guard let nonceData = rlpItem[1]!.data else {return nil}
                nonce = BigUInt(nonceData)
                guard let balanceData = rlpItem[2]!.data else {return nil}
                balance = BigUInt(balanceData)
                guard let codeHashData = rlpItem[3]!.data else {return nil}
                if toChecksumFormat {
                    let temp = codeHashData.toHexString()
                    codeHash = EthereumAddress.toChecksumAddress(temp) ?? "0x"
                } else {
                    codeHash = codeHashData.toHexString()
                }
                guard let storageRootData = rlpItem[4]!.data else {return nil}
                if toChecksumFormat {
                    let temp = storageRootData.toHexString()
                    storageRoot = EthereumAddress.toChecksumAddress(temp) ?? "0x"
                } else {
                    storageRoot = storageRootData.toHexString()
                }
                
                return Account(address: address, nonce: nonce, balance: balance, codeHash: codeHash, storageRoot: storageRoot)
            default:
                return nil
        }
    }
}

/// The storage for smart contract data. The root node goes to storageRoot of an account.
/// Patricia Merkle Trie
/// Key: keccak256 hash
/// Value: RLP encoding
public struct StorageTrie {
    var nodes: [String: String]
}
