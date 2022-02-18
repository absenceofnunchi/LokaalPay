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
        DispatchQueue.global().async {
            /// The local storage which uses the container from app delegate has to be run on the main thread.
            var keystoreManager: KeystoreManager?
            do {
                keystoreManager = try KeysService().keystoreManager()
            } catch {
                completion(nil, TxError.walletError(.walletRetrievalError))
            }
            
            guard let myAddress = keystoreManager?.addresses?.first,
                  let myEthAddress = EthereumAddress(myAddress.address) else {
                      completion(nil, TxError.generalError("Your address could not be prepared."))
                      return
                  }
            
            guard let encodedExtraData = try? JSONEncoder().encode(extraData) else {
                completion(nil, TxError.encodingError)
                return
            }
            
            do {
                let tx = EthereumTransaction.createLocalTransaction(to: to ?? myEthAddress, value: value, data: encodedExtraData)
                let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: myEthAddress, password: password)
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
