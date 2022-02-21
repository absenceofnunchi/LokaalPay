//
//  CoreDataTestings.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-20.
//

import XCTest
@testable import LedgerLinkV2

final class CoreDataTests: XCTestCase {
    func test_state() async {
        do {
            try await LocalStorage.shared.deleteAllAccounts()
            try await LocalStorage.shared.saveStates(treeConfigurableAccounts)
            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccounts() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)

            guard let accounts: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccounts() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)

        } catch {
            fatalError(error.localizedDescription)
        }
        
        do {
            try await LocalStorage.shared.deleteAllAccounts()
            try await LocalStorage.shared.saveStates(accounts)
            guard let accounts: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccounts() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
            
            guard let accounts: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccounts() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
            
        } catch {
            fatalError(error.localizedDescription)
        }
        
        LocalStorage.shared.deleteAllAccounts { error in
            if let error = error {
                fatalError(error.localizedDescription)
            }

            LocalStorage.shared.getAllAccounts { (accts: [Account]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                if let accts = accts {
                    XCTAssertEqual(accts.count, 0)
                }
            }
        }
    }
}
