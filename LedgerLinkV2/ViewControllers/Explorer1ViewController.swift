//
//  ExplorerViewController1.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-23.
//

import UIKit

class ExplorerViewController1: UIViewController {
    private var blockButton: UIButton!
    private var historyButton: UIButton!
    private var textField: UITextField!
    private var accountSearchButton: UIButton!
    private var txSearchButton: UIButton!
    private let alert = AlertView()
    private var tag: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        setConstraints()
    }
    
    func configure() {
        view.backgroundColor = .white
        
        textField = UITextField()
        textField.placeholder = "Account or transaction..."
        textField.textColor = .orange
        textField.layer.borderColor = UIColor.black.cgColor
        textField.layer.borderWidth = 1
        textField.textAlignment = .left
        textField.layer.cornerRadius = 10
        textField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)
        
        accountSearchButton = UIButton()
        accountSearchButton.setTitle("Search Account", for: .normal)
        accountSearchButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        accountSearchButton.tag = 0
        accountSearchButton.backgroundColor = .blue
        accountSearchButton.layer.cornerRadius = 10
        accountSearchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(accountSearchButton)
        
        txSearchButton = UIButton()
        txSearchButton.setTitle("Search Transaction", for: .normal)
        txSearchButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        txSearchButton.tag = 1
        txSearchButton.backgroundColor = .blue
        txSearchButton.layer.cornerRadius = 10
        txSearchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(txSearchButton)
        
        historyButton = UIButton()
        historyButton.setTitle("History", for: .normal)
        historyButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        historyButton.tag = 2
        historyButton.backgroundColor = .black
        historyButton.layer.cornerRadius = 10
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(historyButton)
        
        blockButton = UIButton()
        blockButton.setTitle("Blocks", for: .normal)
        blockButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        blockButton.tag = 3
        blockButton.backgroundColor = .black
        blockButton.layer.cornerRadius = 10
        blockButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blockButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            textField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            textField.heightAnchor.constraint(equalToConstant: 50),
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            accountSearchButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            accountSearchButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            accountSearchButton.heightAnchor.constraint(equalToConstant: 50),
            accountSearchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            txSearchButton.topAnchor.constraint(equalTo: accountSearchButton.bottomAnchor, constant: 20),
            txSearchButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            txSearchButton.heightAnchor.constraint(equalToConstant: 50),
            txSearchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            historyButton.topAnchor.constraint(equalTo: txSearchButton.bottomAnchor, constant: 20),
            historyButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            historyButton.heightAnchor.constraint(equalToConstant: 50),
            historyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            blockButton.topAnchor.constraint(equalTo: historyButton.bottomAnchor, constant: 20),
            blockButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            blockButton.heightAnchor.constraint(equalToConstant: 50),
            blockButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        tag = sender.tag
        
        switch sender.tag {
            case 0:
                scan()
                break
            case 1:
                break
            case 2:
                Node.shared.fetch { [weak self](results: [TreeConfigurableTransaction]?, error: NodeError?) in
                    if let error = error {
                        print(error)
                    }
                    
                    if let results = results {
                        DispatchQueue.main.async {
                            let detailVC = DetailTableViewController<TreeConfigurableTransaction>()
                            detailVC.data = results
                            self?.navigationController?.pushViewController(detailVC, animated: true)
                        }
                    } else {
                        self?.alert.show("No data", for: self)
                    }
                }
                break
            case 3:
//                Node.shared.fetch { [weak self](blocks: [FullBlock]?, error: NodeError?) in
//                    if let error = error {
//                        print(error)
//                    }
//                        
//                    if let blocks = blocks {
//                        DispatchQueue.main.async {
//                            let detailVC = DetailTableViewController<FullBlock>()
//                            detailVC.data = blocks
//                            self?.navigationController?.pushViewController(detailVC, animated: true)
//                        }
//                    } else {
//                        self?.alert.show("No data", for: self)
//                    }
//                }
                break
            default:
                break
        }
    }
}

extension ExplorerViewController1: ScannerDelegate {
    private func scan() {
        let scannerVC = ScannerViewController()
        scannerVC.delegate = self
        self.present(scannerVC, animated: true, completion: nil)
    }
    
    // MARK: - scannerDidOutput
    func scannerDidOutput(code: String) {
        let text = code
        textField.text = text
        
        switch tag {
            case 0:
                Node.shared.fetch(.addressString(text)) { [weak self](results: [TreeConfigurableAccount]?, error: NodeError?) in
                    if let error = error {
                        print(error)
                    }
                    
                    if let results = results {
                        DispatchQueue.main.async {
                            let detailVC = DetailTableViewController<TreeConfigurableAccount>()
                            detailVC.data = results
                            self?.navigationController?.pushViewController(detailVC, animated: true)
                        }
                    } else {
                        self?.alert.show("No data", for: self)
                    }
                }
            default:
                break
        }

    }
}
