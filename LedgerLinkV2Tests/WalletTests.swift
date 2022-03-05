//
//  WalletTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-06.
//

import XCTest
import Combine
import web3swift
import BigInt
@testable import LedgerLinkV2

final class WalletTests: XCTestCase {
    let block = lightBlocks[0]
    //value 1 indicate only one task will be performed at once.
    private var storage = Set<AnyCancellable>()
    private let transactionService = TransactionService()
    private let keysService = KeysService()
    private let localStorage = LocalStorage()

    
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
                Node.shared.localStorage.getBlocks(from: 0, format: "number >= %i") { (blocks: [LightBlock]?, error: NodeError?) in
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
    
    func test_createPublicSignature() {
        
        keysService.createNewWallet(password: "1") { [weak self] (keyWalletModel, error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            guard let keyWalletModel = keyWalletModel else {
                fatalError()
            }
            
            self?.localStorage.saveWallet(wallet: keyWalletModel, completion: { (error) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
                
                do {
                    let senderAddressOriginal = "0x193d729335a03f2b94a4fae4e34423e66987089e"
                    // Create a public signature
                    let tx = EthereumTransaction.createLocalTransaction(nonce: BigUInt(100), to: addresses[1], value: BigUInt(10), data: Data(), chainID: BigUInt(11111))
                    guard let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: self!.keysService.keystoreManager(), transaction: tx, from: EthereumAddress(senderAddressOriginal)!, password: "1") else {
                        fatalError("Unable to sign transaction")
                    }
                    
                    guard let encodedSig = signedTx.encode(forSignature: false) else {
                        fatalError("Unable to RLP-encode the signed transaction")
                    }
                    
                    let decoded = EthereumTransaction.fromRaw(encodedSig)
                    guard let publicKey = decoded?.recoverPublicKey() else { return }
                    let senderAddress = Web3.Utils.publicToAddressString(publicKey)
                    XCTAssertEqual(senderAddressOriginal, senderAddress)
                } catch {
                    XCTAssertNil(error)
                }
            })
        }
    }
}
