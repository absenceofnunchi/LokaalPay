//
//  ExplorerViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-15.
//

import UIKit

enum ExploreSection: Int, CaseIterable {
    case recentTransactions
    case recentBlocks
    
    var asString: String {
        switch self {
            case .recentTransactions:
                return "Recent Transactions"
            case .recentBlocks:
                return "Recent Blocks"
        }
    }
}

struct ExploreMenuData: Hashable {
    let uuid = UUID().uuidString
    let section: ExploreSection
    let colors: [CGColor]
    let title: String
    var subtitle: String? = nil
    let image: UIImage
    let identifier = UUID()
    var extraData: Data? = nil
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

final class ExplorerViewController: UIViewController {
    private var gradientView: GradientView!
    private var blurView: BlurEffectContainerView!
    private var searchController: UISearchController!
    private var dataSource: UICollectionViewDiffableDataSource<ExploreSection, ExploreMenuData>! = nil
    private var collectionView: UICollectionView! = nil
    private var menuDataArray = [ExploreMenuData]()
    private var selectedScope: Int = 0
    private let alert = AlertView()
    private var optionsBarItem: UIBarButtonItem!
    static let sectionHeaderElementKind = "section-header-element-kind"
    private var refresher:UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearchController()
        configureSearchBar()
        configureUI()
        configureDataSource()
        setConstraints()
        tapToDismissKeyboard()
        configureOptionsBar()
        configureRefreshData()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedToDismiss))
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
        navigationController?.navigationBar.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureInitialData()
    }
    
    private func configureUI() {
        title = "Explore"
        view.backgroundColor = .black
//        edgesForExtendedLayout = [.top]
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
//        collectionView.translatesAutoresizingMaskIntoConstraints = false0
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        view.addSubview(collectionView)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
//            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
//            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsCancelButton = true

        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureSearchBar() {
        /// search bar attributes
        guard let searchController = searchController else { return }
        let searchBar = searchController.searchBar
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .lightGray
        searchBar.searchBarStyle = .default
        searchBar.showsScopeBar = true
        searchBar.sizeToFit()
        searchBar.setShowsCancelButton(true, animated: true)
        searchBar.scopeButtonTitles = ["Account", "Transaction"]

        /// search text field attributes
        let searchTextField = searchBar.searchTextField
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.cornerRadius = 8
        searchTextField.textColor = .black
        searchTextField.backgroundColor = .darkGray
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter Account or Transaction Hash", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
        
        guard let cameraImage = UIImage(systemName: "camera") else { return }
        cameraImage.withTintColor(.gray, renderingMode: .alwaysOriginal)
        let button = UIButton.systemButton(with: cameraImage, target: self, action: #selector(buttonPressed(_:)))
        button.tag = 1
        
        searchTextField.leftView = button
        searchTextField.leftViewMode = .always
        
        // Selected text
        let titleTextAttributesSelected = [NSAttributedString.Key.foregroundColor: UIColor.gray]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributesSelected, for: .selected)

        // Normal text
        let titleTextAttributesNormal = [NSAttributedString.Key.foregroundColor: UIColor.gray]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributesNormal, for: .normal)
        UISegmentedControl.appearance().tintColor = .gray
        UISegmentedControl.appearance().backgroundColor = UIColor.darkGray
        UISegmentedControl.appearance().selectedSegmentTintColor = .black
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                collectionView.refreshControl?.beginRefreshing()
                configureInitialData()
            case 1:
                searchController.searchBar.endEditing(true)
                let scannerVC = ScannerViewController()
                scannerVC.delegate = self
                self.present(scannerVC, animated: true, completion: nil)
            default:
                break
        }
    }
    
    @objc override func tappedToDismiss() {
        super.tappedToDismiss()
        searchController.searchBar.endEditing(true)
        view.endEditing(true)
        searchController.isActive = false
    }
}

