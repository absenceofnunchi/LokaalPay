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
    
    func test_test1() {
        let accounts = Future<[TreeConfigurableAccount], NodeError> { [weak self] (promise) in
            Node.shared.localStorage.fetch { (accts: [TreeConfigurableAccount]?, error: NodeError?) in
                if let error = error {
                    promise(.failure(error))
                }
                
                if let accts = accts {
                    promise(.success(accts))
                }
            }
        }
        
        let transactions = Future<[TreeConfigurableTransaction], NodeError> { [weak self] promise in
            Node.shared.localStorage.fetch { (txs: [TreeConfigurableTransaction]?, error: NodeError?) in
                if let error = error {
                    promise(.failure(error))
                }
                
                if let txs = txs {
                    promise(.success(txs))
                }
            }
        }
        
//        let accts = Future<[TreeConfigurableAccount]?, NodeError> { [weak self] promise in
//            do {
//                let accounts: [TreeConfigurableAccount]? = try Node.shared.localStorage.getAllAccounts()
//                promise(.success(accounts))
//            } catch NodeError.generalError(let error) {
//                promise(.failure(.generalError(error)))
//            } catch {
//                promise(.failure(.generalError("Unable to fetch accounts")))
//            }
//        }
        
        let accts = Future<[TreeConfigurableAccount]?, NodeError> { [weak self] promise in
            Node.shared.localStorage.getAllAccountsSync { (accts: [TreeConfigurableAccount]?, error: NodeError?) in
                if let error = error {
                    promise(.failure(error))
                }
                
                if let accts = accts {
                    promise(.success(accts))
                }
            }
        }
        
//        let txs = Future<[TreeConfigurableTransaction], NodeError> { [weak self] promise in
//            Node.shared.localStorage.getall
//        }
        
        Publishers.MergeMany([accts])
            .collect()
            .eraseToAnyPublisher()
            .sink { completion in
                print(completion)
            } receiveValue: { finalValue in
                print("finalValue", finalValue)
            }
            .store(in: &storage)
    }
}
