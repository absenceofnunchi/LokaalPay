//
//  GuestLoginViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-13.
//

/*
 Abstract:
 Create a password for the guest's personal account.
 The password is saved in UserDefaults.
 The account is not yet created until the guest selects an event from EventsVC.
 */

import UIKit

final class GuestLoginViewController: GuestViewController {
    @objc override func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                dismiss(animated: true, completion: nil)
            case 1:
                createAccount()
            case 2:
                goToImportAccount()
            default:
                break
        }
    }
    
    private func createAccount() {
        guard isFieldValid(passwordTextField, alertMsg: "Event password cannot be empty") else {
            return
        }
        
        guard isNumber(passwordTextField, alertMsg: "The passcode has to be numerical") else {
            return
        }
        
        guard isFieldValid(passwordConfirmTextField, alertMsg: "Event password cannot be empty") else {
            return
        }
        
        guard isNumber(passwordConfirmTextField, alertMsg: "The passcode has to be numerical") else {
            return
        }
        
        guard let password = passwordTextField.text else {
            return
        }
        
        UserDefaults.standard.set(password, forKey: UserDefaultKey.walletPassword)
        passwordTextField.text = nil
        passwordConfirmTextField.text = nil
        
        let vc = EventsViewController()
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}

extension GuestLoginViewController {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        createButton.isEnabled = false
        
        let yDelta = view.bounds.origin.y - passwordBlurView.frame.origin.y
        
        if (!(passwordTextField.text?.isEmpty ?? true) ||
            !(passwordConfirmTextField.text?.isEmpty ?? true)) &&
            passwordTextField.text != passwordConfirmTextField.text {
            passwordStatusLabel.isHidden = false
            passwordStatusLabel.text = "Passwords don't match"
            passwordTextField.textColor = UIColor.red
            passwordConfirmTextField.textColor = UIColor.red
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
            }
        } else if (!(passwordTextField.text?.isEmpty ?? true) ||
                   !(passwordConfirmTextField.text?.isEmpty ?? true)) &&
                    ((passwordTextField.text?.count)! != 4) {
            passwordStatusLabel.isHidden = false
            passwordStatusLabel.text = "Password has to be 4 digits"
            passwordConfirmTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
            }
        } else {
            passwordTextField.textColor = UIColor.lightGray
            passwordConfirmTextField.textColor = UIColor.lightGray
            
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 0 : -100)
            }
            
            createButton.isEnabled = true
        }
        
        return true
    }
}
