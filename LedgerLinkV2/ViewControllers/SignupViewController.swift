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
import MultipeerConnectivity

final class SignupViewController: UIViewController {
    private var passswordTitleLabel: UILabel!
    private var passwordTextField: UITextField!
    private var createButton: UIButton!
    private var deleteBlockchainButton: UIButton!
    private var addressTitleLabel: UILabel!
    private var addressLabel: UILabel!
    private var roleTitleLabel: UILabel!
    private var yesButton: UIButton!
    private var noButton: UIButton!
    private var chainIDTitleLabel: UILabel!
    private var chainIDTextField: UITextField!
    private let keysService = KeysService()
    private let localStorage = LocalStorage()
    private let alert = AlertView()
    private var storage = Set<AnyCancellable>()
    private let transactionService = TransactionService()
    private var createWalletMode: Bool = false
    private var isPeerConnected: Bool = false {
        didSet {
            if isPeerConnected && createWalletMode {
                createWallet()
            }
        }
    }
    private let dispatchQueue = DispatchQueue(label: "taskQueue", qos: .background)
    private let semaphore = DispatchSemaphore(value: 1)
    private var isHost: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
        
        NetworkManager.shared.peerConnectedHandler = peerConnectedHandler
    }
    
    func peerConnectedHandler(_ peerID: MCPeerID) {
        isPeerConnected = true
    }
    
    func configureUI() {
        view.backgroundColor = .white
        self.tapToDismissKeyboard()
        
        passswordTitleLabel = UILabel()
        passswordTitleLabel.text = "Password"
        passswordTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passswordTitleLabel)
        
        passwordTextField = UITextField()
        passwordTextField.text = "1"
        passwordTextField.isSecureTextEntry = false
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.gray.cgColor
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordTextField)
        
        addressTitleLabel = UILabel()
        addressTitleLabel.text = "Account Address"
        addressTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addressTitleLabel)
        
        addressLabel = UILabel()
        addressLabel.layer.borderWidth = 1
        addressLabel.layer.borderColor = UIColor.gray.cgColor
        addressLabel.layer.cornerRadius = 10
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addressLabel)
        
        chainIDTitleLabel = UILabel()
        chainIDTitleLabel.text = "Chain ID"
        chainIDTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chainIDTitleLabel)
        
        chainIDTextField = UITextField()
        chainIDTextField.text = "11111"
        chainIDTextField.layer.borderWidth = 1
        chainIDTextField.layer.borderColor = UIColor.gray.cgColor
        chainIDTextField.layer.cornerRadius = 10
        chainIDTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chainIDTextField)
        
        roleTitleLabel = UILabel()
        roleTitleLabel.text = "Are you a host?"
        roleTitleLabel.textAlignment = .center
        roleTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(roleTitleLabel)
        
        yesButton = UIButton()
        yesButton.setTitle("Yes", for: .normal)
        yesButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        yesButton.tag = 2
        yesButton.backgroundColor = .black
        yesButton.layer.cornerRadius = 10
        yesButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(yesButton)
        
        noButton = UIButton()
        noButton.setTitle("No", for: .normal)
        noButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        noButton.tag = 3
        noButton.backgroundColor = .black
        noButton.layer.cornerRadius = 10
        noButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noButton)
        
        createButton = UIButton()
        createButton.setTitle("Create Wallet", for: .normal)
        createButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        createButton.tag = 0
        createButton.backgroundColor = .black
        createButton.layer.cornerRadius = 10
        createButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createButton)
        
        deleteBlockchainButton = UIButton()
        deleteBlockchainButton.setTitle("Delete All Blockchain", for: .normal)
        deleteBlockchainButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        deleteBlockchainButton.tag = 1
        deleteBlockchainButton.backgroundColor = .black
        deleteBlockchainButton.layer.cornerRadius = 10
        deleteBlockchainButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteBlockchainButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            passswordTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            passswordTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            passswordTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            passswordTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            passwordTextField.topAnchor.constraint(equalTo: passswordTitleLabel.bottomAnchor, constant: 20),
            passwordTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            passwordTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            addressTitleLabel.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            addressTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            addressTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            addressTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            addressLabel.topAnchor.constraint(equalTo: addressTitleLabel.bottomAnchor, constant: 20),
            addressLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            addressLabel.heightAnchor.constraint(equalToConstant: 50),
            addressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            chainIDTitleLabel.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 20),
            chainIDTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            chainIDTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            chainIDTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            chainIDTextField.topAnchor.constraint(equalTo: chainIDTitleLabel.bottomAnchor, constant: 20),
            chainIDTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            chainIDTextField.heightAnchor.constraint(equalToConstant: 50),
            chainIDTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            roleTitleLabel.topAnchor.constraint(equalTo: chainIDTextField.bottomAnchor, constant: 20),
            roleTitleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            roleTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            roleTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            yesButton.topAnchor.constraint(equalTo: roleTitleLabel.bottomAnchor, constant: 20),
            yesButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            yesButton.heightAnchor.constraint(equalToConstant: 50),
            yesButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -150),
            
            noButton.topAnchor.constraint(equalTo: roleTitleLabel.bottomAnchor, constant: 20),
            noButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            noButton.heightAnchor.constraint(equalToConstant: 50),
            noButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 150),
            
            createButton.topAnchor.constraint(equalTo: noButton.bottomAnchor, constant: 20),
            createButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            deleteBlockchainButton.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 20),
            deleteBlockchainButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            deleteBlockchainButton.heightAnchor.constraint(equalToConstant: 50),
            deleteBlockchainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                initiateConnectionAndCreateWallet()
                break
            case 1:
                deleteAllBlockchain()
            case 2:
                isHost = true
            case 3:
                isHost = false
            default:
                break
        }
    }
    
    private func initiateConnectionAndCreateWallet() {
        showSpinner()

        /// Start the server to download blockchain and to sent a trasaction regarding the account creation.
        NetworkManager.shared.start()
        createWalletMode = true
        Node.shared.deleteAll(of: .blockCoreData)
    }
        
    private func createWallet() {
        guard let password = passwordTextField.text,
              let chainID = chainIDTextField.text else {
            alert.show("Password Required", for: self)
            return
        }
        
        UserDefaults.standard.set(password, forKey: "password")
        
        print("start")
        let group = DispatchGroup()
        
        group.enter()
        self.dispatchQueue.async {
            self.semaphore.wait()
            NetworkManager.shared.requestBlockchainFromAllPeers(upto: 1) { error in
                if let error = error {
                    print(error)
                    group.leave()
                    return
                }
                
                print("stage 1")
                self.semaphore.signal()
                group.leave()
            }
            
            UserDefaults.standard.set(chainID, forKey: "chainID")
        }
        
        group.enter()
        self.dispatchQueue.async { [weak self] in
            self?.semaphore.wait()
            self?.keysService.createNewWallet(password: password) { (keyWalletModel, error) in
                if let error = error {
                    print(error)
                    group.leave()
                    self?.semaphore.signal()
                    return
                }
                
                guard let keyWalletModel = keyWalletModel else {
                    group.leave()
                    return
                }
                
                print("stage 2")
                self?.localStorage.saveWallet(wallet: keyWalletModel, completion: { (error) in
                    if let error = error {
                        print(error)
                        group.leave()
                        return
                    }
                    
                    print("stage 2.5")
                    
                    /// Propogate the creation of the new account to peers
                    self?.transactionService.prepareTransaction(.createAccount, to: nil, password: "1") { data, error in
                        if let error = error {
                            print("notify error", error)
                            group.leave()
                            return
                        }
                        
                        guard let data = data else {
                            group.leave()
                            return
                        }
                        
                        print("stage 3")
                        NetworkManager.shared.sendDataToAllPeers(data: data)
                        
                        /// Update the UI with the new address
                        DispatchQueue.main.async {
                            self?.addressLabel.text = keyWalletModel.address
                        }
                        
                        print("stage 4")
                        self?.semaphore.signal()
                        group.leave()
                    }
                })
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            
            // Perform any task once all the intermediate tasks (fetchA(), fetchB(), fetchC()) are completed.
            // This block of code will be called once all the enter and leave statement counts are matched.
            print("stage 5")
            self?.createWalletMode = false
            self?.hideSpinner()
        }
        print("incomplete")
    }
    
    private func notifyAccountCreation(account: Account, promise:  @escaping (Result<Bool, NodeError>) -> Void) {
        transactionService.prepareTransaction(.createAccount, to: nil, password: "1") { data, error in
            if let error = error {
                print("notify error", error)
                promise(.failure(.generalError("Notify account creation error")))
                return
            }
            
            if let data = data {
                NetworkManager.shared.sendDataToAllPeers(data: data)
                Node.shared.addValidatedTransaction(data)
            }
        }
    }
    
    private func deleteAllBlockchain() {
        Node.shared.deleteAll()
    }
    
    @objc func didReceiveBlockchain() {
        print("didReceive notification")
    }
}

final class Action: NSObject {
    
    private let _action: () -> ()
    
    init(action: @escaping () -> ()) {
        _action = action
        super.init()
    }
    
    @objc func action() {
        _action()
    }
    
}
