//
//  Mine.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-14.
//

import Foundation
import web3swift
import CryptoKit

struct Mine {
    func generate(with blockHash: String) throws -> Data? {
        guard let english = BIP39Language(language: "english") else { return nil }
        let words = english.words
        
        var hashes = [Data]()
        for word in words {
            guard let data = (word + blockHash).data(using: .utf8) else { return nil }
            hashes.append(data)
        }
        guard case .Node(hash: let hash, datum: _, left: _, right: _) = try? MerkleTree<Data>.buildTree(fromData: hashes) else { return nil }
        return hash
    }
}
