//
//  IndividualDetailViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-16.
//

/*
 Abstract:
 Shows either the Account, EthereumTransaction details, or the Block details.
 Pushed from DetailTableVC
 */

import UIKit
import web3swift

struct SearchResultContent {
    let title: String
    let detail: String?
    var accounts: [TreeConfigurableAccount]? = nil
    var transactions: [TreeConfigurableTransaction]? = nil
}

class IndividualDetailViewController: UITableViewController {
    let alert = AlertView()
    var dataSource: [SearchResultContent] = []
    
    init() {
        super.init(style: .grouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
    
    private func configure() {
        view.backgroundColor = .black
        tableView.backgroundColor = .black
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.selectionStyle = .none
        let data = dataSource[indexPath.section]
        cell.textLabel?.text = data.detail
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .black
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].title
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        headerView.textLabel?.textColor = .lightGray
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = dataSource[indexPath.section]
        switch data.title {
            case "Accounts":
                /// The validated accounts in Block data
                let detailVC = DetailTableViewController<TreeConfigurableAccount>()
                detailVC.title = data.title
                detailVC.data = data.accounts
                self.navigationController?.pushViewController(detailVC, animated: true)
            case "Transactions":
                /// The validated transactions in Block data
                let detailVC = DetailTableViewController<TreeConfigurableTransaction>()
                detailVC.title = data.title
                detailVC.data = data.transactions
                self.navigationController?.pushViewController(detailVC, animated: true)
            case "Recipient Address", "Sender Address", "Validator":
                guard let addressString = data.detail else { return }
                Node.shared.fetch(.addressString(addressString)) { [weak self] (accts: [Account]?, error: NodeError?) in
                    if let error = error {
                        self?.alert.showDetail("Fetch error", with: error.localizedDescription, for: self)
                        return
                    }
                    
                    if let accts = accts, let account = accts.first {
                        let vc = IndividualDetailViewController()
                        
                        let dataSource = [
                            SearchResultContent(title: "Address", detail: account.address.address),
                            SearchResultContent(title: "Nonce", detail: account.nonce.description),
                            SearchResultContent(title: "Balance", detail: account.balance.description),
                            SearchResultContent(title: "Storage Root", detail: account.storageRoot),
                            SearchResultContent(title: "Code Hash", detail: account.codeHash),
                        ]
                        
                        vc.dataSource = dataSource
                        vc.title = "Account"
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            case "Block Number":
                guard let number = data.detail, let blockNumber = Int32(number) else { return }
                
                Node.shared.localStorage.getBlock(blockNumber) { [weak self] (block: FullBlock?, error: NodeError?) in
                    if let error = error {
                        self?.alert.showDetail("Fetch error", with: error.localizedDescription, for: self)
                        return
                    }
                    
                    if let block = block {
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
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            case "Transaction History":
                /// Transaction history is only under Account so the "Address" category should exist
                /// Fetch all transactions and filter them by either a matching "sender" or "to" because they represent any transactions related to the Account.
                Node.shared.fetch { [weak self] (transactions: [EthereumTransaction]?, error: NodeError?) in
                    if let error = error {
                        self?.alert.showDetail("Fetch error", with: error.localizedDescription, for: self)
                        return
                    }
                    
                    /// addressData is the address of the Account in question
                    if let transactions = transactions,
                       let addressData = self?.dataSource.filter ({ $0.title == "Address" }).first {
                        let matchingTransactions = transactions.filter {
                            guard let sender = $0.sender else { return false }
                            return sender.address == addressData.detail || $0.to.address == addressData.detail
                        }
                        
                        /// Encode the full transaction back to TreeConfig form because DetailTableVC requires it.
                        /// TODO: Improve the time complexity
                        let treeConfigArr = matchingTransactions.compactMap { try? TreeConfigurableTransaction(data: $0) }
                        
                        DispatchQueue.main.async {
                            let detailVC = DetailTableViewController<TreeConfigurableTransaction>()
                            detailVC.title = "Transactions"
                            detailVC.data = treeConfigArr
                            self?.navigationController?.pushViewController(detailVC, animated: true)
                        }
                    }
                }
            default:
                break
        }
    }
}
