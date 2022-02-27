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
            
            guard let block = block else {
                completion(nil, NodeError.generalError("Unable to verify the latest block"))
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
                completion(nil, NodeError.generalError("You address from Keystore Manager could not be prepared."))
                return
            }
            
            print("myAddress", myAddress)
            
            //                /// Fetch the exsting the nonce to be added to the new transaction
            //                guard var account: Account = try? Node.shared.localStorage.getAccount(myAddress) else {
            //                    completion(nil, .generalError("Unable to verify nonce"))
            //                    return
            //                }
            
            do {
                let tempAccount: Account? = try Node.shared.localStorage.getAccount(myAddress)
                print("tempAccount", tempAccount as Any)
            } catch {
                print(error)
            }
            
            guard var account: Account = try? Node.shared.localStorage.getAccount(myAddress.address) else {
                completion(nil, .generalError("Account needs to be created first"))
                return
            }
            
            account.nonce += 1
            
            if value != BigUInt(0) {
                /// Verfity that the account has enough balance to cover the value
                guard account.balance >= value else {
                    completion(nil, .generalError("Insufficient fund"))
                    return
                }
                
                /// Subtract the transferring value from the balance
                account.balance -= value
            }
            
            guard let method = ContractMethods(rawValue: contractMethod.rawValue),
                  let methodData = method.data else {
                      completion(nil, .generalError("Unable to parse the contract method"))
                      return
                  }
            
            /// Include the extra data such as the contract method , timestamp, latest block number, and/or a newly created account
            let extraData = TransactionExtraData(contractMethod: methodData, latestBlockNumber: BigUInt(block.number))
            guard let encodedExtraData = try? JSONEncoder().encode(extraData) else {
                completion(nil, NodeError.encodingError)
                return
            }
            
            do {
                // Create a public signature
                let tx = EthereumTransaction.createLocalTransaction(nonce: account.nonce, to: to ?? myAddress, value: value, data: encodedExtraData)
                let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: myAddress, password: password)
                guard let encodedSig = signedTx?.encode(forSignature: false) else {
                    completion(nil, NodeError.encodingError)
                    return
                }
                
                completion(encodedSig, nil)
                
                /// Save the account with an increased nonce
                try Node.shared.localStorage.saveState(account)
            } catch {
                completion(nil, NodeError.generalError("Unable to create a transaction"))
            }
        }
    }
}


///// Fetch the exsting the nonce to increment and add to the new transaction
//Node.shared.fetch(myAddress.address) { (accounts: [Account]?, error: NodeError?) in
//    if let error = error {
//        print(error)
//        completion(nil, .generalError("Unable to verify nonce"))
//        return
//    }
//
//    guard let accounts = accounts, var account = accounts.first else {
//        completion(nil, .generalError("Account needs to be created first"))
//        return
//    }
//
//    account.nonce += 1
//
//    if value != BigUInt(0) {
//        /// Verfity that the account has enough balance to cover the value
//        guard account.balance >= value else {
//            completion(nil, .generalError("Insufficient fund"))
//            return
//        }
//
//        /// Subtract the transferring value from the balance
//        account.balance -= value
//    }
//
//    guard let method = ContractMethods(rawValue: contractMethod.rawValue),
//          let methodData = method.data else {
//              completion(nil, .generalError("Unable to parse the contract method"))
//              return
//          }
//
//    /// Include the extra data such as the contract method , timestamp, latest block number, and/or a newly created account
//    let extraData = TransactionExtraData(contractMethod: methodData, latestBlockNumber: BigUInt(block.number))
//    guard let encodedExtraData = try? JSONEncoder().encode(extraData) else {
//        completion(nil, NodeError.encodingError)
//        return
//    }
//
//    do {
//        // Create a public signature
//        let tx = EthereumTransaction.createLocalTransaction(nonce: account.nonce, to: to ?? myAddress, value: value, data: encodedExtraData)
//        let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: myAddress, password: password)
//        guard let encodedSig = signedTx?.encode(forSignature: false) else {
//            completion(nil, NodeError.encodingError)
//            return
//        }
//
//        completion(encodedSig, nil)
//
//        /// Save the account with an increased nonce
//        try Node.shared.localStorage.saveState(account)
//    } catch {
//        completion(nil, NodeError.generalError("Unable to create a transaction"))
//    }
//    }
