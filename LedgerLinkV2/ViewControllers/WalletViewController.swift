//
//  WalletViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-05.
//

import UIKit
import web3swift
import BigInt
import Network

final class WalletViewController: UIViewController {
    private var receivedTextField: UITextField!
    private var scanButton: UIButton!
    private var balanceLabel: UILabel!
    private var balanceButton: UIButton!
    private var sendAmountLabel: UITextField!
    private var sendButton: UIButton!
    private var qrCodeButton: UIButton!
    private var tableView: UITableView!
    private var results: [String] = []
    private let alert = AlertView()
    private let transactionService = TransactionService()
    private let wallet = LocalStorage()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureTableView()
        setConstraints()
    }
    
    func configureUI() {
        tapToDismissKeyboard()

        view.backgroundColor = .white
        
        receivedTextField = UITextField()
        receivedTextField.placeholder = "Recipient Address: "
        receivedTextField.textColor = .orange
        receivedTextField.layer.borderColor = UIColor.black.cgColor
        receivedTextField.layer.borderWidth = 1
        receivedTextField.textAlignment = .left
        receivedTextField.layer.cornerRadius = 10
        receivedTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(receivedTextField)
        
        scanButton = UIButton()
        scanButton.setTitle("Scan Address", for: .normal)
        scanButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        scanButton.tag = 1
        scanButton.backgroundColor = .black
        scanButton.layer.cornerRadius = 10
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanButton)
        
        balanceLabel = UILabel()
        balanceLabel.text = "Balance: "
        balanceLabel.textColor = .orange
        balanceLabel.layer.borderColor = UIColor.black.cgColor
        balanceLabel.layer.borderWidth = 1
        balanceLabel.textAlignment = .left
        balanceLabel.layer.cornerRadius = 10
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(balanceLabel)

        balanceButton = UIButton()
        balanceButton.setTitle("Check Balance", for: .normal)
        balanceButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        balanceButton.tag = 2
        balanceButton.backgroundColor = .black
        balanceButton.layer.cornerRadius = 10
        balanceButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(balanceButton)
        
        sendAmountLabel = UITextField()
        sendAmountLabel.placeholder = "Amount"
        sendAmountLabel.textColor = .orange
        sendAmountLabel.layer.borderColor = UIColor.black.cgColor
        sendAmountLabel.layer.borderWidth = 1
        sendAmountLabel.textAlignment = .left
        sendAmountLabel.layer.cornerRadius = 10
        sendAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendAmountLabel)
        
        sendButton = UIButton()
        sendButton.setTitle("Send Money", for: .normal)
        sendButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        sendButton.tag = 0
        sendButton.backgroundColor = .black
        sendButton.layer.cornerRadius = 10
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
        
        qrCodeButton = UIButton()
        qrCodeButton.setTitle("Show QR Code", for: .normal)
        qrCodeButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        qrCodeButton.tag = 3
        qrCodeButton.backgroundColor = .black
        qrCodeButton.layer.cornerRadius = 10
        qrCodeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrCodeButton)
        
        /// for testing
        NetworkManager.shared.blockchainReceiveHandler = blockchainReceiveHandler
    }
    
    func configureTableView() {
        tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            receivedTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            receivedTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            receivedTextField.heightAnchor.constraint(equalToConstant: 50),
            receivedTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scanButton.topAnchor.constraint(equalTo: receivedTextField.bottomAnchor, constant: 20),
            scanButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            balanceLabel.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 20),
            balanceLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            balanceLabel.heightAnchor.constraint(equalToConstant: 50),
            balanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            balanceButton.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 20),
            balanceButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            balanceButton.heightAnchor.constraint(equalToConstant: 50),
            balanceButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            sendAmountLabel.topAnchor.constraint(equalTo: balanceButton.bottomAnchor, constant: 20),
            sendAmountLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            sendAmountLabel.heightAnchor.constraint(equalToConstant: 50),
            sendAmountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            sendButton.topAnchor.constraint(equalTo: sendAmountLabel.bottomAnchor, constant: 20),
            sendButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            qrCodeButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 20),
            qrCodeButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            qrCodeButton.heightAnchor.constraint(equalToConstant: 50),
            qrCodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            tableView.topAnchor.constraint(equalTo: qrCodeButton.bottomAnchor, constant: 50),
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                do {
                    try send()
                } catch {
                    alert.show(error, for: self)
                }
                
                break
            case 1:
                scan()
                break
            case 2:
                do {
                    try checkBalance()
                } catch {
                    alert.show(error, for: self)
                }
                break
            case 3:
                showQRCode()
                break
            default:
                break
        }
    }
    
    private func send() throws {
        view.endEditing(true)
        
        guard let address = receivedTextField.text,
              let toAddress = EthereumAddress(address) else {
            throw TxError.generalError("Your address could not be prepared.")
        }
        
        guard let sendAmount = sendAmountLabel.text,
              let value = BigUInt(sendAmount) else {
            throw TxError.generalError("Amount cannot be zero.")
        }

        guard let contractMethod = ContractMethods.transferValue.data else {
            throw TxError.generalError("Unable to encode contract parameters")
        }
        let extraData = TransactionExtraData(contractMethod: contractMethod)
        
        transactionService.prepareTransaction(extraData: extraData, to: toAddress, value: value, password: "1") { (data, error) in
            if let error = error {
                print(error)
            }
            
            if let data = data {
                NetworkManager.shared.enqueue(data)
            }
        }
        
        try checkBalance()
    }

    private func scan() {
        let scannerVC = ScannerViewController()
        scannerVC.delegate = self
        self.present(scannerVC, animated: true, completion: nil)
    }
    
    private func showQRCode() {
        var walletModel: KeyWalletModel?
        do {
            walletModel = try wallet.getWallet()
        } catch {
            alert.show(error, for: self)
        }
        
        let qrCodeVC = QRCodeViewController()
        qrCodeVC.addressString = walletModel?.address
        self.present(qrCodeVC, animated: true, completion: nil)
    }
    
    private func checkBalance() throws {
        guard let account = try NodeDB.shared.getMyAccount() else {
            alert.show("Wallet not found. Have you set up your wallet yet?", for: self)
            return
        }
        balanceLabel.text = account.balance.description
    }
    
    func blockchainReceiveHandler(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let ac = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self?.present(ac, animated: true)
        }
    }
}

extension WalletViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let sender = results[indexPath.row]
        cell.textLabel?.text = sender
        return cell
    }
}

extension WalletViewController: ScannerDelegate {
    
    // MARK: - scannerDidOutput
    func scannerDidOutput(code: String) {
        let text = code
        receivedTextField.text = text
    }
}
