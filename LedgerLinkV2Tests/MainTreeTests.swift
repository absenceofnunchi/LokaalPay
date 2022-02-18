//
//  MainTreeTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-11.
//

import XCTest
import BigInt
@testable import LedgerLinkV2

final class MainTreeTest: XCTestCase {
    var treeConfigurableAccounts = Vectors.treeConfigurableAccounts
    var treeConfigurableTransactions = Vectors.treeConfigurableTransactions
    var treeConfigurableReceipts = Vectors.treeConfigurableReceipts
    var newAccountArr = [TreeConfigurableAccount]()

    func test_tree_counting() {
        let tree = Tree<TreeConfigurableAccount>()
        tree.insert(treeConfigurableAccounts[0])
        tree.insert(treeConfigurableAccounts[1])
        tree.insert(treeConfigurableAccounts[2])
        tree.insert(treeConfigurableAccounts[3])
        
        tree.searchTree.delete(key: treeConfigurableAccounts[5])
        tree.searchTree.delete(key: treeConfigurableAccounts[5])
        tree.searchTree.delete(key: treeConfigurableAccounts[5])
        tree.searchTree.delete(key: treeConfigurableAccounts[5])
        XCTAssertEqual(tree.searchTree.allElements().count, tree.searchTree.count())
        XCTAssertNotNil(tree.searchTree.root)
    }
    
    func test_deleteAndUpdate_accounts() throws {
        /// Initialize a tree
        let tree = Tree<TreeConfigurableAccount>()
        XCTAssertNil(tree.rootHash)

        for account in treeConfigurableAccounts {
            tree.deleteAndUpdate(account)
        }

        XCTAssertEqual(tree.searchTree.allElements().count, treeConfigurableAccounts.count)
        XCTAssertEqual(tree.searchTree.allElements().count, tree.searchTree.size)
        XCTAssertNotNil(tree.rootHash)
        
        /// confirm the existing nodes
        for account in treeConfigurableAccounts {
            let foundNode = tree.search(for: account)

            XCTAssertEqual(account, foundNode)
            XCTAssertEqual(account.decode()?.address, foundNode?.decode()?.address)
            XCTAssertEqual(account.decode()?.balance, foundNode?.decode()?.balance)
            XCTAssertEqual(account.decode()?.nonce, foundNode?.decode()?.nonce)
        }
        
        /// confirm using only the address data
        /// this is possible because the equatable protocol for TreeConfigAccount only compares the address data.
        for i in 0 ..< Vectors.addresses.count {
            let address = Vectors.addresses[i]
            let foundNode = tree.search(for: address.addressData)
            
            let account = treeConfigurableAccounts[i]
            
            XCTAssertEqual(account, foundNode)
            XCTAssertEqual(account.decode()?.address, foundNode?.decode()?.address)
            XCTAssertEqual(account.decode()?.balance, foundNode?.decode()?.balance)
            XCTAssertEqual(account.decode()?.nonce, foundNode?.decode()?.nonce)
            
        }
        
        /// prepare accounts with randomized values. notice the account addresses are still the same as the existing ones.
        for i in stride(from: treeConfigurableAccounts.count, to: 0, by: -1) {
            guard i < Vectors.addresses.count else { continue }
            let random = arc4random_uniform(100)
            let account = Account(address: Vectors.addresses[i], nonce: BigUInt(random), balance: BigUInt(random), codeHash: Vectors.checksumHashes[i], storageRoot: Vectors.checksumHashes[i])
            let treeAccount = try TreeConfigurableAccount(data: account)
            newAccountArr.append(treeAccount)
        }

        /// update the existing nodes
        for i in 0 ..< treeConfigurableAccounts.count {
            guard i < newAccountArr.count else { continue }
            let newAccount = newAccountArr[i]
            tree.deleteAndUpdate(newAccount)
        }

        /// check to see if the nodes in the tree has been updated.
        for i in 0 ..< newAccountArr.count {
            let newAccount = newAccountArr[i]
            let updatedNode = tree.search(for: newAccount)
            XCTAssertEqual(newAccount, updatedNode)
            XCTAssertEqual(newAccount.decode(), updatedNode?.decode())
        }
        
        XCTAssertEqual(tree.searchTree.allElements().count, treeConfigurableAccounts.count)
        XCTAssertEqual(tree.searchTree.allElements().count, tree.searchTree.size)
        XCTAssertNotNil(tree.rootHash)

        /// No matter how many times a node is input, it should only be entered once into a tree if they're identical
        let tree1 = Tree<TreeConfigurableAccount>()
        for _ in 0 ..< 10 {
            tree1.deleteAndUpdate(treeConfigurableAccounts[0])
        }

        XCTAssertEqual(tree1.searchTree.allElements().count, 1)
        XCTAssertEqual(tree1.searchTree.count(), 1)
        XCTAssertFalse(tree1.searchTree.isEmpty())
    }
    
