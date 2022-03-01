//
//  WalletTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-06.
//

import XCTest
import Combine
@testable import LedgerLinkV2

final class WalletTests: XCTestCase {
    let block = lightBlocks[0]
    //value 1 indicate only one task will be performed at once.
    private var storage = Set<AnyCancellable>()
    private let transactionService = TransactionService()
    private let keysService = KeysService()
    private let localStorage = LocalStorage()
    
    func test_createWallet() async {
        await Node.shared.save(block) { [weak self] (error) in
            if let error = error {
                print(error)
                return
            }
            print("stage 0")

            self?.keysService.createNewWallet(password: "1") { (keyWalletModel, error) in
                if let error = error {
                    print(error)
                    return
                }
                print("stage 1")

                guard let keyWalletModel = keyWalletModel else {
                    return
                }
                
                print("stage 2")
                self?.localStorage.saveWallet(wallet: keyWalletModel, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    print("stage 2.5")
                    
                    /// Propogate the creation of the new account to peers
                    self?.transactionService.prepareTransaction(.createAccount, to: nil, password: "1") { data, error in
                        if let error = error {
                            print("notify error", error)
                            return
                        }
                        
                        guard let data = data else {
                            return
                        }
                        
                        print("stage 3")
                        print(data as Any)
                    }
                })
            }
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
