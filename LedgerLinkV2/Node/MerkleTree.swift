//
//  MerkleTree.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-08.
//

import Foundation
import CryptoKit
import web3swift

/**     A Merkle/Binary Hash Tree node.
 The Merkle tree can either be of type .Empty or be of type .Node.
 A .Node will hold some data of type NSData and optionally have
 some children which are also of type MerkleTree.
 */

indirect enum MerkleTree<T: Equatable & Encodable & Hashable> {
    case Empty
    case Node(hash: String, datum: T?, left: MerkleTree, right: MerkleTree)
    
    init() { self = .Empty }
    
    init(hash: String) {
        self = MerkleTree.Node(hash: hash, datum: nil, left: .Empty, right: .Empty)
    }
    
    init(datum: T) throws {
        let encoder = JSONEncoder()
        
        var encoded: Data
        do {
            encoded = try encoder.encode(datum)
        } catch {
            throw NodeError.encodingError
        }
        
        /// make a string from the data and make a hash from it.
        let hash = SHA256.hash(data: encoded).description
        self = MerkleTree.Node(hash: hash, datum: datum, left: .Empty, right: .Empty)
    }
    
    static func createParentNode(leftChild: MerkleTree, rightChild: MerkleTree) -> MerkleTree {
        
        /// get the hashes
        var leftHash  = ""
        var rightHash = ""
        
        switch leftChild {
            case let .Node(hash, _, _, _):
                leftHash = hash
            case .Empty:
                break
        }
        
        switch rightChild {
            case let .Node(hash, _, _, _):
                rightHash = hash
            case .Empty:
                break
        }
        
        /// Calculate the new node's hash which is the hash of the concatenation
        /// of the two children's hashes.
        let data = Data((leftHash + rightHash).utf8)
        let newHash = SHA256.hash(data: data).description
        return MerkleTree.Node(hash: newHash, datum: nil, left: leftChild, right: rightChild)
    }
    
    static func buildTree(fromData data: [T]) throws -> MerkleTree {
        
        /// Calculate the depth of the tree.
        //        let treeDepth = ceil(log2(Double(blobs.count)))
        
        /// Create the node array we will turn into the tree.
        var nodeArray = [MerkleTree]()
        
        /// Start the array off with leaf nodes.
        for datum in data {
            do {
                let mt = try MerkleTree(datum: datum)
                nodeArray.append(mt)
            } catch {
                throw NodeError.merkleTreeBuildError
            }
        }
        
        /// Instead of doing this recursively, which would run out of stack for very large trees,
        /// We do this iteratively using a temporary array.
        while nodeArray.count != 1 {
            var tmpArray = [MerkleTree]()
            while nodeArray.count > 0 {
                
                let leftNode  = nodeArray.removeFirst()
                /** Ensure we have a balanced binary tree by duplicating the left
                 node in the case there is no right node. */
                let rightNode = nodeArray.count > 0 ? nodeArray.removeFirst() : leftNode
                
                tmpArray.append(createParentNode(leftChild: leftNode, rightChild: rightNode))
            }
            
            nodeArray = tmpArray
        }
        
        return nodeArray.first!
    }
    
    static func printTree(theTree: MerkleTree, depth: Int = 0) {
        
        var indent: String = ""
        for _ in 0..<depth {
            indent.append(contentsOf: "   ")
        }
        
        switch theTree {
            case let .Node(hash,_,leftChild,rightChild):
                print(indent,"The node has a hash of",hash)
                print(indent,hash,"'s left child is:")
                MerkleTree.printTree(theTree: leftChild, depth: depth+1)
                print(indent,hash,"'s right child is:")
                MerkleTree.printTree(theTree: rightChild, depth: depth+1)
            case .Empty:
                print(indent,".Empty")
                break
        }
    }
}

extension MerkleTree: Hashable {
    static func == (lhs: MerkleTree<T>, rhs: MerkleTree<T>) -> Bool {
        switch (lhs, rhs) {
            case (.Node(hash: _, datum: let lhsDatum, left: _, right: _), .Node(hash: _, datum: let rhsDatum, left: _, right: _)):
                return lhsDatum == rhsDatum
            default:
                return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
            case .Node(hash: _, datum: let data, left: _, right: _):
                hasher.combine(data)
            default:
                break
        }
    }
}

