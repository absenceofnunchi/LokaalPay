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
        extraData: TransactionExtraData,
        to: EthereumAddress?,
        value: BigUInt = BigUInt(0),
        password: String,
        completion: @escaping (Data?, TxError?) -> Void
    ) {
        guard value >= BigUInt(0) else {
            completion(nil, TxError.generalError("Invalid valud amount"))
            return
        }
        
        DispatchQueue.global().async {
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
            /// Include the extra data such as the contract method and/or a newly created account
            guard let encodedExtraData = try? JSONEncoder().encode(extraData) else {
                completion(nil, TxError.encodingError)
                return
            }
            
            /// Fetch the exsting the nonce to be added to the new transaction
            guard var account: Account = try? Node.shared.localStorage.getAccount(myAddress) else {
                completion(nil, .generalError("Unable to verify nonce"))
                return
            }
            
            account.nonce += 1
            
            if value != BigUInt(0) {
                guard account.balance >= value else {
                    completion(nil, .generalError("Insufficient fund"))
                    return
                }
                
                account.balance -= value
            }
            
            do {
                // Create a public signature
                let tx = EthereumTransaction.createLocalTransaction(nonce: account.nonce, to: to ?? myAddress, value: value, data: encodedExtraData)
                let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: myAddress, password: password)
                guard let encodedSig = signedTx?.encode(forSignature: false) else {
                    completion(nil, TxError.encodingError)
                    return
                }
                
                /// Save the sender account with an updated nonce and possibly value
                try Node.shared.localStorage.saveState(account)
                
                completion(encodedSig, nil)
            } catch {
                completion(nil, TxError.generalError("Unable to create a transaction"))
            }
        }
    }
}
