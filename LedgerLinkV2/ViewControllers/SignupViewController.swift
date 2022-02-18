//
//  SignupViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import UIKit
import BigInt
import web3swift

final class SignupViewController: UIViewController {
    var passwordTextField: UITextField!
    var createButton: UIButton!
    var addressLabel: UILabel!
    let keysService = KeysService()
    let localStorage = LocalStorage()
    let alert = AlertView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
    }
    
    func configureUI() {
        view.backgroundColor = .white
        self.tapToDismissKeyboard()
        
        passwordTextField = UITextField()
        passwordTextField.isSecureTextEntry = true
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.gray.cgColor
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.placeholder = "Create a new password"
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordTextField)
        
        addressLabel = UILabel()
        addressLabel.layer.borderWidth = 1
        addressLabel.layer.borderColor = UIColor.gray.cgColor
        addressLabel.layer.cornerRadius = 10
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addressLabel)
        
        createButton = UIButton()
        createButton.setTitle("Create Wallet", for: .normal)
        createButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        createButton.tag = 0
        createButton.backgroundColor = .black
        createButton.layer.cornerRadius = 10
        createButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            passwordTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            passwordTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            addressLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            addressLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            addressLabel.heightAnchor.constraint(equalToConstant: 50),
            addressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            createButton.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 20),
            createButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                do {
                    try createWallet()
                } catch {
                    alert.show(error, for: self)
                }
                break
            default:
                break
        }
    }
    
    func createWallet() throws {
//        guard let password = passwordTextField.text, !password.isEmpty else { return }
        let password = "1"
        keysService.createNewWallet(password: password) { [weak self] (keyWalletModel, error) in
            if let error = error {
                print("wallet create error", error.localizedDescription)
            }
            
            if let keyWalletModel = keyWalletModel {
                self?.localStorage.saveWallet(wallet: keyWalletModel, completion: { (error) throws in
                    if let error = error {
                        print("wallet save error", error.localizedDescription)
                    }
                    
                    guard let address = EthereumAddress(keyWalletModel.address) else {
                        throw NodeError.generalError("Address Save error")
                    }
                    let account = Account(address: address, nonce: BigUInt(0), balance: BigUInt(1000))
                    try NodeDB.shared.addData(account)
                    DispatchQueue.main.async {
                        self?.addressLabel.text = keyWalletModel.address
                    }
                })
            }
        }
    }
}
