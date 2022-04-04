//
//  GuestImportViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-04.
//

/*
 Abstract:
 Imports an existing wallet for Guest using a passcode and a private key.
 */

import UIKit

final class GuestImportViewController: GuestViewController {
    let keyService = KeysService()
    
    override func configureUI() {
        super.configureUI()
        /// password confirm text field doubles as a field for a private key for a guest wanting to import a wallet. For a guest wanting to create a new wallet, the field is used to confirm a passcode about to be created
        passwordConfirmTextField.attributedPlaceholder = createAttributedString(imageString: "lock", imageColor: .gray, text: " Private Key")
        createButton.setTitle("Import Account", for: .normal)
        
        let attTitle = createAttributedString(imageString: nil, imageColor: nil, text: "I don't have an existing account")
        importButton.setAttributedTitle(attTitle, for: .normal)
    }
    
    @objc override func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                view.window?.rootViewController?.dismiss(animated: true)
            case 1:
                importAccount()
            case 2:
                self.dismiss(animated: true)
            default:
                break
        }
    }

    // MARK: - importAccount
    private func importAccount() {
        guard isFieldValid(passwordTextField, alertMsg: "Event password cannot be empty") else {
            return
        }
        
        guard isNumber(passwordTextField, alertMsg: "The passcode has to be numerical") else {
            return
        }
        
        guard let password = passwordTextField.text else {
            return
        }
        
        guard let privateKey = passwordConfirmTextField.text, !privateKey.isEmpty else {
            showAlert(alertMsg: "The private key cannot be empty")
            return
        }
        
        showSpinner()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.hideSpinner()
        }
         
        DispatchQueue.global().async { [weak self] in
            self?.keyService.addNewWalletWithPrivateKey(key: privateKey, password: password) { [weak self] (wallet: KeyWalletModel?, error: NodeError?) in
                if case .generalError(let error) = error {
                    self?.showAlert(alertMsg: error)
                    return
                }
                
                guard let wallet = wallet else { return }
                Node.shared.localStorage.saveWallet(wallet: wallet) { (error) in
                    if case .generalError(let error) = error {
                        self?.showAlert(alertMsg: error)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(password, forKey: UserDefaultKey.walletPassword)
                        self?.passwordTextField.text = nil
                        self?.passwordConfirmTextField.text = nil
                        
                        let vc = EventsViewController()
                        vc.transitioningDelegate = self
                        vc.modalPresentationStyle = .fullScreen
                        self?.present(vc, animated: true, completion: nil)
                    }
                }
            }
        }
    }
}
