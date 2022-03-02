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
        
        if data is [FullBlock] {
            tableView.register(BlockDetailCell.self, forCellReuseIdentifier: BlockDetailCell.reuseIdentifier)
            tableView.estimatedRowHeight = 200
            tableView.rowHeight = 200
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
            return cell
            
        } else if let transaction = data[indexPath.row] as? TreeConfigurableTransaction {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = transaction.id
            return cell
          
        } else if let transaction = data[indexPath.row] as? TreeConfigurableTransaction {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = transaction.id
            return cell
              
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = "Default"
            return cell
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let block = data[indexPath.row] as? FullBlock {
            let detailVC = DetailTableViewController<TreeConfigurableTransaction>()
            detailVC.data = block.transactions
            self.navigationController?.pushViewController(detailVC, animated: true)
        } else if let block = data[indexPath.row] as? FullBlock {
            let detailVC = DetailTableViewController<TreeConfigurableAccount>()
            detailVC.data = block.accounts
            self.navigationController?.pushViewController(detailVC, animated: true)
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
    
    func set(block: FullBlock) {
        numberTextLabel.text = String(block.number)
        hashTextLabel.text = block.hash.toHexString()
        parentHashLabel.text = block.parentHash.toHexString()
        transactionHashLabel.text = block.transactionsRoot.toHexString()
        stateRootLabel.text = block.stateRoot.toHexString()
        sizeLabel.text = String(block.size)
        timestampLabel.text = block.timestamp.description
    }
    
    func configure() {
        numberTextLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(numberTextLabel)
        
        hashTextLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hashTextLabel)
        
        parentHashLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(parentHashLabel)
        
        transactionHashLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(transactionHashLabel)
        
        stateRootLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stateRootLabel)
        
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sizeLabel)
        
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timestampLabel)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            numberTextLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            numberTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            numberTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            numberTextLabel.heightAnchor.constraint(equalToConstant: 50),
            
            hashTextLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 10),
            hashTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hashTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hashTextLabel.heightAnchor.constraint(equalToConstant: 50),
            
            parentHashLabel.topAnchor.constraint(equalTo: hashTextLabel.bottomAnchor, constant: 10),
            parentHashLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            parentHashLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            parentHashLabel.heightAnchor.constraint(equalToConstant: 50),
            
            transactionHashLabel.topAnchor.constraint(equalTo: parentHashLabel.bottomAnchor, constant: 10),
            transactionHashLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            transactionHashLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            transactionHashLabel.heightAnchor.constraint(equalToConstant: 50),
            
            stateRootLabel.topAnchor.constraint(equalTo: transactionHashLabel.bottomAnchor, constant: 10),
            stateRootLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stateRootLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stateRootLabel.heightAnchor.constraint(equalToConstant: 50),
            
            sizeLabel.topAnchor.constraint(equalTo: stateRootLabel.bottomAnchor, constant: 10),
            sizeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sizeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sizeLabel.heightAnchor.constraint(equalToConstant: 50),
            
            timestampLabel.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 10),
            timestampLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            timestampLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}
