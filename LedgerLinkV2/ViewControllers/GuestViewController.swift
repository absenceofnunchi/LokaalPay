//
//  GuestViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-04.
//

import UIKit
import web3swift
import Network

class GuestViewController: StatusViewController {
    var downloadButton: UIButton!
    let alert = AlertView()
    let transactionService = TransactionService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
    }
    
    override func configureUI() {
        super.configureUI()
        
        downloadButton = UIButton()
        downloadButton.backgroundColor = .black
        downloadButton.setTitle("Download Chain", for: .normal)
        downloadButton.layer.cornerRadius = 10
        downloadButton.tag = 2
        downloadButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(downloadButton)
    }
    
    override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
            downloadButton.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 50),
            downloadButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            downloadButton.heightAnchor.constraint(equalToConstant: 50),
            downloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc override func buttonPressed(_ sender: UIButton) {
        super.buttonPressed(sender)
        
        switch sender.tag {
            case 2:
                do {
                    try downloadChain()
                } catch {
                    print("error", error)
                }
                
                break
            default:
                break
        }
    }
    
    private func downloadChain() throws {
        guard let contractMethod = ContractMethods.blockchainDownloadRequest.data else {
            throw NodeError.generalError("Unable to encode contract parameters")
        }
//        let extraData = TransactionExtraData(contractMethod: contractMethod)
//        transactionService.prepareTransaction(extraData: extraData, to: nil, password: "1") { (data, error) in
//            if let error = error {
//                print(error)
//            }
//            
//            if let data = data {
//                /// add to the queue to be sent
//                NetworkManager.shared.enqueue(data)
//            }
//        }
    }
}