    func test_delete_and_update_using_array_parameter() {
        let tree = Tree<TreeConfigurableAccount>()
        tree.deleteAndUpdate(treeConfigurableAccounts)
        XCTAssertEqual(tree.searchTree.allElements().count, treeConfigurableAccounts.count)
        XCTAssertEqual(tree.searchTree.allElements().count, tree.searchTree.size)
        XCTAssertNotNil(tree.rootHash)
        
        /// confirm the existing nodes
        for account in treeConfigurableAccounts {
            let foundNode = tree.search(for: account)
            
            XCTAssertEqual(account, foundNode)
            XCTAssertEqual(account.decode()?.address, foundNode?.decode()?.address)
            XCTAssertEqual(account.decode()?.balance, foundNode?.decode()?.balance)
            XCTAssertEqual(account.decode()?.nonce, foundNode?.decode()?.nonce)
        }
    }
    
    func test_update_only_using_array_parameter() {
        let tree = Tree<TreeConfigurableTransaction>()
        let originalRootHash = tree.rootHash
        var arr = [TreeConfigurableTransaction]()
        /// Only load half of the vectors first and then load the other half later to test none batch updates
        for i in 0 ..< treeConfigurableTransactions.count / 2 {
            arr.append(treeConfigurableTransactions[i])
        }
        tree.insert(arr)
        XCTAssertEqual(tree.searchTree.allElements().count, treeConfigurableTransactions.count / 2)
        XCTAssertEqual(tree.searchTree.allElements().count, tree.searchTree.size)
        XCTAssertNotNil(tree.rootHash)
        
        /// confirm the existing nodes
        for i in 0 ..< treeConfigurableTransactions.count / 2 {
            let account = treeConfigurableTransactions[i]
            let foundNode = tree.search(for: account)
            
            XCTAssertEqual(account, foundNode)
            XCTAssertEqual(account.decode()?.gasPrice, foundNode?.decode()?.gasPrice)
            XCTAssertEqual(account.decode()?.gasLimit, foundNode?.decode()?.gasLimit)
            XCTAssertEqual(account.decode()?.nonce, foundNode?.decode()?.nonce)
            XCTAssertEqual(account.decode()?.to, foundNode?.decode()?.to)
            XCTAssertEqual(account.decode()?.value, foundNode?.decode()?.value)
        }
        
        var arr1 = [TreeConfigurableTransaction]()
        for i in treeConfigurableTransactions.count / 2 ..< treeConfigurableTransactions.count {
            arr1.append(treeConfigurableTransactions[i])
        }
        
        tree.insert(arr1)
        XCTAssertNotEqual(originalRootHash, tree.rootHash)

        /// check to see if the nodes in the tree has been updated.
        for i in 0 ..< treeConfigurableTransactions.count {
            let newAccount = treeConfigurableTransactions[i]
            let updatedNode = tree.search(for: newAccount)
            XCTAssertEqual(newAccount, updatedNode)
            XCTAssertEqual(newAccount.decode()?.gasPrice, updatedNode?.decode()?.gasPrice)
            XCTAssertEqual(newAccount.decode()?.gasLimit, updatedNode?.decode()?.gasLimit)
            XCTAssertEqual(newAccount.decode()?.nonce, updatedNode?.decode()?.nonce)
            XCTAssertEqual(newAccount.decode()?.to, updatedNode?.decode()?.to)
            XCTAssertEqual(newAccount.decode()?.value, updatedNode?.decode()?.value)
        }
        
        XCTAssertEqual(tree.searchTree.allElements().count, treeConfigurableTransactions.count)
        XCTAssertEqual(tree.searchTree.allElements().count, tree.searchTree.size)
    }
    
