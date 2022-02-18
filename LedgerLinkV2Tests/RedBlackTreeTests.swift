//
//  RedBlackTreeTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-10.
//

import XCTest
import web3swift
import BigInt

@testable import LedgerLinkV2

final class RedBlackTreeTests: XCTestCase {
    var treeConfigurableAccounts = Vectors.treeConfigurableAccounts
    var treeConfigurableTransactions = Vectors.treeConfigurableTransactions
    var treeConfigurableReceipts = Vectors.treeConfigurableReceipts
    var accountVectors = Vectors.accountVectors
    var transactions = Vectors.transactions
    var receipts = Vectors.receipts
    
    func test_encoding_decoding_TreeConfigurableAccount() {
        for (i, account) in treeConfigurableAccounts.enumerated() {
            guard let decoded = Account.fromRaw(account.data) else { continue }
            XCTAssertEqual(decoded, accountVectors[i])
        }
    }
    
    func test_treeConfigurableAccount_conversion() {
        for (i, account) in treeConfigurableAccounts.enumerated() {
            let fullFormAccount = account.decode()
            XCTAssertEqual(fullFormAccount, accountVectors[i])
        }
    }
    
    func test_double_tree() {
        let redBlackTree = RedBlackTree<Double>()
        
        let randomMax = Double(0x10000000)
        var values = [Double]()
        for i in 0..<1000 {
            let value = Double(arc4random()) / randomMax
            values.append(value)
            redBlackTree.insert(key: value)
            
            if i % 100 == 0 {
                let isValid = redBlackTree.verify()
                XCTAssertTrue(isValid)
            }
        }
        let isValid = redBlackTree.verify()
        XCTAssertTrue(isValid)
        
        for i in 0..<1000 {
            let rand = arc4random_uniform(UInt32(values.count))
            let index = Int(rand)
            let value = values.remove(at: index)
            redBlackTree.delete(key: value)
            
            if i % 100 == 0 {
                let isValid = redBlackTree.verify()
                XCTAssertTrue(isValid)
            }
        }
        let isValid2 = redBlackTree.verify()
        XCTAssertTrue(isValid2)
    }
    
    func test_state_tree() {
        let redBlackTree = RedBlackTree<TreeConfigurableAccount>()
        
        var values = [TreeConfigurableAccount]()
        for account in treeConfigurableAccounts {
            values.append(account)
            redBlackTree.insert(key: account)
            
            let isValid = redBlackTree.verify()
            XCTAssertTrue(isValid)
        }
        let isValid = redBlackTree.verify()
        XCTAssertTrue(isValid)
        
        for account in treeConfigurableAccounts {
            let node = redBlackTree.search(input: account)
            XCTAssertEqual(node?.key?.id.toHexString(), account.id.toHexString())
        }
        
        let count = redBlackTree.count()
        let allNodes = redBlackTree.allElements()
        XCTAssertEqual(count, allNodes.count)
        
        let isEmpty = redBlackTree.isEmpty()
        XCTAssertFalse(isEmpty)
        
        for _ in 0 ..< treeConfigurableAccounts.count {
            let rand = arc4random_uniform(UInt32(values.count))
            let index = Int(rand)
            let value = values.remove(at: index)
            redBlackTree.delete(key: value)
            
            let isValid = redBlackTree.verify()
            XCTAssertTrue(isValid)
        }
        let isValid2 = redBlackTree.verify()
        XCTAssertTrue(isValid2)
    }
        
    func test_encoding_treeConfigurableTransaction() throws {
        var encodedArray0 = [TreeConfigurableTransaction]()
        var encodedArray1 = [TreeConfigurableTransaction]()

        for i in 0 ..< transactions.count {
            let transaction = transactions[i]
            guard let encoded = transaction.encode() else { return }
            let tct0 = TreeConfigurableTransaction(rlpTransaction: encoded)
            encodedArray0.append(tct0)
            
            guard let tct1 = try? TreeConfigurableTransaction(data: transaction) else { continue }
            encodedArray1.append(tct1)
            
            XCTAssertEqual(tct0, tct1)
        }
        
        for (i, tx) in encodedArray0.enumerated() {
            guard let decoded = tx.decode() else { continue }
            XCTAssertEqual(decoded.gasPrice, transactions[i].gasPrice)
            XCTAssertEqual(decoded.gasLimit, transactions[i].gasLimit)
            XCTAssertEqual(decoded.to, transactions[i].to)
            XCTAssertEqual(decoded.value, transactions[i].value)
            XCTAssertEqual(decoded.data, transactions[i].data)
        }
        
        for (i, tx) in encodedArray1.enumerated() {
            guard let decoded = tx.decode() else { continue }
            XCTAssertEqual(decoded.gasPrice, transactions[i].gasPrice)
            XCTAssertEqual(decoded.gasLimit, transactions[i].gasLimit)
            XCTAssertEqual(decoded.to, transactions[i].to)
            XCTAssertEqual(decoded.value, transactions[i].value)
            XCTAssertEqual(decoded.data, transactions[i].data)
        }
    }
    