extension ExplorerViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate, ScannerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        print("search")
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.selectedScope = selectedScope
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

        /// If the user tapped on the search bar for the first time, inform them of the camera option to scan the QR code of transactions or accounts for searching
        let hasSeenBefore = UserDefaults.standard.bool(forKey: UserDefaultKey.hasSeenExplorer)
        if !hasSeenBefore {
            /// Prevent the keyboard from appearing to make way for the modal
            searchBar.endEditing(true)
            
            showFirstTimeWarning {
                /// Set the user defaults to true
                UserDefaults.standard.set(true, forKey: UserDefaultKey.hasSeenExplorer)
                /// Bring up the virtual keyboard since the user tapped on the text field
                searchBar.becomeFirstResponder()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.searchTextField.text,
              !text.isEmpty else { return }
        
        fetch(selectedScope: selectedScope, id: text)
    }
    
    private func configureOptionsBar() {
        let image = UIImage(systemName: "line.horizontal.3.decrease")?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        let barButtonMenu = UIMenu(title: "", children: [
            UIAction(title: NSLocalizedString("All Accounts", comment: ""), image: UIImage(systemName: "person"), handler: menuHandler),
            UIAction(title: NSLocalizedString("All Transactions", comment: ""), image: UIImage(systemName: "doc.plaintext"), handler: menuHandler),
            UIAction(title: NSLocalizedString("All Blocks", comment: ""), image: UIImage(systemName: "square.3.stack.3d"), handler: menuHandler),
        ])
        optionsBarItem = UIBarButtonItem(title: nil, image: image, primaryAction: nil, menu: barButtonMenu)
        navigationItem.rightBarButtonItem = optionsBarItem
    }
    
    @objc private func menuHandler(action: UIAction) {
        switch action.title {
            case "All Accounts":
                fetchAccounts(id: nil)
            case "All Transactions":
                fetchTransactions(id: nil)
            case "All Blocks":
                fetchBlocks()
            default:
                break
        }
    }
    
    private func fetch(selectedScope: Int, id: String) {
        switch selectedScope {
            case 0:
                fetchAccounts(id: id)
            case 1:
                fetchTransactions(id: id)
            default:
                break
        }
    }
    
    /// Load the initial data and parse them into blocks and transactions to be displayed
    private func configureInitialData(fetchLimit: Int = 20) {
        Node.shared.localStorage.getLatestBlocks(fetchLimit: fetchLimit) { [weak self] (blocks: [FullBlock]?, error: NodeError?) in
            if let error = error {
                self?.alert.showDetail("Fetch Error", with: error.localizedDescription, for: self)
                return
            }
            
            /// The final data format including both blocks and transactions according to their respective sections
            var array = [ExploreMenuData]()
            
            /// Collection of transactions to be added individually to the above array
            /// Include the "ExtraData" from the block so that it can be displayed on collection view since the information like timestamp, block number, etc are not included in EthereumTransaction by default.
            var transactionIdArray: [String] = []
            
            guard let blocks = blocks else {
                return
            }
            
            /// Instantiate individual blocks as ExploreMenuData
            /// Collect the transactions belonging to those individual blocks and instantiate them as ExploreMenuData as well
            for block in blocks {
                let recentBlock = ExploreMenuData(section: .recentBlocks, colors: [UIColor.yellow.cgColor], title: block.hash.toHexString(), image: UIImage(systemName: "lock.rotation.open")!.withTintColor(.white, renderingMode: .alwaysOriginal))
                array.append(recentBlock)
                
                /// Add the transaction IDs and the according extra data belonging to a specific block to the dicationary
                guard let transactions = block.transactions else { continue }
                transactions.forEach { transactionIdArray.append($0.id) }
            }
            
            for id in transactionIdArray {
                let recentTx = ExploreMenuData(section: .recentTransactions, colors: [UIColor.yellow.cgColor], title: id, image: UIImage())
                array.append(recentTx)
            }
            
            DispatchQueue.main.async {
                var snapshot = NSDiffableDataSourceSnapshot<ExploreSection, ExploreMenuData>()
                ExploreSection.allCases.forEach { section in
                    snapshot.appendSections([section])
                    let items = array.filter { $0.section == section }
                    snapshot.appendItems(items)
                }
                
                self?.dataSource.applySnapshotUsingReloadData(snapshot)
                self?.collectionView.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func fetchAccounts(id: String?) {
        Node.shared.fetch(id != nil ? .treeConfigAccountId(id!): nil) { [weak self] (results: [TreeConfigurableAccount]?, error: NodeError?) in
            if let error = error {
                self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
            }
            
            if let results = results {
                DispatchQueue.main.async {
                    let detailVC = DetailTableViewController<TreeConfigurableAccount>()
                    detailVC.title = "Accounts"
                    detailVC.data = results
                    self?.navigationController?.pushViewController(detailVC, animated: true)
                }
            } else {
                self?.alert.showDetail("No Data", with: "There doesn't seem to be a matching account", for: self)
            }
        }
    }
    
    private func fetchTransactions(id: String?) {
        Node.shared.fetch(id != nil ? .treeConfigTxId(id!): nil) { [weak self] (results: [TreeConfigurableTransaction]?, error: NodeError?) in
            if let error = error {
                self?.alert.showDetail("Error", with: error.localizedDescription, for: self)
            }
            
            if let results = results {
                DispatchQueue.main.async {
                    let detailVC = DetailTableViewController<TreeConfigurableTransaction>()
                    detailVC.title = "Transactions"
                    detailVC.data = results
                    self?.navigationController?.pushViewController(detailVC, animated: true)
                }
            } else {
                self?.alert.showDetail("No Data", with: "There doesn't seem to be a matching transaction", for: self)
            }
        }
    }
    
    private func fetchBlocks() {
        Node.shared.fetch { [weak self](blocks: [FullBlock]?, error: NodeError?) in
            if let error = error {
                print(error)
            }
            
            if let blocks = blocks {
                DispatchQueue.main.async {
                    let detailVC = DetailTableViewController<FullBlock>()
                    detailVC.title = "Blocks"
                    detailVC.data = blocks
                    self?.navigationController?.pushViewController(detailVC, animated: true)
                }
            } else {
                self?.alert.show("No data", for: self)
            }
        }
    }
    
    /// Fetches the results of the QR scan and shows the results in DetailVC
    func scannerDidOutput(code: String) {
        searchController.searchBar.searchTextField.text = code
        
        fetch(selectedScope: selectedScope, id: code)
    }
    
    /// Shows the info for the first time user.
    private func showFirstTimeWarning(completion: @escaping () -> Void) {
        let content = [
            StandardAlertContent(
                titleString: "",
                body: ["": "You can press the camera icon to scan QR codes"],
                isEditable: false,
                messageTextAlignment: .left,
                alertStyle: .oneButton,
                borderColor: UIColor.clear.cgColor
            ),
        ]
        
        let alertVC = AlertViewController(height: 350, standardAlertContent: content)
        alertVC.action = { (modal: AlertViewController, mainVC: StandardAlertViewController) in
            mainVC.buttonAction = { _ in
                
                modal.dismiss(animated: true, completion: {
                    completion()
                })
            }
        }
        
        self.present(alertVC, animated: true)
    }
    
    private func configureRefreshData() {
        refresher = UIRefreshControl()
        refresher.tintColor = UIColor.gray
        refresher.addTarget(self, action: #selector(buttonPressed), for: .valueChanged)
        refresher.tag = 0
        collectionView.refreshControl = refresher
    }
}

extension ExplorerViewController {
    func generateLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0
        
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .estimated(50))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: ExplorerViewController.sectionHeaderElementKind, alignment: .top)
        
        section.boundarySupplementaryItems = [sectionHeader]
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 30
        layout.configuration = config
        return layout
    }
}

extension ExplorerViewController {
    private func configureDataSource() {
        
        let simpleCellRegistration = UICollectionView.CellRegistration<SimpleCell, ExploreMenuData> { (cell, indexPath, menuData) in
            // Populate the cell with our item description.
            cell.titleLabel.text = menuData.title
            cell.layer.cornerRadius = 10
            cell.layer.borderWidth = 0.5
//            cell.layer.borderColor = UIColor.gray.cgColor
            cell.titleLabel.textColor = .lightGray
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration
        <TitleSupplementaryView>(elementKind: ExplorerViewController.sectionHeaderElementKind) {
            [weak self] (supplementaryView, string, indexPath) in
            guard let section = ExploreSection(rawValue: indexPath.section) else { return }
            supplementaryView.label.attributedText = self?.createAttributedString(imageString: "list.bullet.rectangle", imageColor: .white, text: "  \(section.asString)")
            supplementaryView.label.textColor = UIColor.white
        }

        dataSource = UICollectionViewDiffableDataSource<ExploreSection, ExploreMenuData>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: ExploreMenuData) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: simpleCellRegistration, for: indexPath, item: identifier)
        }
        
        dataSource.supplementaryViewProvider = { (view, kind, index) in
            return self.collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration, for: index)
        }
        
        // initial data
