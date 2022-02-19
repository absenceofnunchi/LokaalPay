//
//  MainTree.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-11.
//

import Foundation
import Combine
import web3swift

final class Tree<T: LightConfigurable> {
    private(set) var rootHash: MerkleTree<T>?
    private(set) var searchTree = RedBlackTree<T>()
    private var storage = Set<AnyCancellable>()
    
    func getAllNodes() -> [T] {
        return searchTree.allElements()
    }
    
    func getCount() -> Int {
        return searchTree.count()
    }
    
    func addRootNode(datum: T) throws {
        
        do {
            let node = try MerkleTree<T>(datum: datum)
            rootHash = node
            
            searchTree.deleteAll()
            searchTree.insert(key: datum)
        } catch {
            throw NodeError.merkleTreeBuildError
        }
    }
    
    /// not safe to use for Accounts since there can be duplicates
    @discardableResult
    func buildTree(fromData data: [T]) throws -> MerkleTree<T> {
        
        for datum in data {
            searchTree.insert(key: datum)
        }

        do {
            let node = try MerkleTree<T>.buildTree(fromData: data)
            rootHash = node
            return node
        } catch {
            throw NodeError.merkleTreeBuildError
        }
    }

    func search(for key: T) -> T? {
        let node = searchTree.search(input: key)
        return node?.key
    }
    
    /// Search only with address data since this is possible due to the Equatable protocol only comparing the id.
    /// Use the method only for TreeConfigurableAccount since other TreeConfigurables use different hashing for the id.
    func search(for addressData: Data) -> T? {
        guard let account = TreeConfigurableAccount(id: addressData, rlpAccount: Data()) as? T else { return nil }
        let node = searchTree.search(input: account)
        return node?.key
    }
    
    /**
     Insert a new node without replacing existing nodes. If an identical node exists, simply do nothing. This is used for items that doesn't require updating such as transactions and receipts, but only requires adding new nodes to the trees
     Then, using all of the latest nodes, create a new Merkle tree.
     The operation has to be in sequence so that the updated list of nodes get built into the Merkle tree.
     
     - Parameters:
     - key: A generic data that constitutes the content of a node for the Red Black Tree and the leaf node for the Merkle tree
     - Returns:
     - Void
     
     */
    func insert(_ key: T) {
        searchTree.updateOnly(key)
            .flatMap { _ in
                Future<Bool, NodeError> { [weak self] promise in
                    guard let allNodes = self?.searchTree.allElements() else {
                        promise(.failure(NodeError.merkleTreeBuildError))
                        return
                    }
                    do {
                        let node = try MerkleTree<T>.buildTree(fromData: allNodes)
                        self?.rootHash = node
                    } catch {
                        promise(.failure(NodeError.merkleTreeBuildError))
                    }
                }
            }
            .sink { (completion) in
                switch completion {
                    case .finished:
                        break
                    case .failure(let nodeError):
                        switch nodeError {
                            case .merkleTreeBuildError:
                                print("merkleTreeBuildError")
                            default:
                                print("Unable to process the tree update.")
                        }
                }
            } receiveValue: { _ in
                
            }
            .store(in: &storage)
    }
    
    func insert(_ keys: [T]) {
        guard keys.count > 0 else {
            return
        }
        
        searchTree.updateOnly(keys)
            .flatMap { _ in
                Future<Bool, NodeError> { [weak self] promise in
                    guard let allNodes = self?.searchTree.allElements() else {
                        promise(.failure(NodeError.merkleTreeBuildError))
                        return
                    }
                    do {
                        let node = try MerkleTree<T>.buildTree(fromData: allNodes)
                        self?.rootHash = node
                    } catch {
                        promise(.failure(NodeError.merkleTreeBuildError))
                    }
                }
            }
            .sink { (completion) in
                switch completion {
                    case .finished:
                        break
                    case .failure(let nodeError):
                        switch nodeError {
                            case .merkleTreeBuildError:
                                print("merkleTreeBuildError")
                            default:
                                print("Unable to process the tree update.")
                        }
                }
            } receiveValue: { _ in
                
            }
            .store(in: &storage)
    }
    
