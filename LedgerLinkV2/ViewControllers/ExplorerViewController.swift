//
//  ExplorerViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-15.
//

import UIKit

enum ExploreSection: Int, CaseIterable {
    case main
}

struct ExploreMenuData: Hashable {
    let section: ExploreSection
    let colors: [CGColor]
    let title: String
    var subtitle: String? = nil
    let image: UIImage
    let identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

class ExplorerViewController: UIViewController {
    
    private var gradientView: GradientView!
    private var blurView: BlurEffectContainerView!
    private var searchController: UISearchController!
    private var dataSource: UICollectionViewDiffableDataSource<ExploreSection, ExploreMenuData>! = nil
    private var collectionView: UICollectionView! = nil
    private var menuDataArray: [ExploreMenuData] = [
        ExploreMenuData(section: .main, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Reset Password", image: UIImage(systemName: "lock.rotation.open")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        ExploreMenuData(section: .main, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Transaction History", image: UIImage(systemName: "book.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        ExploreMenuData(section: .main, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Private Key", image: UIImage(systemName: "lock.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        ExploreMenuData(section: .main, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Delete", image: UIImage(systemName: "trash.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal))
    ]
    
    private var selectedScope: Int = 0
    private let alert = AlertView()
    private var optionsBarItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearchController()
        configureSearchBar()
        configureUI()
        configureHierarchy()
        configureDataSource()
        setConstraints()
        tapToDismissKeyboard()
        configureOptionsBar()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedToDismiss))
        tap.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tap)
        navigationController?.navigationBar.addGestureRecognizer(tap)
    }

    func configureUI() {
        title = "Explore"
        view.backgroundColor = .black
//        edgesForExtendedLayout = [.top]
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        collectionView.contentInset = UIEdgeInsets(top: 50, left: 0, bottom: 0, right: 0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = false
        view.addSubview(collectionView)
    }

    func setConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    func configureSearchController() {
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

    final func configureSearchBar() {
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
        
//        let config = UIImage.SymbolConfiguration.
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
                print("yes")
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
}

extension ExplorerViewController {
    /// - Tag: PerSection
    private func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
                                                            layoutEnvironment: NSCollectionLayoutEnvironment)
            -> NSCollectionLayoutSection? in
            let isWideView = layoutEnvironment.container.effectiveContentSize.width > 500
            return self.generateVerticalLayout(isWide: isWideView)
        }
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        layout.configuration = config
        return layout
    }
    
    private func generateVerticalLayout(isWide: Bool) -> NSCollectionLayoutSection {
        /// Item
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 15,
            leading: 15,
            bottom: 15,
            trailing: 15)
        
        /// Group
        let groupFractionalWidth: CGFloat = isWide ? 1 : 1
//        let groupFractionalHeight: CGFloat = 1
        let groupFractionalHeight: CGFloat = isWide ? 4/5 : 2/4

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(groupFractionalWidth),
//            heightDimension: .fractionalHeight(groupFractionalHeight)
            heightDimension: .absolute(100)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        
        /// Section
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: "Menu",
            alignment: .top)
        
        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [sectionHeader]
        section.orthogonalScrollingBehavior = .continuous
        
        
        return section
    }
}

extension ExplorerViewController {

    func configureHierarchy() {

    }
    
    private func configureDataSource() {
        
        let CardCellRegistration = UICollectionView.CellRegistration<CardCell, MenuData> { (cell, indexPath, menuData) in
            // Populate the cell with our item description.
            cell.titleLabel.text = menuData.title
            cell.colors = menuData.colors
            cell.imageView.image = menuData.image
        }
        
        let textCellRegistration = UICollectionView.CellRegistration<CardCell, ExploreMenuData> { (cell, indexPath, menuData) in
            // Populate the cell with our item description.
            cell.titleLabel.text = menuData.title
            cell.titleLabel.textColor = .white
            cell.colors = menuData.colors
            cell.imageView.image = menuData.image
            cell.contentView.layer.cornerRadius = Section(rawValue: indexPath.section)! == .vertical ? 15 : 5
            cell.radiusTopRight = 40
        }
        
        let BalanceCellRegistration = UICollectionView.CellRegistration<BalanceCell, ExploreMenuData> { (cell, indexPath, menuData) in
            // Populate the cell with our item description.
            cell.titleLabel.text = menuData.title
            cell.colors = menuData.colors
        }
        
        dataSource = UICollectionViewDiffableDataSource<ExploreSection, ExploreMenuData>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: ExploreMenuData) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: textCellRegistration, for: indexPath, item: identifier)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration
        <TextCell>(elementKind: "Menu") {
            (supplementaryView, string, indexPath) in
            supplementaryView.label.text = "Wallet Menu"
            supplementaryView.label.textColor = .darkGray
            supplementaryView.label.font = UIFont.rounded(ofSize: 15, weight: .bold)
        }
        
        dataSource.supplementaryViewProvider = { (view, kind, index) in
            return self.collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration, for: index)
        }
        
        // initial data
        var snapshot = NSDiffableDataSourceSnapshot<ExploreSection, ExploreMenuData>()
        ExploreSection.allCases.forEach { [weak self] section in
            snapshot.appendSections([section])
            guard let filteredMenuDataArray = self?.menuDataArray.filter ({ $0.section == section }) else { return }
            snapshot.appendItems(filteredMenuDataArray)
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
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
    }
}