//        var snapshot = NSDiffableDataSourceSnapshot<ExploreSection, ExploreMenuData>()
//        ExploreSection.allCases.forEach { [weak self] section in
//            snapshot.appendSections([section])
//            guard let filteredMenuDataArray = self?.menuDataArray.filter ({ $0.section == section }) else { return }
//            snapshot.appendItems(filteredMenuDataArray)
//        }
//
//        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension ExplorerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        guard let selectedItem = dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        /// If the recent transaction section is tapped, parse a transaction and push to IndividalDetailVC
        /// If the recent block section is tapped, parse a block and push to IndividualDetailVC
        if selectedItem.section == .recentTransactions {
            Node.shared.fetch(.treeConfigTxId(selectedItem.title)) { [weak self] (treeConfigTxs: [TreeConfigurableTransaction]?, error: NodeError?) in
                if let error = error {
                    self?.alert.showDetail("Fetch Error", with: error.localizedDescription, for: self)
                    return
                }
                
                guard let treeConfigTxs = treeConfigTxs,
                      let treeConfigTx = treeConfigTxs.first,
                      let transaction = treeConfigTx.decode() else {
                    return
                }
                
                DispatchQueue.main.async {
                    let vc = IndividualDetailViewController()
                    
                    var dataSource = [
                        SearchResultContent(title: "Recipient Address", detail: transaction.to.address),
                        SearchResultContent(title: "Nonce", detail: transaction.nonce.description),
                        SearchResultContent(title: "Amount", detail: transaction.value != nil ? transaction.value?.description : "0"),
                    ]

                    let data = try? JSONDecoder().decode(TransactionExtraData.self, from: transaction.data)
                    
                    if let data = data {
                        dataSource.append(contentsOf: [
                            SearchResultContent(title: "Sender Address", detail: data.account  != nil ? data.account!.address.address : nil),
                            SearchResultContent(title: "Block Number", detail: (data.latestBlockNumber + 1).description),
                            SearchResultContent(title: "Created At", detail: data.timestamp.description),
                        ])
                    }
                    
                    vc.dataSource = dataSource
                    vc.title = "Transaction"
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        } else if selectedItem.section == .recentBlocks {
            Node.shared.fetch(.lightBlockId(selectedItem.title)) { [weak self](lightBlocks: [LightBlock]?, error: NodeError?) in
                if let error = error {
                    self?.alert.showDetail("Fetch Error", with: error.localizedDescription, for: self)
                    return
                }
            
                guard let lightBlocks = lightBlocks,
                      let lightBlock = lightBlocks.first,
                      let block = lightBlock.decode() else {
                    return
                }
                
                DispatchQueue.main.async {
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
        }
    }
}

final class SimpleCell: UICollectionViewCell {
    let titleLabel = UILabel()
    let lineView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension SimpleCell {
    func configure() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.rounded(ofSize: 13, weight: .bold)
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)
        
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.layer.borderColor = UIColor.darkGray.cgColor
        lineView.layer.borderWidth = 0.5
        contentView.addSubview(lineView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            titleLabel.heightAnchor.constraint(equalToConstant: 40),
            
            lineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            lineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            lineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
            lineView.heightAnchor.constraint(equalToConstant: 1),
        ])
    }
}
