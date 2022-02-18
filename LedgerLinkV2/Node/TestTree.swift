//
//  TestTree.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-13.
//

import Foundation

public final class BinaryTree<T: Comparable> {
    public final class Node<T> {
        public var value: T
        public var leftChild: Node<T>?
        public var rightChild: Node<T>?
        
        public init(value: T, leftChild: Node<T>? = nil, rightChild: Node<T>? = nil) {
            self.value = value
            self.leftChild = leftChild
            self.rightChild = rightChild
        }
    }
    
    public var rootNode: Node<T>
    
    public init(rootNode: Node<T>) {
        self.rootNode = rootNode
    }
    
    public func addNodes(to parent: Node<T>, leftChild: Node<T>?, rightChild: Node<T>?) {
        parent.leftChild = leftChild
        parent.rightChild = rightChild
    }
    
    public func searchTree(_ value: T, node: inout Node<T>?, f: (inout Node<T>?) -> Void) {
        if node == nil || value == node?.value {
            f(&node)
        } else if value < node!.value {
            searchTree(value, node: &node!.leftChild, f: f)
        } else {
            searchTree(value, node: &node!.rightChild, f: f)
        }
    }
}
