//
//  MerkleTreeTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-08.
//

import XCTest
import CryptoKit
import web3swift
import BigInt

@testable import LedgerLinkV2

final class MerkleTreeTests: XCTestCase {
    
    func testBuildTree() throws {
        for rightHash in hashes {
            let leftHash = "d2870829bfddde366f5ed67aa5cddc8b0ad014872c27c10c1d3f0bdaed5a23a3"
            let data = Data((rightHash + leftHash).utf8)
            let hash0 = SHA256.hash(data: data)
            print("hash0", hash0)
        }
        
        let leftHash = "d2870829bfddde366f5ed67aa5cddc8b0ad014872c27c10c1d3f0bdaed5a23a3"
        let rightHash = "9c78e772291c441a0a13d14cc4530cbfa376302330889513a481864319a186fd"
        let data = Data((leftHash + rightHash).utf8)
        let hash0 = SHA256.hash(data: data)
        print("hash0", hash0)
        
        
        guard let converted = (leftHash + rightHash).data(using: .utf8) else { return }
        let hashed = converted.sha3(.keccak256)
        print("------", hashed.toHexString())
        
        guard let converted1 = ("d2870829bfddde366f5ed67aa5cddc8b0ad014872c27c10c1d3f0bdaed5a23a3" + "b39e4addf3925285c9199739eb1388d682860345e2004bebf9a5fb0a41b708e0").data(using: .utf8) else { return }
        let hashed1 = converted1.sha3(.keccak256)
        print("------", hashed1.toHexString())
        
        // SHA256 of
        // Account 0 is d2870829bfddde366f5ed67aa5cddc8b0ad014872c27c10c1d3f0bdaed5a23a3
        // Account 1 is b39e4addf3925285c9199739eb1388d682860345e2004bebf9a5fb0a41b708e0
        // Account 2 is dae9ba8aab3b22e65c5be635baffd37387ee7a50b843b0695b370f2c3f91d257
        // Account 3 is 203fec14e308d5ef1f01dbd37d940e669dc027c804d6a47409933008a1565aa9
        // Account 4 is 9c78e772291c441a0a13d14cc4530cbfa376302330889513a481864319a186fd
        // Account 5 is c95ce4917d14ab2bd1d20773c89b8575ada1fce1f96d2aa9e64e3c027ce265e4
        
        // Of the concatenated hashes of Account 0 and Account 1 is d83d808ea127aeec0d82dd9769ac47c0b9d907f7bc79947b653a9cb97214f834 -> A
        // Of the concatenated hashes of Account 2 and Account 3 is cfa0549423decfcf2a2c1d93c884154dac329cac2429e24237f8770395d02759 -> B
        // Of the concatenated hashes of Account 4 and Account 5 is c3b7ab1e471e9665eb71ea4ff0fd831fa45ee5236837ee94deadf99cdde257fd -> C
        
        // Of the concatenated hashes of A and B is b3479d98c18c21454525670f48b9675deb7e6a34d92a64d5cf1a30eb61b1e7a4 -> D
        // Of the concatenated hashes of D and C is e09914172159f428e32b05434c418db38ec6d1a98ae37a6c79d29f195b57fe76 -> Root Hash

        do {
            let tree = try MerkleTree.buildTree(fromData: treeConfigurableAccounts)

            switch tree {
                case let .Node(root_hash,_,_,_):
                    print("root_hash", root_hash.toHexString())
                    XCTAssertNotNil(root_hash)
                case .Empty:
                    XCTFail()
                    break
            }

            MerkleTree.printTree(theTree: tree)
        } catch {
            print("tree error", error)
            throw NodeError.merkleTreeBuildError
        }
    }
    
    func test_rootHashes() {
        var rootHashArr = Set<Data>()
        for account in treeConfigurableAccounts {
            do {
                guard case .Node(hash: let stateRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: [account]) else {
                    fatalError()
                }

                rootHashArr.insert(stateRoot)
            } catch {
                fatalError("merkle tree build error")
            }
        }

        /// All the root hashes should be different
        XCTAssertEqual(rootHashArr.count, treeConfigurableAccounts.count)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
