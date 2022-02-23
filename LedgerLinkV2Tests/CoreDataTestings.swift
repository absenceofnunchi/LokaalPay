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
    func test_repeat() async {
        var count = 0
        for _ in 0 ... 5 {
            let _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Core Data wait")], timeout: 1.0)
            
            await test_batch_operations()
//            await test_state_async()
            
            count += 1
            print("count: ", count)
        }
    }
    
    /// Batch insert, fetch, and delete
    func test_batch_operations() async {
        do {
            try await LocalStorage.shared.deleteAllAccountsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        do {
            try LocalStorage.shared.saveStatesAsync(treeConfigurableAccounts)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        await LocalStorage.shared.getAllAccountsAsync { [weak self] (results: [Account]?, error: NodeError?) in
            if let error = error {
                self?.parseError(error)
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableAccounts.count)
            }
        }
    }
    
    func test_state_async() async {
        do {
            try await LocalStorage.shared.deleteAllAccountsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }

        /// Individual updates. Save by Account
        for account in accounts {
            await LocalStorage.shared.saveStateAsync(account) { [weak self] error in
                if let error = error {
                    self?.parseError(error)
                    fatalError(error.localizedDescription)
                }
            }
        }

        for account in accounts {
            do {
                let treeConfigAcct = try TreeConfigurableAccount(data: account)
                /// Search by EthereumAddress, return Account
                LocalStorage.shared.getAccountAsync(account.address, completion: { [weak self] (acct: Account?, error: NodeError?) in
                    if let error = error {
                        self?.parseError(error)
                        fatalError(error.localizedDescription)
                    }

                    XCTAssertNotNil(acct)
                    if let acct = acct {
                        XCTAssertEqual(account, acct)
                    }
                })

                /// Search by addressString, return Account
                LocalStorage.shared.getAccountAsync(account.address.address, completion: { [weak self] (acct: Account?, error: NodeError?) in
                    if let error = error {
                        self?.parseError(error)
                        fatalError(error.localizedDescription)
                    }

                    XCTAssertNotNil(acct)
                    if let acct = acct {
                        XCTAssertEqual(account, acct)
                    }
                })

                /// Search by EthereumAddress, return TreeConfigAccount
                LocalStorage.shared.getAccountAsync(account.address, completion: { [weak self] (acct: TreeConfigurableAccount?, error: NodeError?) in
                    if let error = error {
                        self?.parseError(error)
                        fatalError(error.localizedDescription)
                    }

                    XCTAssertNotNil(acct)
                    if let acct = acct {
                        XCTAssertEqual(treeConfigAcct, acct)
                    }
                })


                /// Search by addressString, return TreeConfigurableAccount
                try LocalStorage.shared.getAccountAsync(account.address.address, completion: { [weak self] (acct: TreeConfigurableAccount?, error: NodeError?) in
                    if let error = error {
                        self?.parseError(error)
                        fatalError(error.localizedDescription)
                    }

                    XCTAssertNotNil(acct)
                    if let acct = acct {
                        XCTAssertEqual(treeConfigAcct, acct)
                    }
                })
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Delete by EthreumAddress individually
        for account in accounts {
            await LocalStorage.shared.deleteAccountAsync(account.address, completion: { [weak self] error in
                if let error = error {
                    self?.parseError(error)
                    fatalError(error.localizedDescription)
                }
            })
        }

        /// Confirm that everything has been deleted
        await LocalStorage.shared.getAllAccountsAsync { [weak self] (results: [Account]?, error: NodeError?) in
            if let error = error {
                self?.parseError(error)
                fatalError(error.localizedDescription)
            }

            if let results = results {
                XCTAssertEqual(results.count, 0)
            }
        }

        /// Individual updates. Save by TreeConfigAccount
        for account in treeConfigurableAccounts {
            await LocalStorage.shared.saveStateAsync(account, completion: { [weak self] error in
                if let error = error {
                    self?.parseError(error)
                    fatalError(error.localizedDescription)
                }
            })
        }

        /// Duplicate update to test that only unique elements can be saved
        for account in treeConfigurableAccounts {
            await LocalStorage.shared.saveStateAsync(account, completion: { [weak self] error in
                if let error = error {
                    self?.parseError(error)
                    fatalError(error.localizedDescription)
                }
            })
        }

//        await LocalStorage.shared.getAllAccountsAsync { [weak self] (results: [Account]?, error: NodeError?) in
//            if let error = error {
//                self?.parseError(error)
//                fatalError(error.localizedDescription)
//            }
//
//            XCTAssertNotNil(results)
//            if let results = results {
//                print("treeConfigurableAccounts", treeConfigurableAccounts as Any)
//                print("results", results as Any)
//                XCTAssertEqual(results.count, treeConfigurableAccounts.count)
//            }
//        }

//        do {
//            try await LocalStorage.shared.deleteAllAccountsAsync()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
    }

    // MARK: - test_state_sync
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

    // MARK: - test_transaction_async
    /// Core Data operations for Transaction using asynchronous methods
    func test_transaction_async() async {
        /// Batch updates
        do {
            try await LocalStorage.shared.deleteAllTransactionsAsync()
            try await LocalStorage.shared.saveTransactionsAsync(treeConfigurableTransactions)

        } catch {
            fatalError(error.localizedDescription)
        }

        do {
            guard let txs: [EthereumTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(txs.count, treeConfigurableTransactions.count)

            guard let txs1: [TreeConfigurableTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(txs1.count, treeConfigurableTransactions.count)
            try await LocalStorage.shared.deleteAllTransactionsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }

        /// Individual updates. Save by Account
        for tx in transactions {
            do {
                try await LocalStorage.shared.saveTransactionAsync(tx)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        for tx in transactions {
            do {
                guard let hash = tx.getHash() else {
                    fatalError()
                }
                /// Search by hash, return EthereumTransaction
                LocalStorage.shared.getTransaction(hash, completion: { [weak self] (result: EthereumTransaction?, error: NodeError?) in
                    if let error = error {
    self?.parseError(error)
                        fatalError(error.localizedDescription)
                    }

                    if let result = result {
                        XCTAssertEqual(tx.hash, result.hash)
                    }
                })

                guard let encoded = tx.encode() else {
                    fatalError()
                }
                /// Search by RLP, return EthereumTransaction
                try LocalStorage.shared.getTransaction(encoded, completion: { [weak self] (result: EthereumTransaction?, error: NodeError?) in
                    if let error = error {
    self?.parseError(error)
                        fatalError(error.localizedDescription)
                    }

                    if let result = result {
                        XCTAssertEqual(tx.hash, result.hash)
                    }
                })

                let treeConfig = try TreeConfigurableTransaction(data: tx)

                guard let hash = tx.getHash() else {
                    fatalError()
                }
                /// Search by hash, return TreeConfigurableTransaction
                LocalStorage.shared.getTransaction(hash, completion: { [weak self] (result: TreeConfigurableTransaction?, error: NodeError?) in
                    if let error = error {
    self?.parseError(error)
                        fatalError(error.localizedDescription)
                    }

                    if let result = result {
                        XCTAssertEqual(treeConfig.id, result.id)
                    }
                })

                guard let encoded = tx.encode() else {
                    fatalError()
                }
                /// Search by RLP, return TreeConfigurableTransaction
                try LocalStorage.shared.getTransaction(encoded, completion: { [weak self] (result: TreeConfigurableTransaction?, error: NodeError?) in
                    if let error = error {
    self?.parseError(error)
                        fatalError(error.localizedDescription)
                    }

                    if let result = result {
                        XCTAssertEqual(treeConfig.id, result.id)
                    }
                })
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Delete by EthereumTransaction
        for tx in transactions {
            do {
                try await LocalStorage.shared.deleteTransactionAsync(tx)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Confirm that everything is deleted
        do {
            guard let results: [EthereumTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(results.count, 0)

            guard let results1: [TreeConfigurableTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(results1.count, 0)
        } catch {
            fatalError(error.localizedDescription)
        }

        /// Individual updates. Save by TreeConfigTransaction
        for treeConfigTx in treeConfigurableTransactions {
            do {
                try await LocalStorage.shared.saveTransactionAsync(treeConfigTx)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Duplicate update
        for treeConfigTx in treeConfigurableTransactions {
            do {
                try await LocalStorage.shared.saveTransactionAsync(treeConfigTx)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Confirm that no duplicate exists
        do {
            guard let results: [EthereumTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(results.count, treeConfigurableTransactions.count)

            guard let results1: [TreeConfigurableTransaction] = try await LocalStorage.shared.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(results1.count, treeConfigurableTransactions.count)
        } catch {
            fatalError(error.localizedDescription)
        }

        // Delete all data
        do {
            try await LocalStorage.shared.deleteAllTransactionsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func parseError(_ error: NodeError) {
        switch error {
            case .encodingError:
                print("encodingError")
            case .rlpEncodingError:
                print("rlpEncodingError")
            case .decodingError:
                print("decodingError")
            case .merkleTreeBuildError:
                print("merkleTreeBuildError")
            case .compressionError:
                print("compressionError")
            case .treeSearchError:
                print("treeSearchError")
            case .notFound:
                print("notFound")
            case .hashingError:
                print("hashingError")
            case .generalError(let string):
                print(string)
        }
    }
    
    // MARK: - test_generic_save
    /// Generic methods
    func test_generic_save() async {
        let treeConfigAcct = treeConfigurableAccounts[0]
        await LocalStorage.shared.save(treeConfigAcct) { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        
        let treeConfigTx = treeConfigurableTransactions[0]
        await LocalStorage.shared.save(treeConfigTx) { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        
        let treeConfigReceipt = treeConfigurableReceipts[0]
        await LocalStorage.shared.save(treeConfigReceipt) { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        
        for account in accounts {
            await LocalStorage.shared.save(account) { error in
                XCTAssertNil(error)
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        for transaction in transactions {
            await LocalStorage.shared.save(transaction) { error in
                XCTAssertNil(error)
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        for receipt in receipts {
            await LocalStorage.shared.save(receipt) { error in
                XCTAssertNil(error)
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        LocalStorage.shared.deleteAll(of: .stateCoreData)
        LocalStorage.shared.deleteAll(of: .transactionCoreData)
        LocalStorage.shared.deleteAll(of: .receiptCoreData)
        
        await LocalStorage.shared.save(treeConfigurableAccounts, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })

        await LocalStorage.shared.save(treeConfigurableTransactions, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        
        await LocalStorage.shared.save(treeConfigurableReceipts, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        
        LocalStorage.shared.fetchAll(of: .account) { (results: [Account]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableAccounts.count)
            }
        }
        
        LocalStorage.shared.fetchAll(of: .transaction) { (results: [EthereumTransaction]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableAccounts.count)
            }
        }
        
        LocalStorage.shared.fetchAll(of: .receipt) { (results: [TransactionReceipt]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableAccounts.count)
            }
        }
        
        LocalStorage.shared.fetchAll(of: .account) { (results: [TreeConfigurableAccount]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableAccounts.count)
            }
        }
        
        LocalStorage.shared.fetchAll(of: .transaction) { (results: [TreeConfigurableTransaction]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableTransactions.count)
            }
        }
        
        LocalStorage.shared.fetchAll(of: .receipt) { (results: [TreeConfigurableReceipt]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableReceipts.count)
            }
        }
    }
}
