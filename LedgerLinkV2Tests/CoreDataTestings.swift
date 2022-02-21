//
//  CoreDataTestings.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-20.
//

import XCTest
@testable import LedgerLinkV2

final class CoreDataTests: XCTestCase {
    /// Core Data operations for State using asynchronous methods
    func test_state_async() async {
        /// Batch updates
        do {
            try await LocalStorage.shared.deleteAllAccountsAsync()
            try await LocalStorage.shared.saveStatesAsync(treeConfigurableAccounts)
            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)

            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
                fatalError()
            }
            XCTAssertEqual(accounts1.count, treeConfigurableAccounts.count)
            try await LocalStorage.shared.deleteAllAccountsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        /// Individual updates. Save by Account
        for account in accounts {
            do {
                try await LocalStorage.shared.saveStateAsync(account)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        for account in accounts {
            do {
                /// Search by EthereumAddress, return Account
                LocalStorage.shared.getAccount(account.address, completion: { (acct: Account?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                    
                    if let acct = acct {
                        XCTAssertEqual(account, acct)
                    }
                })
                
                /// Search by addressString, return Account
                try LocalStorage.shared.getAccount(account.address.address, completion: { (acct: Account?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                    
                    if let acct = acct {
                        XCTAssertEqual(account, acct)
                    }
                })
                
                /// Search by EthereumAddress, return TreeConfigurableAccount
                let treeConfigAcct = try TreeConfigurableAccount(data: account)
                LocalStorage.shared.getAccount(account.address, completion: { (acct: TreeConfigurableAccount?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                    
                    if let acct = acct {
                        XCTAssertEqual(treeConfigAcct, acct)
                    }
                })
                
                /// Search by addressString, return TreeConfigurableAccount
                try LocalStorage.shared.getAccount(account.address.address, completion: { (acct: TreeConfigurableAccount?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                    
                    if let acct = acct {
                        XCTAssertEqual(treeConfigAcct, acct)
                    }
                })
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        /// Delete by EthreumAddress
        for account in accounts {
            do {
                try await LocalStorage.shared.deleteAccountAsync(account.address)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        /// Confirm that everything is deleted
        do {
            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, 0)
            
            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
                fatalError()
            }
            XCTAssertEqual(accounts1.count, 0)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        /// Individual updates. Save by TreeConfigAccount
        for account in treeConfigurableAccounts {
            do {
                try await LocalStorage.shared.saveStateAsync(account)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        /// Duplicate update
        for account in treeConfigurableAccounts {
            do {
                try await LocalStorage.shared.saveStateAsync(account)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        /// Confirm that no duplicate exists
        do {
            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
            
            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
                fatalError()
            }
            XCTAssertEqual(accounts1.count, treeConfigurableAccounts.count)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        // Delete all data
        do {
            try await LocalStorage.shared.deleteAllAccountsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Core Data operations for State using synchronous methods
    func test_state_sync() {
        do {
            try LocalStorage.shared.deleteAllAccounts()
            
            for account in accounts {
                try LocalStorage.shared.saveState(account)
            }
            guard let accounts: [Account] = try LocalStorage.shared.getAllAccounts() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
            
            guard let accounts: [TreeConfigurableAccount] = try LocalStorage.shared.getAllAccounts() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
            
        } catch {
            fatalError(error.localizedDescription)
        }
        for account in accounts {
            do {
                guard let fetchedAcct: Account = try LocalStorage.shared.getAccount(account.address) else {
                    fatalError()
                }
                XCTAssertEqual(fetchedAcct, account)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        do {
            try LocalStorage.shared.deleteAllAccounts()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
//    func test_test() async {
//        do {
//            try await LocalStorage.shared.saveState(accounts[0])
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        do {
//            guard let fetchedAcct: Account = try await LocalStorage.shared.getAccount(accounts[0].address) else {
//                fatalError()
//            }
//            XCTAssertEqual(fetchedAcct, accounts[0])
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//    }
//
//    func test_batch_update_closure() {
//        let _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Core Data wait")], timeout: 1.0)
//
//        for account in accounts {
//            do {
//                try LocalStorage.shared.saveState(account) { error in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    do {
//                        try LocalStorage.shared.getAccount(account.address) { (acct: Account?, error: NodeError?) in
//                            if let error = error {
//                                fatalError(error.localizedDescription)
//                            }
//
//                            if let acct = acct {
//                                XCTAssertEqual(acct, account)
//                            }
//                        }
//                    } catch {
//                        fatalError(error.localizedDescription)
//                    }
//                }
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        let _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Core Data wait")], timeout: 1.0)
//
//        LocalStorage.shared.deleteAllAccounts { error in
//            if let error = error {
//                fatalError(error.localizedDescription)
//            }
//
//            LocalStorage.shared.getAllAccounts { (accts: [Account]?, error: NodeError?) in
//                if let error = error {
//                    fatalError(error.localizedDescription)
//                }
//
//                if let accts = accts {
//                    XCTAssertEqual(accts.count, 0)
//                }
//            }
//        }
//    }
}
