//
//  SignupViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import UIKit
import BigInt
import web3swift
import Combine

final class SignupViewController: UIViewController {
    var passwordTextField: UITextField!
    var createButton: UIButton!
    var addressLabel: UILabel!
    let keysService = KeysService()
    let localStorage = LocalStorage()
    let alert = AlertView()
    var storage = Set<AnyCancellable>()
    let transactionService = TransactionService()
    
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
                createWallet()
                break
            default:
                break
        }
    }
    
    func createWallet() {
//        guard let password = passwordTextField.text, !password.isEmpty else { return }
        let password = "1"
        
        NetworkManager.shared.start()
        
        Deferred {
            Future<KeyWalletModel, WalletError> { [weak self] promise in
                self?.keysService.createNewWallet(password: password) { (keyWalletModel, error) in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    if let keyWalletModel = keyWalletModel {
                        promise(.success(keyWalletModel))
                    }
                }
            }
            .eraseToAnyPublisher()
        }
        .flatMap { (keyWalletModel) -> AnyPublisher<KeyWalletModel, WalletError> in
            Future<KeyWalletModel, WalletError> { [weak self] promise in
                self?.localStorage.saveWallet(wallet: keyWalletModel, completion: { (error) throws in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    promise(.success(keyWalletModel))
                })
            }
            .eraseToAnyPublisher()
        }
        .sink { [weak self] (completion) in
            switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.alert.show(error, for: self)
            }
        } receiveValue: { [weak self] (keyWalletModel) in
            guard let address = EthereumAddress(keyWalletModel.address) else {
                return
            }
            
            let account = Account(address: address, nonce: BigUInt(0), balance: BigUInt(1000))
            
            self?.notifyAccountCreation(account: account)
            
            DispatchQueue.main.async {
                self?.addressLabel.text = keyWalletModel.address
            }
            
            Task {
                await Node.shared.save(account) { error in
                    if let error = error {
                        print(error)
                    }
                }
            }
        }
        .store(in: &storage)
    }
    
    func notifyAccountCreation(account: Account) {
        guard let contractMethod = ContractMethods.createAccount.data else {
            return
        }
        
        let extraData = TransactionExtraData(contractMethod: contractMethod, account: account)
        transactionService.prepareTransaction(extraData: extraData, to: nil, password: "1") { (data, error) in
            if let error = error {
                print(error)
            }
            
            if let data = data {
                NetworkManager.shared.enqueue(data)
                Node.shared.addValidatedTransaction(data)
            }
        }
    }
}
