//
//  LedgerLinkV2Tests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-01.
//

import XCTest
import BigInt
import web3swift

@testable import LedgerLinkV2

class LedgerLinkV2Tests: XCTestCase {

    func test_transactionTest() {
        let password = "111111"
        KeysService().createNewWallet(password: password) { (keyWalletModel, error) in
            if let error = error {
                print("wallet error", error.localizedDescription)
            }
            
            guard let keyWalletModel = keyWalletModel,
                  let data = keyWalletModel.data else { return }
            
            let keystoreManager = KeystoreManager([EthereumKeystoreV3(data)!])
            
            let tx = EthereumTransaction.createLocalTransaction(nonce: BigUInt(0), to: EthereumAddress("0xFadAFCE89EA2221fa33005640Acf2C923312F2b9")!, value: BigUInt(10))
            do {
                let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: EthereumAddress("0xFadAFCE89EA2221fa33005640Acf2C923312F2b9")!, password: password)
                print(signedTx as Any)
            } catch {
                print("signTx error", error)
            }
        }
    }
}
