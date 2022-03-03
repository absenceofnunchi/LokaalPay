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
    var passwordTextField: UITextField!
    var createButton: UIButton!
    var deleteBlockchainButton: UIButton!
    var addressLabel: UILabel!
    let keysService = KeysService()
    let localStorage = LocalStorage()
    let alert = AlertView()
    var storage = Set<AnyCancellable>()
    let transactionService = TransactionService()
    var createWalletMode: Bool = false
    var isPeerConnected: Bool = false {
        didSet {
            if isPeerConnected && createWalletMode {
                createWallet()
            }
        }
    }
    private let dispatchQueue = DispatchQueue(label: "taskQueue", qos: .background)
    private let semaphore = DispatchSemaphore(value: 1)
    
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
        let password = "1"
        let chainID = 11111
        
        print("start")
        let group = DispatchGroup()
        
        group.enter()
        self.dispatchQueue.async {
            self.semaphore.wait()
            
            NetworkManager.shared.requestBlockchainFromAllPeers { error in
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
