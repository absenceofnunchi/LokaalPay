//
//  WalletTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-06.
//

import XCTest
@testable import LedgerLinkV2

import BigInt

class WalletTests: XCTestCase {
    func test_test() {
        let one = "aksdfksa".data(using: .utf8)
        let two = "0x0000000000000000000000000000000000000000000000000000000000000000".data(using: .utf8)
        let three = "0x0000000000000000000000000000000000000000".data(using: .utf8)
//        let array = [one, two, three]
        let array: [Data] = [three!]
        let accountArr = array.map { $0 }
        do {
            guard case .Node(hash: let stateRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: accountArr) else {
                fatalError()
            }
            
            print(stateRoot.toHexString())
        } catch {
            print(error)
        }
        
        let array1: [Data] = [two!]

        do {
            guard case .Node(hash: let stateRoot, datum: _, left: _, right: _) = try MerkleTree.buildTree(fromData: array1) else {
                fatalError()
            }
            
            print(stateRoot.toHexString())
        } catch {
            print(error)
        }
    }
}
