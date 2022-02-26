//
//  TransactionService.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-05.
//

import Foundation
import web3swift
import BigInt

final class TransactionService {
    func prepareTransaction(
        _ contractMethod: ContractMethods,
        to: EthereumAddress?,
        value: BigUInt = BigUInt(0),
        password: String,
        completion: @escaping (Data?, TxError?) -> Void
    ) {
        guard value >= BigUInt(0) else {
            completion(nil, TxError.generalError("Invalid valud amount"))
            return
        }

        /// Fetch the latest block to include the block number in the transaction
        Node.shared.localStorage.getLatestBlock { (block: LightBlock?, error: NodeError?) in
            if let error = error {
                completion(nil, TxError.nodeError(error))
            }
            
            if let block = block {
                /// The local storage which uses the container from app delegate has to be run on the main thread.
                var keystoreManager: KeystoreManager?
                do {
                    keystoreManager = try KeysService().keystoreManager()
                } catch {
                    completion(nil, TxError.walletError(.walletRetrievalError))
                }
                
                /// Get the sender's address
                guard let myAddress = keystoreManager?.addresses?.first else {
                    completion(nil, TxError.generalError("Your address could not be prepared."))
                    return
                }

//                /// Fetch the exsting the nonce to be added to the new transaction
//                guard var account: Account = try? Node.shared.localStorage.getAccount(myAddress) else {
//                    completion(nil, .generalError("Unable to verify nonce"))
//                    return
//                }
                
                /// Fetch the exsting the nonce to increment and add to the new transaction
                Node.shared.fetch(myAddress.address) { (accounts: [Account]?, error: NodeError?) in
                    if let error = error {
                        print(error)
                        completion(nil, .generalError("Unable to verify nonce"))
                    }
                    
                    if let accounts = accounts, var account = accounts.first {
                        account.nonce += 1
                        
                        if value != BigUInt(0) {
                            guard account.balance >= value else {
                                completion(nil, .generalError("Insufficient fund"))
                                return
                            }
                            
                            account.balance -= value
                        }
                        
                        guard let method = ContractMethods(rawValue: contractMethod.rawValue),
                              let methodData = method.data else {
                                  completion(nil, .generalError("Unable to parse the contract method"))
                                  return
                              }
                        
                        /// Include the extra data such as the contract method , timestamp, latest block number, and/or a newly created account
                        let extraData = TransactionExtraData(contractMethod: methodData, latestBlockNumber: block.number)
                        guard let encodedExtraData = try? JSONEncoder().encode(extraData) else {
                            completion(nil, TxError.encodingError)
                            return
                        }
                        
                        do {
                            // Create a public signature
                            let tx = EthereumTransaction.createLocalTransaction(nonce: account.nonce, to: to ?? myAddress, value: value, data: encodedExtraData)
                            let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: myAddress, password: password)
                            guard let encodedSig = signedTx?.encode(forSignature: false) else {
                                completion(nil, TxError.encodingError)
                                return
                            }
                            
                            completion(encodedSig, nil)
                        } catch {
                            completion(nil, TxError.generalError("Unable to create a transaction"))
                        }
                    }
                }
            }
        }
    }
}
