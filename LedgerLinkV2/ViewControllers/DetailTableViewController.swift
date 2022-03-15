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
        
        view.backgroundColor = .black
        tableView.backgroundColor = .black
        
        if data is [FullBlock] {
            tableView.register(BlockDetailCell.self, forCellReuseIdentifier: BlockDetailCell.reuseIdentifier)
//            tableView.estimatedRowHeight = 250
            tableView.rowHeight = 250
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
            
        } else if let account = data[indexPath.row] as? TreeConfigurableAccount {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = account.id
            cell.textLabel?.textColor = .white
            return cell
          
        } else if let transaction = data[indexPath.row] as? TreeConfigurableTransaction {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = transaction.id
            cell.textLabel?.textColor = .white
            return cell
              
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "reuse-identifier", for: indexPath)
            cell.textLabel?.text = "Default"
            cell.textLabel?.textColor = .white
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let block = data[indexPath.row] as? FullBlock {
            if let tx = block.transactions, tx.count > 0 {
                let detailVC = DetailTableViewController<TreeConfigurableTransaction>()
                detailVC.data = tx
                self.navigationController?.pushViewController(detailVC, animated: true)
            }
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
        
        numberTextLabel.textColor = .white
        numberTextLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(numberTextLabel)
        
        hashTextLabel.textColor = .white
        hashTextLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(hashTextLabel)
        
        parentHashLabel.textColor = .white
        parentHashLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(parentHashLabel)
        
        transactionHashLabel.textColor = .white
        transactionHashLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(transactionHashLabel)
        
        stateRootLabel.textColor = .white
        stateRootLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stateRootLabel)
        
        sizeLabel.textColor = .white
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sizeLabel)
        
        timestampLabel.textColor = .white
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
