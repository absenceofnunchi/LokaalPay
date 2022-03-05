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
        _ contractMethod: ContractMethod.CodingKeys,
        to: EthereumAddress?,
        value: BigUInt = BigUInt(0),
        password: String,
        completion: @escaping (Data?, NodeError?) -> Void
    ) {
        guard value >= BigUInt(0) else {
            completion(nil, NodeError.generalError("Invalid valud amount"))
            return
        }
        
        /// Fetch the latest block to include the block number in the transaction
        Node.shared.localStorage.getLatestBlock { (block: LightBlock?, error: NodeError?) in
            if let error = error {
                completion(nil, error)
                return
            }
  
            /// The local storage which uses the container from app delegate has to be run on the main thread.
            var keystoreManager: KeystoreManager?
            do {
                keystoreManager = try KeysService().keystoreManager()
            } catch {
                completion(nil, .walletRetrievalError)
            }
            
            /// Get the sender's address
            guard let myAddress = keystoreManager?.addresses?.first else {
                completion(nil, NodeError.generalError("Your address from Keystore Manager could not be prepared."))
                return
            }
                        
            // Fetch the newly created address to increment the nonce and update the balance (if needed)
            Node.shared.fetch(.addressString(myAddress.address)) { (accounts: [Account]?, error: NodeError?) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let accounts = accounts, var account = accounts.first else {
                    completion(nil, .generalError("No account available"))
                    return
                }
                
                /// Increment the nonce
                account.nonce += 1
                
                if value != BigUInt(0) {
                    /// Verfity that the account has enough balance to cover the value
                    guard account.balance >= value else {
                        completion(nil, .generalError("Insufficient fund"))
                        return
                    }
                    
                    /// The transferring value is not to be subtracted from the balance as below since if the validator can't take this balance at face value
                    /// account.balance -= value
                    /// Instead, the sender's balance will be accessed from the validator's blockchain and the value be subtracted from there.
                }
                
                
                /// Chain ID is set by the Host of the blockchain. This is to distinguish the original blockchain from any other blockchains that might postentially coexist, akin to EIP155.
                /// It cannot be saved into EthereumTransaction's chainID since the "fromRaw" method doesn't decode chainID. The result become null even if chainID is set.
                let chainID = UserDefaults.standard.integer(forKey: "chainID")
                
                /// Include the extra data such as the contract method , timestamp, latest block number, and/or a newly created account
                let extraData = TransactionExtraData(account: account, latestBlockNumber: BigUInt(block?.number ?? 1), chainID: BigUInt(chainID))
                guard let encodedExtraData = try? JSONEncoder().encode(extraData) else {
                    completion(nil, NodeError.encodingError)
                    return
                }
                
                do {
                    // Create a public signature
                    let tx = EthereumTransaction.createLocalTransaction(nonce: account.nonce, to: to ?? myAddress, value: value, data: encodedExtraData)
                    guard let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: myAddress, password: password) else {
                        completion(nil, NodeError.generalError("Unable to sign transaction"))
                        return
                    }
                    
                    /// RLP-encode the transaction
                    /// Don't need to be "for signature" since it's being encoded only for transporting.
                    /// The RLP-encoding for the signature already includes v, r, and s.
                    guard let encodedSig = signedTx.encode(forSignature: false) else {
                        completion(nil, NodeError.generalError("Unable to RLP-encode the signed transaction"))
                        return
                    }
                          
                    var method: ContractMethod!
                    switch contractMethod {
                        case .createAccount:
                            /// Add the operations to be sorted according to the timestamp and to be executed in order
//                            let createAccount = CreateAccount(extraData: extraData)
//                            let timestamp = extraData.timestamp
//                            Node.shared.addValidatedOperation(TimestampedOperation(timestamp: timestamp, operation: createAccount))
                            /// Add the transactions to be added to the pool of transactions to be included in the upcoming block
                            
                            /// Create a ContractMethod instance to be sent to peers
                            method = ContractMethod.createAccount(encodedSig)
                            break
                        case .transferValue:
                            /// Add the operations to be sorted according to the timestamp and to be executed in order
//                            let transferValueOperation = TransferValueOperation(transaction: signedTx)
//                            let timestamp = extraData.timestamp
//                            Node.shared.addValidatedOperation(TimestampedOperation(timestamp: timestamp, operation: transferValueOperation))

                            /// Create a ContractMethod instance to be sent to peers
                            method = ContractMethod.transferValue(encodedSig)
                            break
                        default:
                            break
                    }
                    
//                    Node.shared.addValidatedTransaction(signedTx)
                    let finalData = try JSONEncoder().encode(method)
                    
                    completion(finalData, nil)
                    
                    /// Save the account with an increased nonce
                    try Node.shared.localStorage.saveState(account)
                } catch {
                    completion(nil, NodeError.generalError("Unable to create a transaction"))
                }
            }
        }
    }
}

