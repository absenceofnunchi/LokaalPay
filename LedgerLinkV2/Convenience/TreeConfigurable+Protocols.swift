//
//  TreeConfigurable+Protocols.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-11.
//

import Foundation

/**
 TreeConfigurable is for a binary tree to be able to sort the nodes
 Codable because the Merkle tree needs to encode in order to convert a type to Data.
 Hashable because the Merkle tree needs to hash the converted data.
 Comparable because the Red Black tree needs to sort.
 */
protocol TreeConfigurable: Codable, Hashable, Comparable {
    associatedtype T
    var id: Data { get set }
    init(data: T) throws
    func decode() -> T?
}

//protocol AccountTreeConfigurable: TreeConfigurable {
//    var address: EthereumAddress { get set }
//}
//
//extension AccountTreeConfigurable {
//    var id: Data {
//        return address.addressData
//    }
//}
//
//protocol TxTreeConfigurable: TreeConfigurable {
//    var transactionHash: Data { get set }
//}
//
//extension TxTreeConfigurable {
//    var id: Data {
//        return transactionHash
//    }
//}
