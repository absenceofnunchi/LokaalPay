//
//  NetworkTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-24.
//

import XCTest
import MultipeerConnectivity
import web3swift
import BigInt
import Combine
@testable import LedgerLinkV2

class NetworkTests: XCTestCase {
    let password = "1"
    var storage = Set<AnyCancellable>()
    
    func test_asynchronous_updates() {
        KeysService().createNewWallet(password: password) { (keyWalletModel, error) in
            if let error = error {
                print("wallet error", error.localizedDescription)
                XCTAssertNil(error)
            }
            
            var keystoreManager: KeystoreManager!
            do {
                keystoreManager = try KeysService().keystoreManager()
            } catch {
                print(error)
            }
            
            let tx = EthereumTransaction.createLocalTransaction(nonce: BigUInt(0), to: EthereumAddress("0xFadAFCE89EA2221fa33005640Acf2C923312F2b9")!, value: BigUInt(10))
            do {
                guard let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: EthereumAddress("0xFadAFCE89EA2221fa33005640Acf2C923312F2b9")!, password: self.password) else {
                    print("sign error1")
                    return
                }
                
                print("signedTx", signedTx as Any)

                guard let rlpData = signedTx.encode() else {
                    print("sign error2")
                    return
                }
                
                print("rlpData", rlpData)
                
//                let queue = OperationQueue()
//                let peerID = MCPeerID(displayName: "J")
//                let parseOperation = ParseTransactionOperation(rlpData: rlpData, peerID: peerID)
//                let contractMethodOperation = ContractMethodOperation()
//                contractMethodOperation.addDependency(parseOperation)
//
//                queue.addOperations([parseOperation, contractMethodOperation], waitUntilFinished: true)
//                print("Operation finished with: \(contractMethodOperation.result!)")
            } catch {
                XCTAssertNil(error)
                print(error)
            }
        }
    }
    
    func test_transaction_creation() {
        Deferred {
            Future<KeyWalletModel, NodeError> { [weak self] promise in
                KeysService().createNewWallet(password: self!.password) { (keyWalletModel, error) in
                    if let error = error {
                        print(error)
                        promise(.failure(NodeError.generalError("0")))
                        return
                    }
                    
                    if let keyWalletModel = keyWalletModel {
                        promise(.success(keyWalletModel))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap { (_) -> AnyPublisher<EthereumTransaction, NodeError> in
            Future<EthereumTransaction, NodeError> { promise in
                var keystoreManager: KeystoreManager!
                do {
                    keystoreManager = try KeysService().keystoreManager()
                } catch {
                    promise(.failure(.generalError("1")))
                }
                
                let tx = EthereumTransaction.createLocalTransaction(nonce: BigUInt(0), to: EthereumAddress("0xFadAFCE89EA2221fa33005640Acf2C923312F2b9")!, value: BigUInt(10))
                do {
                    guard let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: EthereumAddress("0xFadAFCE89EA2221fa33005640Acf2C923312F2b9")!, password: self.password) else {
                        promise(.failure(.generalError("2")))
                        return
                    }
                    
                    print("signedTx", signedTx as Any)
                    
                    guard let rlpData = signedTx.encode() else {
                        promise(.failure(.generalError("3")))
                        return
                    }
                    
                    print("rlpData", rlpData)
                    promise(.success(signedTx))
                    
                    //                let queue = OperationQueue()
                    //                let peerID = MCPeerID(displayName: "J")
                    //                let parseOperation = ParseTransactionOperation(rlpData: rlpData, peerID: peerID)
                    //                let contractMethodOperation = ContractMethodOperation()
                    //                contractMethodOperation.addDependency(parseOperation)
                    //
                    //                queue.addOperations([parseOperation, contractMethodOperation], waitUntilFinished: true)
                    //                print("Operation finished with: \(contractMethodOperation.result!)")
                } catch {
                    XCTAssertNil(error)
                    promise(.failure(.generalError("4")))
                }
            }
            .eraseToAnyPublisher()
        }
        .sink { (completion) in
            switch completion {
                case .finished:
                    print("finished")
                    break
                case .failure(let error):
                   print(error)
            }
        } receiveValue: { (finalValue) in
            print("finalValue", finalValue)
        }
        .store(in: &storage)
    }
    
    func test_asynchronous_operation() {
        class First: ChainedAsyncResultOperation<String, String, NodeError> {
            
            init(input: String) {
                super.init(input: input)
            }
            
            override func main() {
                guard let input = input else {
                    finish(with: .failure(.generalError("input fail")))
                    return
                }
                
                XCTAssertEqual(input, "Hello!")
                
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
                    print("Executing")
                    self.finish(with: .success("First Success!!!"))
                })
            }
        }
        
        class Second: ChainedAsyncResultOperation<String, String, NodeError>  {
            override func main() {
                guard let input = input else {
                    finish(with: .failure(.generalError("input fail")))
                    return
                }
                
                DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
                    print("Executing")
                    self.finish(with: .success("\(input) and Final Success!!!"))
                })
            }
        }
        
        let first = First(input: "Hello!")
        let second = Second()
        second.addDependency(first)
        
        let queue = OperationQueue()
        queue.addOperations([first, second], waitUntilFinished: true)
        
        guard case .success(let msg) = second.result else { return }
        XCTAssertEqual(msg, "First Success!!! and Final Success!!!")
    }
    
    func test_test3() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(10), execute: {
            print("first")
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            print("Timer fired!")
        }
        
        Deferred {
            Future<Bool, NodeError> { promise in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(10), execute: {
                    print("first")
                    promise(.success(true))
                })
            }
        }
        .eraseToAnyPublisher()
        .buffer(size: 1, prefetch: .keepFull, whenFull: .dropOldest)
        .flatMap(maxPublishers: .max(1)) { _ -> AnyPublisher<Bool, NodeError> in
            Future<Bool, NodeError> { promise in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(10), execute: {
                    print("second")
                    promise(.success(true))
                })
            }
            .eraseToAnyPublisher()
        }
        .sink { completion in
            print(completion)
        } receiveValue: { _ in
            print("final")
        }
        .store(in: &storage)
    }
}
