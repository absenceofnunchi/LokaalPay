//
//  SendViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-09.
//

import UIKit
import web3swift
import BigInt

final class SendViewController: WalletModalViewController {
    private var destinationTextField: UITextField!
    private var amountTextField: UITextField!
    private var scanButton: UIButton!
    private var sendButton: UIButton!
    private var maxButton: UIButton!
    private let alert = AlertView()
    private let transactionService = TransactionService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getCurrency()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadAnimation()
    }
    
    override func configureUI() {
        super.configureUI()
        
        titleLabel.text = "Send Currency"
        
        destinationTextField = createTextField(placeHolderText: " Recipient Address", placeHolderImageString: "magnifyingglass")
        destinationTextField.alpha = 0
        destinationTextField.transform = CGAffineTransform(translationX: 0, y: 40)
        destinationTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(destinationTextField)
        
        guard let scanButtonImage = UIImage(systemName: "qrcode.viewfinder") else { return }
        scanButton = UIButton.systemButton(with: scanButtonImage.withTintColor(.white, renderingMode: .alwaysOriginal), target: self, action: #selector(buttonHandler(_:)))
        scanButton.backgroundColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        scanButton.transform = CGAffineTransform(translationX: 0, y: 40)
        scanButton.layer.cornerRadius = 7
        scanButton.alpha = 0
        scanButton.tag = 0
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanButton)
        
        amountTextField = createTextField(placeHolderText: " Amount to send", placeHolderImageString: "creditcard")
        amountTextField.alpha = 0
        amountTextField.keyboardType = .decimalPad
        amountTextField.transform = CGAffineTransform(translationX: 0, y: 40)
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(amountTextField)
        
        maxButton = UIButton()
        maxButton.setTitle("MAX", for: .normal)
        maxButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        maxButton.tag = 1
        maxButton.alpha = 0
        maxButton.layer.cornerRadius = 7
        maxButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        maxButton.transform = CGAffineTransform(translationX: 0, y: 40)
        maxButton.backgroundColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        maxButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(maxButton)
        
        sendButton = UIButton()
        sendButton.transform = CGAffineTransform(translationX: 0, y: 40)
        sendButton.alpha = 0
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        sendButton.tag = 2
        sendButton.backgroundColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        sendButton.layer.cornerRadius = 7
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
    }
    
    override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
            destinationTextField.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 35),
            destinationTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            destinationTextField.trailingAnchor.constraint(equalTo: scanButton.leadingAnchor, constant: -10),
            destinationTextField.heightAnchor.constraint(equalToConstant: 50),
            
            scanButton.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 35),
            scanButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.widthAnchor.constraint(equalToConstant: 50),
            
            amountTextField.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 45),
            amountTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountTextField.trailingAnchor.constraint(equalTo: maxButton.leadingAnchor, constant: -10),
            amountTextField.heightAnchor.constraint(equalToConstant: 50),
            
            maxButton.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 45),
            maxButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            maxButton.heightAnchor.constraint(equalToConstant: 50),
            maxButton.widthAnchor.constraint(equalToConstant: 50),
            
            sendButton.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 45),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    /// Cascasding animation for loading
    private func loadAnimation() {
        let totalCount = 4
        let duration = 1.0 / Double(totalCount)
        
        let animation = UIViewPropertyAnimator(duration: 0.5, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.titleLabel.alpha = 1
                    self?.titleLabel.transform = .identity
                    
                    self?.lineView.alpha = 1
                    self?.lineView.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    self?.destinationTextField.alpha = 1
                    self?.destinationTextField.transform = .identity
                    
                    self?.scanButton.alpha = 1
                    self?.scanButton.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 3 / Double(totalCount), relativeDuration: duration) {
                    self?.amountTextField.alpha = 1
                    self?.amountTextField.transform = .identity
                    
                    self?.maxButton.alpha = 1
                    self?.maxButton.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 4 / Double(totalCount) - 0.1, relativeDuration: duration) {
                    self?.sendButton.alpha = 1
                    self?.sendButton.transform = .identity
                }
                
            })
        }
        
        animation.startAnimation()
    }
    
    /// Get currency name to display as the title
    private func getCurrency() {
        Node.shared.localStorage.getBlock(Int32(0)) { [weak self] (block: FullBlock?, error: NodeError?) in
            if let error = error {
                self?.alert.show(error, for: self)
                return
            }
            
            if let block = block,
               let extraData = block.extraData,
               let eventInfo = try? JSONDecoder().decode(EventInfo.self, from: extraData) {
                self?.titleLabel.text = "Send \(eventInfo.currencyName)"
            }
        }
    }
    
    @objc func buttonHandler(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                /// Scan recipient address
                let scannerVC = ScannerViewController()
                scannerVC.delegate = self
                scannerVC.modalPresentationStyle = .fullScreen
                self.present(scannerVC, animated: true, completion: nil)
                break
            case 1:
                /// Get max balance
                Node.shared.getMyAccount { [weak self] (acct, error) in
                    if let error = error {
                        self?.alert.show(error, for: self)
                        return
                    }
                    
                    if let acct = acct {
                        self?.amountTextField.text = "\(acct.balance)"
                    }
                }
            case 2:
                send { [weak self] (error) in
                    if let error = error {
                        self?.alert.show(error, for: self)
                        return
                    }
                }
            default:
                break
        }
    }

    /// Send value to a peer
    private func send(completion: @escaping (NodeError?) -> Void) {
        view.endEditing(true)
        
        guard let address = destinationTextField.text,
              !address.isEmpty,
              let toAddress = EthereumAddress(address) else {
                  completion(NodeError.generalError("The recipient address could not be prepared."))
                  return
              }
        
        guard let sendAmount = amountTextField.text,
              !sendAmount.isEmpty,
              let value = BigUInt(sendAmount),
              value != 0 else {
                  completion(NodeError.generalError("Amount cannot be zero."))
                  return
              }
        
        guard let password = UserDefaults.standard.string(forKey: UserDefaultKey.walletPassword) else {
            completion(NodeError.generalError("Unable to obtain your wallet password. Please try logging in again"))
            return
        }
        
        showSpinner()
        transactionService.prepareTransaction(.transferValue, to: toAddress, value: value, password: password) { [weak self] (data, error) in
            if let error = error {
                completion(error)
                return
            }
            
            if let data = data {
                NetworkManager.shared.sendDataToAllPeers(data: data)
                /// For validators only to include the validated transactions in a block
                /// For non validators, the pool of validated transactions will be cleared after the auto relay
                Node.shared.addValidatedTransaction(data)
 
                DispatchQueue.main.async {
                    self?.amountTextField.text = nil
                    self?.hideSpinner()
                    self?.dismiss(animated: true)
                }
            }
        }
    }
}

extension SendViewController: ScannerDelegate {
    
    // MARK: - scannerDidOutput
    func scannerDidOutput(code: String) {
        destinationTextField.text = code
    }
}