//final class TransactionService {
//    func prepareTransaction(
//        _ contractMethod: ContractMethods,
//        to: EthereumAddress?,
//        value: BigUInt = BigUInt(0),
//        password: String,
//        completion: @escaping (Data?, NodeError?) -> Void
//    ) {
//        guard value >= BigUInt(0) else {
//            completion(nil, NodeError.generalError("Invalid valud amount"))
//            return
//        }
//
//        /// Fetch the latest block to include the block number in the transaction
//        Node.shared.localStorage.getLatestBlock { (block: LightBlock?, error: NodeError?) in
//            if let error = error {
//                completion(nil, error)
//                return
//            }
//
//            guard let block = block else {
//                completion(nil, NodeError.generalError("Unable to verify the latest block"))
//                return
//            }
//
//            /// The local storage which uses the container from app delegate has to be run on the main thread.
//            var keystoreManager: KeystoreManager?
//            do {
//                keystoreManager = try KeysService().keystoreManager()
//            } catch {
//                completion(nil, .walletRetrievalError)
//            }
//
//            /// Get the sender's address
//            guard let myAddress = keystoreManager?.addresses?.first else {
//                completion(nil, NodeError.generalError("Your address from Keystore Manager could not be prepared."))
//                return
//            }
//
//            print("myAddress", myAddress)
//
//            // Fetch the newly created address to increment the nonce and update the balance (if needed)
//            Node.shared.fetch(myAddress.address) { (accounts: [Account]?, error: NodeError?) in
//                if let error = error {
//                    completion(nil, error)
//                    return
//                }
//
//                guard let accounts = accounts, var account = accounts.first else {
//                    completion(nil, .generalError("No account available"))
//                    return
//                }
//
//                /// Increment the nonce
//                account.nonce += 1
//
//                if value != BigUInt(0) {
//                    /// Verfity that the account has enough balance to cover the value
//                    guard account.balance >= value else {
//                        completion(nil, .generalError("Insufficient fund"))
//                        return
//                    }
//
//                    /// Subtract the transferring value from the balance
//                    account.balance -= value
//                }
//
//                guard let method = ContractMethods(rawValue: contractMethod.rawValue),
//                      let methodData = method.data else {
//                          completion(nil, .generalError("Unable to parse the contract method"))
//                          return
//                      }
//
//                /// Include the extra data such as the contract method , timestamp, latest block number, and/or a newly created account
//                let extraData = TransactionExtraData(contractMethod: methodData, account: account, latestBlockNumber: BigUInt(block.number))
//                guard let encodedExtraData = try? JSONEncoder().encode(extraData) else {
//                    completion(nil, NodeError.encodingError)
//                    return
//                }
//
//                do {
//                    // Create a public signature
//                    let tx = EthereumTransaction.createLocalTransaction(nonce: account.nonce, to: to ?? myAddress, value: value, data: encodedExtraData)
//                    guard let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: myAddress, password: password) else {
//                        completion(nil, NodeError.encodingError)
//                        return
//                    }
//                    //                    guard let encodedSig = signedTx?.encode(forSignature: false) else {
//                    //                        completion(nil, NodeError.encodingError)
//                    //                        return
//                    //                    }
//
//                    var finalData: Data!
//                    switch contractMethod {
//                        case .transferValue:
//                            break
//                        case .createAccount:
//                            finalData = try ContractMethod.encode(.createAccount(signedTx, Date()))
//                            break
//                        case .blockchainDownloadRequest:
//                            break
//                        case .blockchainDownloadResponse:
//                            break
//                    }
//
//                    completion(finalData, nil)
//
//                    /// Save the account with an increased nonce
//                    try Node.shared.localStorage.saveState(account)
//                } catch {
//                    completion(nil, NodeError.generalError("Unable to create a transaction"))
//                }
//            }
//        }
//    }
//}