    func test_transaction_tree() {
        let redBlackTree = RedBlackTree<TreeConfigurableTransaction>()
        
        var values = [TreeConfigurableTransaction]()
        for account in treeConfigurableTransactions {
            values.append(account)
            redBlackTree.insert(key: account)
            
            let isValid = redBlackTree.verify()
            XCTAssertTrue(isValid)
        }
        let isValid = redBlackTree.verify()
        XCTAssertTrue(isValid)
        
        for account in treeConfigurableTransactions {
            let node = redBlackTree.search(input: account)
            XCTAssertEqual(node?.key?.hashValue, account.hashValue)
        }
        
        let count = redBlackTree.count()
        let allNodes = redBlackTree.allElements()
        XCTAssertEqual(count, allNodes.count)
        let isEmpty = redBlackTree.isEmpty()
        XCTAssertFalse(isEmpty)
        
        for _ in 0 ..< treeConfigurableTransactions.count {
            let rand = arc4random_uniform(UInt32(values.count))
            let index = Int(rand)
            let value = values.remove(at: index)
            redBlackTree.delete(key: value)
            
            let isValid = redBlackTree.verify()
            XCTAssertTrue(isValid)
        }
        let isValid2 = redBlackTree.verify()
        XCTAssertTrue(isValid2)
        
        let count1 = redBlackTree.count()
        let allNodes1 = redBlackTree.allElements()
        XCTAssertEqual(count1, allNodes1.count)
        let isEmpty1 = redBlackTree.isEmpty()
        XCTAssertTrue(isEmpty1)
    }
    
    func test_receipt_tree() {
        for i in 0 ..< treeConfigurableReceipts.count {
            let configReceipt = treeConfigurableReceipts[i]
            let decoded = configReceipt.decode()
            
            let receipt = receipts[i]
            XCTAssertEqual(decoded?.transactionHash, receipt.transactionHash)
            XCTAssertEqual(decoded?.blockNumber, receipt.blockNumber)
            XCTAssertEqual(decoded?.transactionIndex, receipt.transactionIndex)
            XCTAssertEqual(decoded?.contractAddress, receipt.contractAddress)
            XCTAssertEqual(decoded?.cumulativeGasUsed, receipt.cumulativeGasUsed)
            XCTAssertEqual(decoded?.gasUsed, receipt.gasUsed)
        }
    }
    
    /// Trying the "pointer method" on a simplified version of a binary tree
    func test_tree() {
        var rootNode: BinaryTree<Int>.Node<Int>? = BinaryTree<Int>.Node(value: 100, leftChild: nil, rightChild: nil)
        let tree = BinaryTree(rootNode: rootNode!)
        
        /// add new nodes. This is not a self-balancing tree so the left child's value has to be smaller than the parent and the right child's value greater than the parent.
        let leftChild = BinaryTree<Int>.Node(value: 0, leftChild: nil, rightChild: nil)
        let rightChild = BinaryTree<Int>.Node(value: 200, leftChild: nil, rightChild: nil)
        tree.addNodes(to: rootNode!, leftChild: leftChild, rightChild: rightChild)
        
        /// the node argument is the starting point of the search so let's start from the root node.
        /// the found node will be updated with a new node with a value 50
        tree.searchTree(0, node: &rootNode) { foundNode in
            let newNode = BinaryTree<Int>.Node(value: 50, leftChild: nil, rightChild: nil)
            foundNode = newNode
        }
        
        tree.searchTree(0, node: &rootNode) { foundNode in
            XCTAssertNil(foundNode)
        }
        
        tree.searchTree(50, node: &rootNode) { foundNode in
            guard let value = foundNode?.value else { return }
            XCTAssertEqual(value, 50)
        }
    }
    
