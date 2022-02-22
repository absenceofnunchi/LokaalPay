//
//  CoreDataTestings.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-20.
//

import XCTest
import web3swift
@testable import LedgerLinkV2

final class CoreDataTests: XCTestCase {
//    func test_test() async {
//        /// Individual updates. Save by Account
//        for account in accounts {
//            do {
//                try await LocalStorage.shared.saveStateAsync(account)
//            } catch {
//                print(error as Any)
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        LocalStorage.shared.anotherDeleteAllAccountsAsync()
//    }
//    
//    func test_batch_request() async {
////        let transactionRequest = LocalStorage.shared.newBatchInsertRequest(with: [treeConfigurableTransactions[0]])
////        print("transactionRequest", transactionRequest)
////        let stateRequest = LocalStorage.shared.newBatchInsertRequest(with: [treeConfigurableAccounts[0]])
////        print("stateRequest", stateRequest)
////        let receiptRequest = LocalStorage.shared.newBatchInsertRequest(with: [treeConfigurableReceipts[0]])
////        print("receiptRequest", receiptRequest)
//        
//        do {
//            try await LocalStorage.shared.deleteAllAccountsAsync()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//        
//        do {
//            try await LocalStorage.shared.saveStatesAsync(treeConfigurableAccounts)
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//        
//        do {
//            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
//            
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//        
//        do {
//            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts1.count, treeConfigurableAccounts.count)
//            try await LocalStorage.shared.deleteAllAccountsAsync()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//        
////        /// Batch updates
////        do {
////            try await LocalStorage.shared.deleteAllTransactionsAsync()
////            try await LocalStorage.shared.saveTransactionsAsync(treeConfigurableTransactions)
////
////        } catch {
////            fatalError(error.localizedDescription)
////        }
////
////        do {
////            guard let txs: [EthereumTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
////                fatalError()
////            }
////            XCTAssertEqual(txs.count, treeConfigurableTransactions.count)
////
////            guard let txs1: [TreeConfigurableTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
////                fatalError()
////            }
////            XCTAssertEqual(txs1.count, treeConfigurableTransactions.count)
////            try await LocalStorage.shared.deleteAllTransactionsAsync()
////        } catch {
////            fatalError(error.localizedDescription)
////        }
//    }

    func test_repeat() async {
        var count = 0
        for _ in 0 ... 10 {
            let _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Core Data wait")], timeout: 1.0)
            await test_state_async()
            count += 1
            print("count: ", count)
        }
    }
    