indirect enum SimpleMerkleTree<T: Equatable & Encodable & Hashable> {
    case Empty
    case Node(hash: String, datum: T?, left: SimpleMerkleTree, right: SimpleMerkleTree)
    
    init() { self = .Empty }
    
    init(hash: String) {
        self = SimpleMerkleTree.Node(hash: hash, datum: nil, left: .Empty, right: .Empty)
    }
    
    init(datum: T) throws {
        let encoder = JSONEncoder()
        
        var encoded: Data
        do {
            encoded = try encoder.encode(datum)
        } catch {
            throw NodeError.encodingError
        }
        
        /// make a string from the data and make a hash from it.
        let hash = SHA256.hash(data: encoded).description
        self = SimpleMerkleTree.Node(hash: hash, datum: datum, left: .Empty, right: .Empty)
    }
    
    static func createParentNode(leftChild: SimpleMerkleTree, rightChild: SimpleMerkleTree) -> SimpleMerkleTree {
        
        /// get the hashes
        var leftHash  = ""
        var rightHash = ""
        
        switch leftChild {
            case let .Node(hash, _, _, _):
                leftHash = hash
            case .Empty:
                break
        }
        
        switch rightChild {
            case let .Node(hash, _, _, _):
                rightHash = hash
            case .Empty:
                break
        }
        
        /// Calculate the new node's hash which is the hash of the concatenation
        /// of the two children's hashes.
        let data = Data((leftHash + rightHash).utf8)
        let newHash = SHA256.hash(data: data).description
        return SimpleMerkleTree.Node(hash: newHash, datum: nil, left: leftChild, right: rightChild)
    }
    
    static func buildTree(fromData data: [T]) throws -> SimpleMerkleTree {
        
        /// Calculate the depth of the tree.
        //        let treeDepth = ceil(log2(Double(blobs.count)))
        
        /// Create the node array we will turn into the tree.
        var nodeArray = [SimpleMerkleTree]()
        
        /// Start the array off with leaf nodes.
        for datum in data {
            do {
                let mt = try SimpleMerkleTree(datum: datum)
                nodeArray.append(mt)
            } catch {
                throw NodeError.merkleTreeBuildError
            }
        }
        
        /// Instead of doing this recursively, which would run out of stack for very large trees,
        /// We do this iteratively using a temporary array.
        while nodeArray.count != 1 {
            var tmpArray = [SimpleMerkleTree]()
            while nodeArray.count > 0 {
                
                let leftNode  = nodeArray.removeFirst()
                /** Ensure we have a balanced binary tree by duplicating the left
                 node in the case there is no right node. */
                let rightNode = nodeArray.count > 0 ? nodeArray.removeFirst() : leftNode
                
                tmpArray.append(createParentNode(leftChild: leftNode, rightChild: rightNode))
            }
            
            nodeArray = tmpArray
        }
        
        return nodeArray.first!
    }
    
    static func printTree(theTree: SimpleMerkleTree, depth: Int = 0) {
        
        var indent: String = ""
        for _ in 0..<depth {
            indent.append(contentsOf: "   ")
        }
        
        switch theTree {
            case let .Node(hash,_,leftChild,rightChild):
                print(indent,"The node has a hash of",hash)
                print(indent,hash,"'s left child is:")
                SimpleMerkleTree.printTree(theTree: leftChild, depth: depth+1)
                print(indent,hash,"'s right child is:")
                SimpleMerkleTree.printTree(theTree: rightChild, depth: depth+1)
            case .Empty:
                print(indent,".Empty")
                break
        }
    }
}

extension SimpleMerkleTree: Hashable {
    static func == (lhs: SimpleMerkleTree<T>, rhs: SimpleMerkleTree<T>) -> Bool {
        switch (lhs, rhs) {
            case (.Node(hash: _, datum: let lhsDatum, left: _, right: _), .Node(hash: _, datum: let rhsDatum, left: _, right: _)):
                return lhsDatum == rhsDatum
            default:
                return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
            case .Node(hash: _, datum: let data, left: _, right: _):
                hasher.combine(data)
            default:
                break
        }
    }
}