    /// AddData with a single item parameter
    func test_single_adds_NodeDB() {
        let node = NodeDB()
        
        /// add and search state
        for account in treeConfigurableAccounts {
            node.addData(account)
        }
        XCTAssertEqual(node.stateTrie.getCount(), treeConfigurableAccounts.count)

        for account in treeConfigurableAccounts {
            let result = node.search(account)
            
            guard let acct = account.decode(),
                  let res = result?.decode() else { continue }
            XCTAssertEqual(acct.address, res.address)
            XCTAssertEqual(acct.balance, res.balance)
            XCTAssertEqual(acct.nonce, res.nonce)
            XCTAssertEqual(acct.storageRoot, res.storageRoot)
            XCTAssertEqual(acct.codeHash, res.codeHash)
        }
        
        /// add and search receipts
        for receipts in treeConfigurableReceipts {
            node.addData(receipts)
        }
        XCTAssertEqual(node.receiptTrie.getCount(), treeConfigurableReceipts.count)
        
        for receipts in treeConfigurableReceipts {
            let result = node.search(receipts)
            XCTAssertEqual(result, receipts)
        }
        
        /// add and search transactions
        for tx in treeConfigurableTransactions {
            node.addData(tx)
        }
        XCTAssertEqual(node.transactionTrie.getCount(), treeConfigurableTransactions.count)
        
        for tx in treeConfigurableTransactions {
            let result = node.search(tx)
            XCTAssertEqual(result, tx)
        }
    }
    
    /// AddData with an array of parameters
    func test_multiple_adds_NodeDB() throws {
        let node = NodeDB()
        
        /// add and search state
        node.addData(treeConfigurableAccounts)
        XCTAssertEqual(node.stateTrie.getCount(), treeConfigurableAccounts.count)

        for account in treeConfigurableAccounts {
            let result = node.search(account)

            guard let acct = account.decode(),
                  let res = result?.decode() else {
                      throw NodeError.decodingError
                  }
            XCTAssertEqual(acct.address, res.address)
            XCTAssertEqual(acct.balance, res.balance)
            XCTAssertEqual(acct.nonce, res.nonce)
            XCTAssertEqual(acct.storageRoot, res.storageRoot)
            XCTAssertEqual(acct.codeHash, res.codeHash)

            /// all trees have to be initialized
            let blockHash = try? node.getBlockHash()
            XCTAssertNil(blockHash)
        }
        
        /// add and search receipts
        node.addData(treeConfigurableReceipts)
        XCTAssertEqual(node.receiptTrie.getCount(), treeConfigurableReceipts.count)

        for receipt in treeConfigurableReceipts {
            let result = node.search(receipt)
            
            guard let receipt = receipt.decode(),
                  let res = result?.decode() else {
                      throw NodeError.decodingError
                  }
            XCTAssertEqual(receipt.blockHash, res.blockHash)
            XCTAssertEqual(receipt.blockNumber, res.blockNumber)
            XCTAssertEqual(receipt.transactionHash, res.transactionHash)
            XCTAssertEqual(receipt.transactionIndex, res.transactionIndex)
            XCTAssertEqual(receipt.contractAddress, res.contractAddress)
            XCTAssertEqual(receipt.cumulativeGasUsed, res.cumulativeGasUsed)
            XCTAssertEqual(receipt.gasUsed, res.gasUsed)
            
            /// all trees have to be initialized
            let blockHash = try? node.getBlockHash()
            XCTAssertNil(blockHash)
        }

        /// add and search transactions
        node.addData(treeConfigurableTransactions)
        XCTAssertEqual(node.transactionTrie.getCount(), treeConfigurableTransactions.count)

        for tx in treeConfigurableTransactions {
            let result = node.search(tx)
            XCTAssertEqual(result, tx)
            
            guard let decoded = tx.decode(),
                  let res = result?.decode() else {
                      throw NodeError.decodingError
                  }
            XCTAssertEqual(decoded.nonce, res.nonce)
            XCTAssertEqual(decoded.gasLimit, res.gasLimit)
            XCTAssertEqual(decoded.gasPrice, res.gasPrice)
            XCTAssertEqual(decoded.to, res.to)
            XCTAssertEqual(decoded.value, res.value)
        }
        
        guard let blockHash = try? node.getBlockHash() else {
            throw NodeError.hashingError
        }
        XCTAssertNotNil(blockHash)
    }
}