    func test_state_async() async {
        /// Batch updates
//        do {
//            try await LocalStorage.shared.deleteAllAccountsAsync()
//            try await LocalStorage.shared.saveStatesAsync(treeConfigurableAccounts)
//            await LocalStorage.shared.getAllAccountsAsync { (results: [Account]?, error: NodeError?) in
//                if let error = error {
//                    fatalError(error.localizedDescription)
//                }
//
//                if let results = results {
//                    XCTAssertEqual(results.count, treeConfigurableAccounts.count)
//
//                }
//            }
//
//            await LocalStorage.shared.getAllAccountsAsync { (results: [TreeConfigurableAccount]?, error: NodeError?) in
//                if let error = error {
//                    fatalError(error.localizedDescription)
//                }
//
//                if let results = results {
//                    XCTAssertEqual(results.count, treeConfigurableAccounts.count)
//                }
//            }
//            try await LocalStorage.shared.deleteAllAccountsAsync()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
        
        /// Individual updates. Save by Account
        for account in accounts {
            do {
                try await LocalStorage.shared.saveStateAsync(account) { error in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        for account in accounts {
            do {
                /// Search by EthereumAddress, return Account
                await LocalStorage.shared.getAccount(account.address, completion: { (acct: Account?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }

                    if let acct = acct {
                        XCTAssertEqual(account, acct)
                    }
                })

                /// Search by addressString, return Account
                try await LocalStorage.shared.getAccount(account.address.address, completion: { (acct: Account?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }

                    if let acct = acct {
                        XCTAssertEqual(account, acct)
                    }
                })

                /// Search by EthereumAddress, return TreeConfigurableAccount
                let treeConfigAcct = try TreeConfigurableAccount(data: account)
                await LocalStorage.shared.getAccount(account.address, completion: { (acct: TreeConfigurableAccount?, error: NodeError?) in
                    if let error = error {
                        fatalError(error.localizedDescription)
                    }

                    if let acct = acct {
                        XCTAssertEqual(treeConfigAcct, acct)
                    }
                })

                /// Search by addressString, return TreeConfigurableAccount
                try await LocalStorage.shared.getAccount(account.address.address, completion: { (acct: TreeConfigurableAccount?, error: NodeError?) in
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
    }
    
//    func test_state_async() async {
        /// Delete by EthreumAddress
//        for account in accounts {
//            do {
//                try await LocalStorage.shared.deleteAccountAsync(account.address)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Confirm that everything is deleted
//        do {
//            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts.count, 0)
//
//            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts1.count, 0)
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        /// Individual updates. Save by TreeConfigAccount
//        for account in treeConfigurableAccounts {
//            do {
//                try await LocalStorage.shared.saveStateAsync(account)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Duplicate update
//        for account in treeConfigurableAccounts {
//            do {
//                try await LocalStorage.shared.saveStateAsync(account)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Confirm that no duplicate exists
//        do {
//            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
//
//            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts1.count, treeConfigurableAccounts.count)
//        } catch {
//            fatalError(error.localizedDescription)
//        }

        // Delete all data
        //        do {
        //            try await LocalStorage.shared.deleteAllAccountsAsync()
        //        } catch {
        //            fatalError(error.localizedDescription)
        //        }
//        LocalStorage.shared.anotherDeleteAllAccountsAsync()

//    }
    
    // MARK: - test_state_async
    /// Core Data operations for State using asynchronous methods
//    func test_state_async() async {
//        /// Batch updates
//        do {
//            try await LocalStorage.shared.deleteAllAccountsAsync()
//            try await LocalStorage.shared.saveStatesAsync(treeConfigurableAccounts)
//            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
//
//            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts1.count, treeConfigurableAccounts.count)
//            try await LocalStorage.shared.deleteAllAccountsAsync()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        /// Individual updates. Save by Account
//        for account in accounts {
//            do {
//                try await LocalStorage.shared.saveStateAsync(account)
//            } catch {
//                print(error as Any)
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        for account in accounts {
//            do {
//                /// Search by EthereumAddress, return Account
//                LocalStorage.shared.getAccount(account.address, completion: { (acct: Account?, error: NodeError?) in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    if let acct = acct {
//                        XCTAssertEqual(account, acct)
//                    }
//                })
//
//                /// Search by addressString, return Account
//                try await LocalStorage.shared.getAccount(account.address.address, completion: { (acct: Account?, error: NodeError?) in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    if let acct = acct {
//                        XCTAssertEqual(account, acct)
//                    }
//                })
//
//                /// Search by EthereumAddress, return TreeConfigurableAccount
//                let treeConfigAcct = try TreeConfigurableAccount(data: account)
//                LocalStorage.shared.getAccount(account.address, completion: { (acct: TreeConfigurableAccount?, error: NodeError?) in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    if let acct = acct {
//                        XCTAssertEqual(treeConfigAcct, acct)
//                    }
//                })
//
//                /// Search by addressString, return TreeConfigurableAccount
//                try LocalStorage.shared.getAccount(account.address.address, completion: { (acct: TreeConfigurableAccount?, error: NodeError?) in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    if let acct = acct {
//                        XCTAssertEqual(treeConfigAcct, acct)
//                    }
//                })
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Delete by EthreumAddress
//        for account in accounts {
//            do {
//                try await LocalStorage.shared.deleteAccountAsync(account.address)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Confirm that everything is deleted
//        do {
//            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts.count, 0)
//
//            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts1.count, 0)
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        /// Individual updates. Save by TreeConfigAccount
//        for account in treeConfigurableAccounts {
//            do {
//                try await LocalStorage.shared.saveStateAsync(account)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Duplicate update
//        for account in treeConfigurableAccounts {
//            do {
//                try await LocalStorage.shared.saveStateAsync(account)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Confirm that no duplicate exists
//        do {
//            guard let accounts: [Account] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
//
//            guard let accounts1: [TreeConfigurableAccount] = try await LocalStorage.shared.getAllAccountsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts1.count, treeConfigurableAccounts.count)
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        // Delete all data
////        do {
////            try await LocalStorage.shared.deleteAllAccountsAsync()
////        } catch {
////            fatalError(error.localizedDescription)
////        }
//        LocalStorage.shared.anotherDeleteAllAccountsAsync()
//
//    }

//    // MARK: - test_state_sync
//    /// Core Data operations for State using synchronous methods
//    func test_state_sync() {
//        do {
//            try LocalStorage.shared.deleteAllAccounts()
//
//            for account in accounts {
//                try LocalStorage.shared.saveState(account)
//            }
//            guard let accounts: [Account] = try LocalStorage.shared.getAllAccounts() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
//
//            guard let accounts: [TreeConfigurableAccount] = try LocalStorage.shared.getAllAccounts() else {
//                fatalError()
//            }
//            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)
//
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//        for account in accounts {
//            do {
//                guard let fetchedAcct: Account = try LocalStorage.shared.getAccount(account.address) else {
//                    fatalError()
//                }
//                XCTAssertEqual(fetchedAcct, account)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        do {
//            try LocalStorage.shared.deleteAllAccounts()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//    }
//
//    // MARK: - test_transaction_async
//    /// Core Data operations for Transaction using asynchronous methods
//    func test_transaction_async() async {
//        /// Batch updates
//        do {
//            try await LocalStorage.shared.deleteAllTransactionsAsync()
//            try await LocalStorage.shared.saveTransactionsAsync(treeConfigurableTransactions)
//
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        do {
//            guard let txs: [EthereumTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(txs.count, treeConfigurableTransactions.count)
//
//            guard let txs1: [TreeConfigurableTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(txs1.count, treeConfigurableTransactions.count)
//            try await LocalStorage.shared.deleteAllTransactionsAsync()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        /// Individual updates. Save by Account
//        for tx in transactions {
//            do {
//                try await LocalStorage.shared.saveTransactionAsync(tx)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        for tx in transactions {
//            do {
//                guard let hash = tx.getHash() else {
//                    fatalError()
//                }
//                /// Search by hash, return EthereumTransaction
//                LocalStorage.shared.getTransaction(hash, completion: { (result: EthereumTransaction?, error: NodeError?) in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    if let result = result {
//                        XCTAssertEqual(tx.hash, result.hash)
//                    }
//                })
//
//                guard let encoded = tx.encode() else {
//                    fatalError()
//                }
//                /// Search by RLP, return EthereumTransaction
//                try LocalStorage.shared.getTransaction(encoded, completion: { (result: EthereumTransaction?, error: NodeError?) in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    if let result = result {
//                        XCTAssertEqual(tx.hash, result.hash)
//                    }
//                })
//
//                let treeConfig = try TreeConfigurableTransaction(data: tx)
//
//                guard let hash = tx.getHash() else {
//                    fatalError()
//                }
//                /// Search by hash, return TreeConfigurableTransaction
//                LocalStorage.shared.getTransaction(hash, completion: { (result: TreeConfigurableTransaction?, error: NodeError?) in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    if let result = result {
//                        XCTAssertEqual(treeConfig.id, result.id)
//                    }
//                })
//
//                guard let encoded = tx.encode() else {
//                    fatalError()
//                }
//                /// Search by RLP, return TreeConfigurableTransaction
//                try LocalStorage.shared.getTransaction(encoded, completion: { (result: TreeConfigurableTransaction?, error: NodeError?) in
//                    if let error = error {
//                        fatalError(error.localizedDescription)
//                    }
//
//                    if let result = result {
//                        XCTAssertEqual(treeConfig.id, result.id)
//                    }
//                })
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Delete by EthereumTransaction
//        for tx in transactions {
//            do {
//                try await LocalStorage.shared.deleteTransactionAsync(tx)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Confirm that everything is deleted
//        do {
//            guard let results: [EthereumTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(results.count, 0)
//
//            guard let results1: [TreeConfigurableTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(results1.count, 0)
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        /// Individual updates. Save by TreeConfigTransaction
//        for treeConfigTx in treeConfigurableTransactions {
//            do {
//                try await LocalStorage.shared.saveTransactionAsync(treeConfigTx)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Duplicate update
//        for treeConfigTx in treeConfigurableTransactions {
//            do {
//                try await LocalStorage.shared.saveTransactionAsync(treeConfigTx)
//            } catch {
//                fatalError(error.localizedDescription)
//            }
//        }
//
//        /// Confirm that no duplicate exists
//        do {
//            guard let results: [EthereumTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(results.count, treeConfigurableTransactions.count)
//
//            guard let results1: [TreeConfigurableTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
//                fatalError()
//            }
//            XCTAssertEqual(results1.count, treeConfigurableTransactions.count)
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//
//        // Delete all data
//        do {
//            try await LocalStorage.shared.deleteAllTransactionsAsync()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
//    }
}
