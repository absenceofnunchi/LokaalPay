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
    func test_test() async {
        
        let account = accounts[0]
        try? Node.shared.localStorage.saveState(account)
        do {
            guard var fetched: Account = try Node.shared.localStorage.getAccount(account.address.address) else {
                print("not found")
                return
            }
            print("fetched", fetched as Any)
            fetched.nonce += 1
            print("nonce increased", fetched as Any)
//            try? Node.shared.localStorage.saveState(fetched)
            Node.shared.localStorage.coreDataStack.saveContext()
            
            guard let fetched2: Account = try Node.shared.localStorage.getAccount(account.address) else {
                print("not found")
                return
            }
            print("fetched2", fetched2 as Any)
        } catch {
            print(error)
        }
        
        
        
//        await Node.shared.save(accounts[0]) { error in
//            if let error = error {
//                print(error)
//                return
//            }
//
//            Node.shared.fetch(accounts[0].address.address) { (accounts: [Account]?, error: NodeError?) in
//                if let error = error {
//                    print(error)
//
//                    return
//                }
//
//                guard let accounts = accounts, var account = accounts.first else {
//                    print("Account needs to be created first")
//                    return
//                }
//
//                print("oldFetched", account as Any)
//                account.nonce += 1
//
//
//                do {
//                    let newlyFetched: Account? = try Node.shared.localStorage.getAccount(account.address)
//                    print("newlyFetched", newlyFetched as Any)
//                } catch {
//                    print(error)
//                }
//            }
//        }
//
//        Node.shared.saveSync([treeConfigurableAccounts[0]]) { error in
//
//        }
    }
}