    /**
     Update an existing tree by pointer without adding or deleting an entire node.  This is for Accounts only since they require constant updates.
     Since the address, which is used for sorting in the trees, doesn't change, the account node in a tree doesn't require a complete overhaul, only the details of the node other than the address.
     Then, using all of the latest nodes, create a new Merkle tree.
     The operation has to be in sequence so that the updated list of nodes get built into the Merkle tree.
     
     - Parameters:
     - key: A generic data that constitutes the content of a node for the Red Black Tree and the leaf node for the Merkle tree
     - Returns:
     - Void
     
     */
    func update(_ key: T) {
        /// TODO: the use of inout and the closure cause multiple threads to try to access a memory at the same time.
//        let queue = DispatchQueue(label: "db.update", qos: .utility, attributes: [], autoreleaseFrequency: .inherit, target: nil)
//
//        queue.async { [weak self] in
//            self?.searchTree.search(key: key) { (foundNode, error) in
//                /// If the search returns empty, insert a new node without searching for a duplicate.
//                if let _ = error {
//                    self?.searchTree.insert(key: key, isSearched: false)
//                }
//
//                /// If the search returns a node, modify the existing node instead of creating a new one.
//                if let foundNode = foundNode {
//                    foundNode.key = key
//                }
//            }
//        }
//        searchTree.searchAndUpdate(key: <#T##T#>)
    }
    
    /**
     Insert a new node or replace an existing node by deleting it and inserting a new node in the Red Black Tree.
     Then, using all of the latest nodes, create a new Merkle tree.
     The operation has to be in sequence so that the updated list of nodes get built into the Merkle tree.
     
     - Parameters:
        - key: A generic data that constitutes the content of a node for the Red Black Tree and the leaf node for the Merkle tree
     - Returns:
        - Void
     
     */
    func deleteAndUpdate(_ key: T)  {
        searchTree.update(key: key)
            .flatMap { _ in
                Future<Bool, NodeError> { [weak self] promise in
                    guard let allNodes = self?.searchTree.allElements() else {
                        promise(.failure(NodeError.merkleTreeBuildError))
                        return
                    }
                    do {
                        let node = try MerkleTree<T>.buildTree(fromData: allNodes)
                        self?.rootHash = node
                    } catch {
                        promise(.failure(NodeError.merkleTreeBuildError))
                    }
                }
            }
            .sink { (completion) in
                switch completion {
                    case .finished:
                        break
                    case .failure(let nodeError):
                        switch nodeError {
                            case .merkleTreeBuildError:
                                print("merkleTreeBuildError")
                            default:
                                print("Unable to process the tree update.")
                        }
                }
            } receiveValue: { _ in

            }
            .store(in: &storage)
    }
    
    /// Same as deleteAndUpdate, but with an array of keys as a parameter.
    /// Updates the red black tree entirely first before moving onto merkle tree unlike the single parameter deleteAndUpdate where the red black tree and merkle tree are updated one at a time.
    /// Better time complexity since the merkle tree is updated only once at the end.
    func deleteAndUpdate(_ keys: [T])  {
        guard keys.count > 0 else { return }
        searchTree.update(keys: keys)
            .flatMap { _ in
                Future<Bool, NodeError> { [weak self] promise in
                    guard let allNodes = self?.searchTree.allElements() else {
                        promise(.failure(NodeError.merkleTreeBuildError))
                        return
                    }
                    do {
                        let node = try MerkleTree<T>.buildTree(fromData: allNodes)
                        self?.rootHash = node
                    } catch {
                        promise(.failure(NodeError.merkleTreeBuildError))
                    }
                }
            }
            .sink { (completion) in
                switch completion {
                    case .finished:
                        break
                    case .failure(let nodeError):
                        switch nodeError {
                            case .merkleTreeBuildError:
                                print("merkleTreeBuildError")
                            default:
                                print("Unable to process the tree update.")
                        }
                }
            } receiveValue: { _ in
                
            }
            .store(in: &storage)
    }
}