    /// Create, search, and update transactions using a pointer.
    func test_transactions_in_rbtree() throws {
        let redBlackTree = RedBlackTree<TreeConfigurableTransaction>()
        
        /// Load the tree with initial values
        var values = [TreeConfigurableTransaction]()
        for i in 0 ..< treeConfigurableTransactions.count / 2 {
            let tx = treeConfigurableTransactions[i]
            values.append(tx)
            redBlackTree.insert(key: tx)
            
            let isValid = redBlackTree.verify()
            XCTAssertTrue(isValid)
        }
        let isValid = redBlackTree.verify()
        XCTAssertTrue(isValid)
        
        /// Confirm that the values have been loaded to the tree
        for i in 0 ..< treeConfigurableTransactions.count / 2 {
            let tx = treeConfigurableTransactions[i]
            let node = redBlackTree.search(input: tx)
            XCTAssertEqual(node?.key?.hashValue, tx.hashValue)
        }
        
        /// Update the tree with new values
        for i in 0 ..< treeConfigurableTransactions.count / 2 {
            let originalTx = treeConfigurableTransactions[i]
            let newTx = treeConfigurableTransactions[treeConfigurableTransactions.count - i - 1]
            redBlackTree.search(key: originalTx) { (foundNode, error) in
                if let error = error {
                    XCTAssertNotNil(error)
                    return
                }
                
                if let foundNode = foundNode {
                    foundNode.key = newTx
                }
            }
        }
        
        /// Confirm that the old values don't exist anymore
        for i in 0 ..< treeConfigurableTransactions.count / 2 {
            let originalTx = treeConfigurableTransactions[i]
            redBlackTree.search(key: originalTx) { (foundNode, error) in
                if let error = error {
                    XCTAssertNotNil(error)
                    return
                }
                
                if let foundNode = foundNode {
                    XCTAssertNil(foundNode)
                }
            }
        }
        
        /// Confirm that the newly updated values are in the tree
        for i in (treeConfigurableTransactions.count / 2 + 1) ..< treeConfigurableTransactions.count {
            let newTx = treeConfigurableTransactions[i]
            
            redBlackTree.search(key: newTx) { (foundNode, error) in
                if let error = error {
                    XCTAssertNotNil(error)
                    return
                }
                
                guard let foundNode = foundNode,
                      let decoded = newTx.decode(),
                      let decodedFound = foundNode.key?.decode() else {
                          throw NodeError.decodingError
                }
                
                foundNode.key = newTx

                XCTAssertEqual(decoded.to, decodedFound.to)
            }
        }
        
        let originalTx = treeConfigurableTransactions[0]
        guard let newTx = treeConfigurableTransactions.last else { return }
        redBlackTree.search(key: originalTx) { (foundNode, error) in
            if let error = error {
                XCTAssertNotNil(error)
                return
            }
            
            if let foundNode = foundNode {
                foundNode.key = newTx
            }
        }
        
        let node1 = redBlackTree.search(input: newTx)
        let node2 = redBlackTree.search(input: originalTx)
        XCTAssertNotEqual(node1?.key?.decode()?.value, node2?.key?.decode()?.value)
        XCTAssertNotEqual(node1?.key?.decode()?.to, node2?.key?.decode()?.to)
//        XCTAssertNotEqual(node1?.key?.decode()?.logs, node2?.key?.decode()?.logs)
//        XCTAssertNotEqual(node1?.key?.decode()?.balance, node2?.key?.decode()?.balance)
//        XCTAssertNotEqual(node1?.key?.decode()?.gasUsed, node2?.key?.decode()?.gasUsed)
    }
    
    /// Create, search, and update accounts using a pointer.
    func test_accounts_in_rbtree() throws {
        let redBlackTree = RedBlackTree<TreeConfigurableAccount>()
        
        /// Load the tree with initial values
        var values = [TreeConfigurableAccount]()
        for i in 0 ..< treeConfigurableAccounts.count / 2 {
            let acct = treeConfigurableAccounts[i]
            values.append(acct)
            redBlackTree.insert(key: acct)
            
            let isValid = redBlackTree.verify()
            XCTAssertTrue(isValid)
        }
        let isValid = redBlackTree.verify()
        XCTAssertTrue(isValid)
        
        /// Confirm that the values have been loaded to the tree
        for i in 0 ..< treeConfigurableAccounts.count / 2 {
            let acct = treeConfigurableAccounts[i]
            let node = redBlackTree.search(input: acct)
            XCTAssertEqual(node?.key?.hashValue, acct.hashValue)
        }
        
        /// Modify only the balance of an account.
        let updatedAccount = treeConfigurableAccounts[0]
        var decoded = updatedAccount.decode()
        decoded?.balance = BigUInt(100)
        guard let decoded = decoded else {
            throw NodeError.decodingError
        }

        do {
            /// Update a node in the tree with the updated account
            /// Notice that the tree is being *searched* with the updated account even though the exact model of the updated account doesn't exist on the tree yet.
            /// This is because the Equatable only compares the account number by design.
            let account = try TreeConfigurableAccount(data: decoded)
            redBlackTree.search(key: account) { (foundNode, error) in
                if let error = error {
                    XCTAssertNil(error)
                    throw NodeError.notFound
                }
                
                if let foundNode = foundNode {
                    foundNode.key = account
                }
            }
            
            /// Confirm the change.
            redBlackTree.search(key: account) { (foundNode, error) in
                if let error = error {
                    XCTAssertNil(error)
                    throw NodeError.notFound
                }
                
                if let foundNode = foundNode {
                    let finalDecoded = foundNode.key?.decode()
                    XCTAssertEqual(finalDecoded, decoded)
                }
            }
            
            /// Fail to find a node
            redBlackTree.search(key: treeConfigurableAccounts[9]) { (foundNode, error) in
                if let error = error {
                    XCTAssertNotNil(error)
                    throw NodeError.notFound
                }
                
                if let foundNode = foundNode {
                    let finalDecoded = foundNode.key?.decode()
                    XCTAssertEqual(finalDecoded, decoded)
                }
            }
        } catch {
            throw NodeError.treeSearchError
        }
    }
}
