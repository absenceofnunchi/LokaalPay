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
//    func test_repeat() async {
//        var count = 0
//        for _ in 0 ... 5 {
//            let _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Core Data wait")], timeout: 1.0)
//            
//            await test_batch_operations()
////            await test_state_async()
//            
//            count += 1
//            print("count: ", count)
//        }
//    }
    
    /// Batch insert, fetch, and delete
    func test_batch_operations() async {
        do {
            try await Node.shared.localStorage.deleteAllAccountsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }
        
        do {
            try Node.shared.localStorage.saveStatesAsync(treeConfigurableAccounts)
        } catch {
            fatalError(error.localizedDescription)
        }
        
        await Node.shared.localStorage.getAllAccountsAsync { [weak self] (results: [Account]?, error: NodeError?) in
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
            try await Node.shared.localStorage.deleteAllAccountsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }

        /// Individual updates. Save by Account
        for account in accounts {
            await Node.shared.localStorage.saveStateAsync(account) { [weak self] error in
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
                Node.shared.localStorage.getAccountAsync(account.address, completion: { [weak self] (acct: Account?, error: NodeError?) in
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
                Node.shared.localStorage.getAccountAsync(account.address.address, completion: { [weak self] (acct: Account?, error: NodeError?) in
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
                Node.shared.localStorage.getAccountAsync(account.address, completion: { [weak self] (acct: TreeConfigurableAccount?, error: NodeError?) in
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
                try Node.shared.localStorage.getAccountAsync(account.address.address, completion: { [weak self] (acct: TreeConfigurableAccount?, error: NodeError?) in
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
            await Node.shared.localStorage.deleteAccountAsync(account.address, completion: { [weak self] error in
                if let error = error {
                    self?.parseError(error)
                    fatalError(error.localizedDescription)
                }
            })
        }

        /// Confirm that everything has been deleted
        await Node.shared.localStorage.getAllAccountsAsync { [weak self] (results: [Account]?, error: NodeError?) in
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
            await Node.shared.localStorage.saveStateAsync(account, completion: { [weak self] error in
                if let error = error {
                    self?.parseError(error)
                    fatalError(error.localizedDescription)
                }
            })
        }

        /// Duplicate update to test that only unique elements can be saved
        for account in treeConfigurableAccounts {
            await Node.shared.localStorage.saveStateAsync(account, completion: { [weak self] error in
                if let error = error {
                    self?.parseError(error)
                    fatalError(error.localizedDescription)
                }
            })
        }

//        await Node.shared.localStorage.getAllAccountsAsync { [weak self] (results: [Account]?, error: NodeError?) in
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
//            try await Node.shared.localStorage.deleteAllAccountsAsync()
//        } catch {
//            fatalError(error.localizedDescription)
//        }
    }

    // MARK: - test_state_sync
    /// Core Data operations for State using synchronous methods
    func test_state_sync() {
        do {
            try Node.shared.localStorage.deleteAllAccounts()

            for account in accounts {
                try Node.shared.localStorage.saveState(account)
            }
            guard let accounts: [Account] = try Node.shared.localStorage.getAllAccounts() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)

            guard let accounts: [TreeConfigurableAccount] = try Node.shared.localStorage.getAllAccounts() else {
                fatalError()
            }
            XCTAssertEqual(accounts.count, treeConfigurableAccounts.count)

        } catch {
            fatalError(error.localizedDescription)
        }
        for account in accounts {
            do {
                guard let fetchedAcct: Account = try Node.shared.localStorage.getAccount(account.address) else {
                    fatalError()
                }
                XCTAssertEqual(fetchedAcct, account)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        do {
            try Node.shared.localStorage.deleteAllAccounts()
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    // MARK: - test_transaction_async
    /// Core Data operations for Transaction using asynchronous methods
    func test_transaction_async() async {
        /// Batch updates
        do {
            try await Node.shared.localStorage.deleteAllTransactionsAsync()
            try await Node.shared.localStorage.saveTransactionsAsync(treeConfigurableTransactions)

        } catch {
            fatalError(error.localizedDescription)
        }

        do {
            guard let txs: [EthereumTransaction] = try await Node.shared.localStorage.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(txs.count, treeConfigurableTransactions.count)

            guard let txs1: [TreeConfigurableTransaction] = try await Node.shared.localStorage.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(txs1.count, treeConfigurableTransactions.count)
            try await Node.shared.localStorage.deleteAllTransactionsAsync()
        } catch {
            fatalError(error.localizedDescription)
        }

        /// Individual updates. Save by Account
        for tx in transactions {
            do {
                try await Node.shared.localStorage.saveTransactionAsync(tx)
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
                Node.shared.localStorage.getTransaction(hash, completion: { [weak self] (result: EthereumTransaction?, error: NodeError?) in
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
                try Node.shared.localStorage.getTransaction(encoded, completion: { [weak self] (result: EthereumTransaction?, error: NodeError?) in
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
                Node.shared.localStorage.getTransaction(hash, completion: { [weak self] (result: TreeConfigurableTransaction?, error: NodeError?) in
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
                try Node.shared.localStorage.getTransaction(encoded, completion: { [weak self] (result: TreeConfigurableTransaction?, error: NodeError?) in
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
                try await Node.shared.localStorage.deleteTransactionAsync(tx)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Confirm that everything is deleted
        do {
            guard let results: [EthereumTransaction] = try await Node.shared.localStorage.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(results.count, 0)

            guard let results1: [TreeConfigurableTransaction] = try await Node.shared.localStorage.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(results1.count, 0)
        } catch {
            fatalError(error.localizedDescription)
        }

        /// Individual updates. Save by TreeConfigTransaction
        for treeConfigTx in treeConfigurableTransactions {
            do {
                try await Node.shared.localStorage.saveTransactionAsync(treeConfigTx)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Duplicate update
        for treeConfigTx in treeConfigurableTransactions {
            do {
                try await Node.shared.localStorage.saveTransactionAsync(treeConfigTx)
            } catch {
                fatalError(error.localizedDescription)
            }
        }

        /// Confirm that no duplicate exists
        do {
            guard let results: [EthereumTransaction] = try await Node.shared.localStorage.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(results.count, treeConfigurableTransactions.count)

            guard let results1: [TreeConfigurableTransaction] = try await Node.shared.localStorage.getAllTransactionsAsync() else {
                fatalError()
            }
            XCTAssertEqual(results1.count, treeConfigurableTransactions.count)
        } catch {
            fatalError(error.localizedDescription)
        }

        // Delete all data
        do {
            try await Node.shared.localStorage.deleteAllTransactionsAsync()
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
        // MARK: - save
        let treeConfigAcct = treeConfigurableAccounts[0]
        await Node.shared.save(treeConfigAcct) { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        
        let treeConfigTx = treeConfigurableTransactions[0]
        await Node.shared.save(treeConfigTx) { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        
        let treeConfigReceipt = treeConfigurableReceipts[0]
        await Node.shared.save(treeConfigReceipt) { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        }
        
        for account in accounts {
            await Node.shared.save(account) { error in
                XCTAssertNil(error)
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        for transaction in transactions {
            await Node.shared.save(transaction) { error in
                XCTAssertNil(error)
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        for receipt in receipts {
            await Node.shared.save(receipt) { error in
                XCTAssertNil(error)
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        for block in blocks {
            await Node.shared.save(block) { error in
                XCTAssertNil(error)
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
        }
        
        // MARK: - deletAll
        Node.shared.deleteAll(of: .stateCoreData)
        Node.shared.deleteAll(of: .transactionCoreData)
        Node.shared.deleteAll(of: .receiptCoreData)
        
        await Node.shared.save(treeConfigurableAccounts, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })

        await Node.shared.save(treeConfigurableTransactions, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        
        await Node.shared.save(treeConfigurableReceipts, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        
//        await Node.shared.save(lightBlocks, completion: { error in
//            XCTAssertNil(error)
//            if let error = error {
//                fatalError(error.localizedDescription)
//            }
//        })
        
        Node.shared.deleteAll(of: .stateCoreData)
        Node.shared.deleteAll(of: .transactionCoreData)
        Node.shared.deleteAll(of: .receiptCoreData)
    }
    
    // MARK: - test_generic_fetch
    func test_generic_fetch() async {
        Node.shared.deleteAll()
        
        // Seeding
        await Node.shared.save(accounts, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        
        await Node.shared.save(transactions, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        
        await Node.shared.save(receipts, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        
        await Node.shared.save(blocks, completion: { error in
            XCTAssertNil(error)
            if let error = error {
                fatalError(error.localizedDescription)
            }
        })
        
        // MARK: - fetchAll
        Node.shared.fetch() { (results: [Account]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, accounts.count)
            }
        }
        
        Node.shared.fetch() { (results: [EthereumTransaction]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, transactions.count)
            }
        }
        
        Node.shared.fetch() { (results: [TransactionReceipt]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, receipts.count)
            }
        }
        
        Node.shared.fetch() { (results: [FullBlock]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, blocks.count)
            }
        }
        
        Node.shared.fetch() { (results: [TreeConfigurableAccount]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableAccounts.count)
            }
        }
        
        Node.shared.fetch() { (results: [TreeConfigurableTransaction]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableTransactions.count)
            }
        }
        
        Node.shared.fetch() { (results: [TreeConfigurableReceipt]?, error: NodeError?) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            XCTAssertNotNil(results)
            if let results = results {
                XCTAssertEqual(results.count, treeConfigurableReceipts.count)
            }
        }
        
        // MARK: - fetch individual
        for account in accounts {
            Node.shared.fetch(account.address.address) { (results: [Account]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                XCTAssertNotNil(results)
                if let results = results, let result = results.first {
                    XCTAssertEqual(results.count, 1)
                    XCTAssertEqual(result, account)
                }
            }
        }
        
        for account in treeConfigurableAccounts {
            Node.shared.fetch(account.id) { (results: [TreeConfigurableAccount]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                XCTAssertNotNil(results)
                if let results = results, let result = results.first {
                    XCTAssertEqual(results.count, 1)
                    XCTAssertEqual(result, account)
                }
            }
        }
        
        for transaction in transactions {
            guard let hash = transaction.getHash() else { return }
            Node.shared.fetch(hash) { (results: [EthereumTransaction]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                XCTAssertNotNil(results)
                if let results = results, let result = results.first {
                    XCTAssertEqual(results.count, 1)
                    XCTAssertEqual(result.nonce, transaction.nonce)
                    XCTAssertEqual(result.gasPrice, transaction.gasPrice)
                    XCTAssertEqual(result.gasLimit, transaction.gasLimit)
                    XCTAssertEqual(result.value, transaction.value)
                    XCTAssertEqual(result.sender, transaction.sender)
                }
            }
        }
        
        for transaction in treeConfigurableTransactions {
            Node.shared.fetch(transaction.id) { (results: [TreeConfigurableTransaction]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                XCTAssertNotNil(results)
                if let results = results, let result = results.first {
                    XCTAssertEqual(results.count, 1)
                    XCTAssertEqual(result, transaction)
                }
            }
        }
        
        for receipt in receipts {
            guard let hash = receipt.getHash() else { return }
            Node.shared.fetch(hash) { (results: [TransactionReceipt]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                XCTAssertNotNil(results)
                if let results = results, let result = results.first {
                    XCTAssertEqual(results.count, 1)
                    XCTAssertEqual(result.blockHash, receipt.blockHash)
                    XCTAssertEqual(result.blockNumber, receipt.blockNumber)
                    XCTAssertEqual(result.contractAddress, receipt.contractAddress)
                    XCTAssertEqual(result.transactionHash, receipt.transactionHash)
                    XCTAssertEqual(result.transactionIndex, receipt.transactionIndex)
                }
            }
        }
        
        for receipt in treeConfigurableReceipts {
            Node.shared.fetch(receipt.id) { (results: [TreeConfigurableReceipt]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                XCTAssertNotNil(results)
                if let results = results, let result = results.first {
                    XCTAssertEqual(results.count, 1)
                    XCTAssertEqual(result, receipt)
                }
            }
        }
        
        for block in blocks {
            Node.shared.fetch(block.hash.toHexString()) { (results: [FullBlock]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                XCTAssertNotNil(results)
                if let results = results, let result = results.first {
                    XCTAssertEqual(results.count, 1)
                    XCTAssertEqual(result, block)
                }
            }
        }
        
        for block in lightBlocks {
            Node.shared.fetch(block.id) { (results: [LightBlock]?, error: NodeError?) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                XCTAssertNotNil(results)
                if let results = results, let result = results.first {
                    XCTAssertEqual(results.count, 1)
                    XCTAssertEqual(result, block)
                }
            }
        }
    }
    
    func test_test() {
        let tx = transactions[0]
        guard let rlpEncoded = tx.encode(),
        let compressed = rlpEncoded.compressed else { return }
        
        let hash = compressed.sha256().toHexString()
        print("hash", hash)
        
        
        
        Node.shared.fetch(hash) { (txs: [TreeConfigurableTransaction]?, error: NodeError?) in
            if let error = error {
                print(error)
                return
            }
            
            if let txs = txs {
                print("txs", txs)
            }
        }
    }
}
