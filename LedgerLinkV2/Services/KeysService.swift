//
//  KeysService.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import Foundation
import web3swift

struct KeyWalletModel {
    let address: String
    let data: Data?
    
    static func fromCoreData(crModel: WalletCoreData) -> KeyWalletModel? {
        guard let address = crModel.address, let data = crModel.data else { return nil }
        let model = KeyWalletModel(address: address, data: data)
        return model
    }
}

protocol IKeysService {
    func keystoreManager() throws -> KeystoreManager?
    func selectedWallet() throws -> KeyWalletModel?
}

extension IKeysService {
    func keystoreManager() throws -> KeystoreManager? {
        var fetchedWallet: KeyWalletModel!
        
        do {
            fetchedWallet = try selectedWallet()
        } catch {
            throw NodeError.walletRetrievalError
        }
        
        guard let data = fetchedWallet?.data else {
            return KeystoreManager.defaultManager
        }
        return KeystoreManager([EthereumKeystoreV3(data)!])
    }
}

class KeysService: IKeysService {
    let localStorage = LocalStorage()
    
    func selectedWallet() throws -> KeyWalletModel? {
        return try localStorage.getWallet()
    }
    
    func addNewWalletWithPrivateKey(key: String, password: String, completion: @escaping (KeyWalletModel?, NodeError?) -> Void) {
        let text = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data.fromHex(text) else {
            completion(nil, NodeError.hexConversionError)
            return
        }
        
        guard let newWallet = try? EthereumKeystoreV3(privateKey: data, password: password) else {
            completion(nil, NodeError.walletCreateError)
            return
        }
        
        guard newWallet.addresses?.count == 1 else {
            completion(nil, NodeError.walletCountError)
            return
        }
        
        guard let keyData = try? JSONEncoder().encode(newWallet.keystoreParams) else {
            completion(nil, NodeError.walletEncodeError)
            return
        }
        
        guard let address = newWallet.addresses?.first?.address else {
            completion(nil, NodeError.walletAddressFetchError)
            return
        }
        
        let walletModel = KeyWalletModel(address: address, data: keyData)
        completion(walletModel, nil)
    }
    
    func createNewWallet(password: String, completion: @escaping (KeyWalletModel?, NodeError?) -> Void) {
        DispatchQueue.global().async {
            guard let newWallet = try? EthereumKeystoreV3(password: password) else {
                completion(nil, NodeError.walletCreateError)
                return
            }

            guard newWallet.addresses?.count == 1 else {
                completion(nil, NodeError.walletCountError)
                return
            }

            guard let keydata = try? JSONEncoder().encode(newWallet.keystoreParams) else {
                completion(nil, NodeError.walletEncodeError)
                return
            }

            guard let address = newWallet.addresses?.first?.address else {
                completion(nil, NodeError.walletAddressFetchError)
                return
            }

            let walletModel = KeyWalletModel(address: address, data: keydata)
            completion(walletModel, nil)
        }
    }
    
//    func createNewWallet(password: String, completion: @escaping (KeyWalletModel?, WalletError?) -> Void) {
//
//        guard let newWallet = try? EthereumKeystoreV3(password: password) else {
//            completion(nil, WalletError.walletCreateError)
//            return
//        }
//
//        guard newWallet.addresses?.count == 1 else {
//            completion(nil, WalletError.walletCountError)
//            return
//        }
//
//        guard let keydata = try? JSONEncoder().encode(newWallet.keystoreParams) else {
//            completion(nil, WalletError.walletEncodeError)
//            return
//        }
//
//        guard let address = newWallet.addresses?.first?.address else {
//            completion(nil, WalletError.walletAddressFetchError)
//            return
//        }
//
//        let walletModel = KeyWalletModel(address: address, data: keydata)
//        completion(walletModel, nil)
//    }
    
    func getWalletPrivateKey(password: String) throws -> String? {
        guard let selectedWallet = try selectedWallet(), let address = EthereumAddress(selectedWallet.address) else {
            print(NodeError.walletAddressFetchError)
            return nil
        }
        let data = try keystoreManager()?.UNSAFE_getPrivateKeyData(password: password, account: address)
        return data?.toHexString()
    }
    
    func resetPassword(oldPassword: String, newPassword: String, completion: @escaping (KeyWalletModel?, NodeError?) -> Void) {
        var fetchedWallet: KeyWalletModel!
        do {
            fetchedWallet = try selectedWallet()
        } catch {
            completion(nil, NodeError.walletRetrievalError)
        }
        
        guard let data = fetchedWallet.data,
              let ks = EthereumKeystoreV3(data) else {
                  DispatchQueue.main.async {
                      completion(nil, NodeError.failureToFetchOldPassword)
                  }
                  return
              }
        
        do {
            try ks.regenerate(oldPassword: oldPassword, newPassword: newPassword)
            guard let pk = try getWalletPrivateKey(password: oldPassword) else { return }
            addNewWalletWithPrivateKey(key: pk, password: newPassword) { (wallet, error) in
                if let error = error {
                    print("error from getting the private key", error)
                }
                
                DispatchQueue.main.async {
                    completion(wallet, nil)
                }
            }
        } catch {
            DispatchQueue.main.async {
                completion(nil, NodeError.failureToRegeneratePassword)
            }
        }
    }
}
