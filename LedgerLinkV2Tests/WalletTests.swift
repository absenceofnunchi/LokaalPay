//
//  WalletTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-06.
//

import XCTest
import Combine
@testable import LedgerLinkV2

class WalletTests: XCTestCase {
    let block = lightBlocks[0]
    private let dispatchQueue = DispatchQueue(label: "taskQueue", qos: .userInteractive)
    //value 1 indicate only one task will be performed at once.
    private let semaphore = DispatchSemaphore(value: 1)
    private var storage = Set<AnyCancellable>()
    
    func test_test() {
        
        print("start")
        let group = DispatchGroup()
        
        group.enter()
        self.dispatchQueue.async {
            self.semaphore.wait()
            print("1")
            self.semaphore.signal()
            group.leave()
        }
        
        group.enter()
        self.dispatchQueue.async {
            self.semaphore.wait()
            print("2")
            self.semaphore.signal()
            group.leave()
        }
        
        group.enter()
        self.dispatchQueue.async {
            self.semaphore.wait()
            print("3")
            self.semaphore.signal()
            group.leave()
        }
        
        group.notify(queue: .main) {
            
            // Perform any task once all the intermediate tasks (fetchA(), fetchB(), fetchC()) are completed.
            // This block of code will be called once all the enter and leave statement counts are matched.
            print("4")
        }
    }
    
    func test_test1() async {
        Node.shared.deleteAll()
        try? Node.shared.localStorage.saveStatesAsync(accounts)
        await Node.shared.save(blocks) { error in
            if let error = error {
                print(error)
            }
        }
        
        await Node.shared.save(transactions) { [weak self] (error) in
            if let error = error {
                print(error)
                return
            }
            
            let accts = Future<[TreeConfigurableAccount]?, NodeError> { promise in
                Node.shared.localStorage.getAllAccountsSync { (accts: [TreeConfigurableAccount]?, error: NodeError?) in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    if let accts = accts {
                        promise(.success(accts))
                    }
                }
            }
            
            let txs = Future<[TreeConfigurableTransaction], NodeError> { promise in
                Node.shared.localStorage.getAllTransactionsAsync { (tx: [TreeConfigurableTransaction]?, error: NodeError?) in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    if let tx = tx {
                        promise(.success(tx))
                    }
                }
            }
            
            let blocks = Future<[LightBlock], NodeError> { promise in
                Node.shared.localStorage.getBlocks(from: 0, format: "number > %i") { (blocks: [LightBlock]?, error: NodeError?) in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    if let blocks = blocks {
                        promise(.success(blocks))
                    }
                }
            }
            
            guard let self = self else { return }
            Publishers.CombineLatest3(accts, txs, blocks)
                .collect()
                .eraseToAnyPublisher()
                .flatMap({ (results) -> AnyPublisher<Bool, NodeError> in
                    Future<Bool, NodeError> { promise in
//                        results.forEach { print("for each", $0)}
                        
                        for (acct, tx, blocks) in results {
                            print("acct", acct as Any)
                            print("tx", tx as Any)
                            print("blocks", blocks as Any)
                        }
                        promise(.success(true))
                    }
                    .eraseToAnyPublisher()
                })
                .sink { completion in
                    print(completion)
                    Node.shared.deleteAll()
                } receiveValue: { finalValue in
                    print("finalValue", finalValue)
                }
                .store(in: &self.storage)
        }
    }
}
