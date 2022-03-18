//
//  DetailTableViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-23.
//

import UIKit

class DetailTableViewController<T>: UITableViewController {
    var data: [T]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func configure() {
        view.backgroundColor = .black
        tableView.backgroundColor = .black
        tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)

        if data is [FullBlock] {
            tableView.register(BlockDetailCell.self, forCellReuseIdentifier: BlockDetailCell.reuseIdentifier)
            tableView.rowHeight = 280
        } else {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuse-identifier")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let block = data[indexPath.row] as? FullBlock {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: BlockDetailCell.reuseIdentifier, for: indexPath) as? BlockDetailCell else {
                fatalError()
            }
            cell.set(block: block)
            cell.selectionStyle = .none
            return cell
        } else if let lightBlock = data[indexPath.row] as? LightBlock {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = "Block Number: \(lightBlock.number.description)"
            cell.textLabel?.textColor = .white
            cell.backgroundColor = .black
            cell.selectionStyle = .none
            return cell
            
        } else if let account = data[indexPath.row] as? TreeConfigurableAccount {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = account.id
            cell.textLabel?.textColor = .white
            cell.backgroundColor = .black
            cell.selectionStyle = .none
            return cell
          
        } else if let transaction = data[indexPath.row] as? TreeConfigurableTransaction {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = transaction.id
            cell.textLabel?.textColor = .white
            cell.backgroundColor = .black
            cell.selectionStyle = .none
            return cell
              
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = "Default"
            cell.textLabel?.textColor = .white
            cell.selectionStyle = .none
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let block = data[indexPath.row] as? FullBlock {
            let vc = IndividualDetailViewController()
            
            let dataSource = [
                SearchResultContent(title: "Block Number", detail: block.number.description),
                SearchResultContent(title: "Block Hash", detail: block.hash.toHexString()),
                SearchResultContent(title: "Parent Hash", detail: block.parentHash == Data() ? "N/A" : block.parentHash.toHexString()),
                SearchResultContent(title: "Transaction Root", detail: block.transactionsRoot.toHexString()),
                SearchResultContent(title: "State Root", detail: block.stateRoot.toHexString()),
                SearchResultContent(title: "Validator", detail: block.miner),
                SearchResultContent(title: "Created At", detail: block.timestamp.description),
                SearchResultContent(title: "Transactions", detail: "Show More Detail", transactions: block.transactions),
                SearchResultContent(title: "Accounts", detail: "Show More Detail", accounts: block.accounts),
            ]
            
            vc.dataSource = dataSource
            vc.title = "Block"
            self.navigationController?.pushViewController(vc, animated: true)
        } else if let treeConfigAcct = data[indexPath.row] as? TreeConfigurableAccount, let account = treeConfigAcct.decode() {
            let vc = IndividualDetailViewController()
            
            let dataSource = [
                SearchResultContent(title: "Address", detail: account.address.address),
                SearchResultContent(title: "Nonce", detail: account.nonce.description),
                SearchResultContent(title: "Balance", detail: account.balance.description),
                SearchResultContent(title: "Storage Root", detail: account.storageRoot),
                SearchResultContent(title: "Code Hash", detail: account.codeHash),
                SearchResultContent(title: "Transaction History", detail: "Show More Detail"),
            ]
            
            vc.dataSource = dataSource
            vc.title = "Account"
            self.navigationController?.pushViewController(vc, animated: true)
        } else if let treeConfigTx = data[indexPath.row] as? TreeConfigurableTransaction,
                  let tx = treeConfigTx.decode() {
            
            let extraData = try? JSONDecoder().decode(TransactionExtraData.self, from: tx.data)
            let vc = IndividualDetailViewController()
            
            var dataSource = [
                SearchResultContent(title: "Recipient Address", detail: tx.to.address),
                SearchResultContent(title: "Nonce", detail: tx.nonce.description),
                SearchResultContent(title: "Amount", detail: tx.value != nil ? tx.value?.description : "0"),
            ]
            
            if let extraData = extraData {
                dataSource.append(contentsOf: [
                    SearchResultContent(title: "Sender Address", detail: extraData.account  != nil ? extraData.account!.address.address : nil),
                    SearchResultContent(title: "Block Number", detail: (extraData.latestBlockNumber + 1).description),
                    SearchResultContent(title: "Created At", detail: extraData.timestamp.description),
                ])
            }
            
            vc.dataSource = dataSource
            vc.title = "Transaction"
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

class BlockDetailCell: UITableViewCell {
    static let reuseIdentifier = "block-cell-reuse-identifier"
    var numberTextLabel = UILabel()
    var hashTextLabel = UILabel()
    var parentHashLabel = UILabel()
    var transactionHashLabel = UILabel()
    var stateRootLabel = UILabel()
    var sizeLabel = UILabel()
    var timestampLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }
    
    func set(block: FullBlock) {
        numberTextLabel.text = "Block Number: \(String(block.number))"
        hashTextLabel.text = "Block Hash: \(block.hash.toHexString())"
        parentHashLabel.text = "Parent Hash: \(block.parentHash.toHexString())"
        transactionHashLabel.text = "Transaction Hash: \(block.transactionsRoot.toHexString())"
        stateRootLabel.text = "State Root: \(block.stateRoot.toHexString())"
        sizeLabel.text = "Size: \(String(block.size))"
        timestampLabel.text = "Created At: \(block.timestamp.description)"
    }
    
    func configure() {
        self.backgroundColor = .black
        contentView.layer.cornerRadius = 10
        contentView.layer.borderColor = UIColor.lightGray.cgColor
        contentView.layer.borderWidth = 0.5
        
        numberTextLabel.textColor = .lightGray
        numberTextLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(numberTextLabel)
        
        hashTextLabel.textColor = .lightGray
        hashTextLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hashTextLabel)
        
        parentHashLabel.textColor = .lightGray
        parentHashLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(parentHashLabel)
        
        transactionHashLabel.textColor = .lightGray
        transactionHashLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(transactionHashLabel)
        
        stateRootLabel.textColor = .lightGray
        stateRootLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stateRootLabel)
        
        sizeLabel.textColor = .lightGray
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sizeLabel)
        
        timestampLabel.textColor = .lightGray
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timestampLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            numberTextLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            numberTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            numberTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            numberTextLabel.heightAnchor.constraint(equalToConstant: 30),
            
            hashTextLabel.topAnchor.constraint(equalTo: numberTextLabel.bottomAnchor, constant: 5),
            hashTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            hashTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hashTextLabel.heightAnchor.constraint(equalToConstant: 30),
            
            parentHashLabel.topAnchor.constraint(equalTo: hashTextLabel.bottomAnchor, constant: 5),
            parentHashLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            parentHashLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            parentHashLabel.heightAnchor.constraint(equalToConstant: 30),
            
            transactionHashLabel.topAnchor.constraint(equalTo: parentHashLabel.bottomAnchor, constant: 5),
            transactionHashLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            transactionHashLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            transactionHashLabel.heightAnchor.constraint(equalToConstant: 30),
            
            stateRootLabel.topAnchor.constraint(equalTo: transactionHashLabel.bottomAnchor, constant: 5),
            stateRootLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stateRootLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stateRootLabel.heightAnchor.constraint(equalToConstant: 30),
            
            sizeLabel.topAnchor.constraint(equalTo: stateRootLabel.bottomAnchor, constant: 5),
            sizeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sizeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sizeLabel.heightAnchor.constraint(equalToConstant: 30),
            
            timestampLabel.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 5),
            timestampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            timestampLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            timestampLabel.heightAnchor.constraint(equalToConstant: 30),
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        numberTextLabel.text = nil
        hashTextLabel.text = nil
        parentHashLabel.text = nil
        transactionHashLabel.text = nil
        stateRootLabel.text = nil
        sizeLabel.text = nil
        timestampLabel.text = nil
    }
}
