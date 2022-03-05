//
//  EthereumTransaction+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-07.
//

import Foundation
import web3swift
import BigInt
import CryptoKit

/// A full transaction order of creation
/// 1. Create transaction options.
/// 2. send https://github.com/skywinder/web3swift/blob/d0b15b9f6d66baa910b1ec32f9a10345f8498b42/Sources/web3swift/Web3/Web3%2BMutatingTransaction.swift#L187
/// 3. sendPromise https://github.com/skywinder/web3swift/blob/d0b15b9f6d66baa910b1ec32f9a10345f8498b42/Sources/web3swift/Web3/Web3%2BMutatingTransaction.swift#L176
/// 4. sendTransactionPromise https://github.com/skywinder/web3swift/blob/5484e81580219ea491d48e94f6aef6f18d8ec58f/Sources/web3swift/Promises/Promise%2BWeb3%2BEth%2BSendTransaction.swift#L13
/// 5. EthereumTransaction.createRequest https://github.com/skywinder/web3swift/blob/5484e81580219ea491d48e94f6aef6f18d8ec58f/Sources/web3swift/Promises/Promise%2BWeb3%2BEth%2BSendTransaction.swift#L42
/// 6. Web3Signer.signTX https://github.com/skywinder/web3swift/blob/5484e81580219ea491d48e94f6aef6f18d8ec58f/Sources/web3swift/Promises/Promise%2BWeb3%2BEth%2BSendTransaction.swift#L66
/// 7. sign https://github.com/skywinder/web3swift/blob/39520ec9dbbef40775727330f922c0a1876d8909/Sources/web3swift/Transaction/TransactionSigner.swift#L36
/// 8. sendRawTransactionPromise https://github.com/skywinder/web3swift/blob/5484e81580219ea491d48e94f6aef6f18d8ec58f/Sources/web3swift/Promises/Promise%2BWeb3%2BEth%2BSendRawTransaction.swift#L20

extension EthereumTransaction {
    public init(nonce: BigUInt, to: EthereumAddress, gasPrice: BigUInt = BigUInt(0), gasLimit: BigUInt = BigUInt(0), value: BigUInt = BigUInt(0), data: Data = Data()) {
        self.init(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: data)
        self.nonce = nonce
    }
    
    
    public func getHash() -> String? {
        guard let encoded = self.encode(),
              let compressed = encoded.compressed else { return nil }
        return compressed.sha256().toHexString()
    }
    
    /// Create a transaction signature for a local transaction.
    /// Doesn't require gas because no mining reward exists.
    /// TODO: Change the chain ID to the 4-digit password set by the host
    public static func createLocalTransaction(nonce: BigUInt, to: EthereumAddress, value: BigUInt = BigUInt(0), data: Data = Data()) -> EthereumTransaction {
        return EthereumTransaction(nonce: nonce, to: to, value: value, data: data)
    }
    
    public static func signLocalTransaction(keystoreManager: KeystoreManager? = nil, transaction: EthereumTransaction, from: EthereumAddress, password: String) throws -> EthereumTransaction? {
        var tx = transaction
        var km = keystoreManager
        
        if km == nil {
            do {
                km = try KeysService().keystoreManager()
            } catch {
                throw NodeError.walletRetrievalError
            }
        }
        
        guard let km = km else { return nil }
        do {
            try Web3Signer.signTX(transaction: &tx, keystore: km, account: from, password: password)
        } catch {
            throw Web3Error.inputError(desc: "Failed to locally sign a transaction")
        }
        
        /// Assign an ID for the transaction to conform to TreeConfigurable (or Comparable to be more sepecific)
        /// The TreeConfigurable comformance is needed for the Red Black tree.
        /// In the case of EthereumTransaction, this ID is essentially a transaction ID.
        //        guard let hash = tx.hashForSignature() else { return nil }
        //        tx.id = hash
        //
        return tx
    }
}
