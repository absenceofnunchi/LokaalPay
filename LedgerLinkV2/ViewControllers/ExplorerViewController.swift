//
//  ExplorerViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-15.
//

import UIKit

class ExplorerViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var gradientView: GradientView!
    private var blurView: BlurEffectContainerView!
    private var searchController: UISearchController!
    private var dataSource: UICollectionViewDiffableDataSource<Section, MenuData>! = nil
    private var collectionView: UICollectionView! = nil
    private var menuDataArray: [MenuData] = [
        MenuData(section: .vertical, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Reset Password", image: UIImage(systemName: "lock.rotation.open")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        MenuData(section: .vertical, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Transaction History", image: UIImage(systemName: "book.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        MenuData(section: .vertical, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Private Key", image: UIImage(systemName: "lock.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        MenuData(section: .vertical, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Delete", image: UIImage(systemName: "trash.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTransparentBackgroundToTheNavigationBar(opacity: 0, titleTextColor: .gray)
        configureSearchController()
        configureSearchBar()
        configureUI()
        configureHierarchy()
        configureDataSource()
        setConstraints()
    }

    func configureUI() {
        title = "Explore"
        view.backgroundColor = .black
        navigationController?.navigationBar.backgroundColor = .clear
        
        scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)
        scrollView.setFill()
        
        gradientView = GradientView(colors: [UIColor.white.cgColor, UIColor(red: 255/255, green: 229/255, blue: 204/255, alpha: 1).cgColor, UIColor.red.cgColor])
        gradientView.alpha = 5
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gradientView)
        
        blurView = BlurEffectContainerView(blurStyle: .light)
        gradientView.addSubview(blurView)
        blurView.setFill()
    }

    func setConstraints() {
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),
            
            collectionView.topAnchor.constraint(equalTo: gradientView.bottomAnchor),
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
        
        guard let searchBar = searchController?.searchBar else { return }
        searchBar.sizeToFit()
        //        searchBar.placeholder = "Search for places"
        
        definesPresentationContext = true
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    final func configureSearchBar() {
        // search bar attributes
        guard let searchController = searchController else { return }
        let searchBar = searchController.searchBar
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.tintColor = .black
        searchBar.searchBarStyle = .minimal
        searchBar.scopeButtonTitles = ["Account", "Transaction"]
        
        // search text field attributes
        let searchTextField = searchBar.searchTextField
        searchTextField.borderStyle = .roundedRect
        searchTextField.layer.cornerRadius = 8
        searchTextField.textColor = .gray
        searchTextField.backgroundColor = .clear
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Enter Account or Transaction Hash", attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
        
        // Selected text
        let titleTextAttributesSelected = [NSAttributedString.Key.foregroundColor: UIColor.gray]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributesSelected, for: .selected)
        
        // Normal text
        let titleTextAttributesNormal = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributesNormal, for: .normal)
        UISegmentedControl.appearance().tintColor = .gray
        UISegmentedControl.appearance().backgroundColor = UIColor.clear
        UISegmentedControl.appearance().selectedSegmentTintColor = .black

    }
}

extension ExplorerViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        print("search")
    }
}


extension ExplorerViewController {
    /// - Tag: PerSection
    private func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
                                                            layoutEnvironment: NSCollectionLayoutEnvironment)
            -> NSCollectionLayoutSection? in
            let isWideView = layoutEnvironment.container.effectiveContentSize.width > 500
            
            let sectionLayoutKind = Section.allCases[sectionIndex]
            switch (sectionLayoutKind) {
                case .horizontal: return self.generateHorizontalLayout(
                    isWide: isWideView)
                case .vertical: return self.generateVerticalLayout(isWide: isWideView)
            }
        }
        return layout
    }
    
    private func generateHorizontalLayout(isWide: Bool) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 50,
            leading: 10,
            bottom: 50,
            trailing: 5)
        
        let groupFractionalWidth: CGFloat = isWide ? 0.425 : 0.6
        let groupFractionalHeight: CGFloat = isWide ? 1/5 : 1/4
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(groupFractionalWidth),
            heightDimension: .fractionalHeight(groupFractionalHeight)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 30
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.visibleItemsInvalidationHandler = { items, offset, environment in
            let visibleFrame = CGRect(origin: offset, size: environment.container.contentSize)
            let cells = items.filter { $0.representedElementCategory == .cell }
            for item in cells {
                let distanceFromCenter = abs(visibleFrame.midX - item.center.x)
                let scaleZone = CGFloat(70)
                let scaleFactor = distanceFromCenter / scaleZone
                if distanceFromCenter < scaleZone {
                    let scale = 1 + 0.5 * (1 - abs(scaleFactor))
                    let transform = CGAffineTransform(scaleX: scale, y: scale)
                    item.transform = transform
                }
            }
        }
        
        return section
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
        let groupFractionalWidth: CGFloat = 0.5
        let groupFractionalHeight: CGFloat = isWide ? 4/5 : 2/4
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(groupFractionalWidth),
            heightDimension: .fractionalHeight(groupFractionalHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 2)
        
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
        section.orthogonalScrollingBehavior = .groupPaging
        
        return section
    }
}

extension ExplorerViewController {

    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    private func configureDataSource() {
        
        let CardCellRegistration = UICollectionView.CellRegistration<CardCell, MenuData> { (cell, indexPath, menuData) in
            // Populate the cell with our item description.
            cell.titleLabel.text = menuData.title
            cell.colors = menuData.colors
            cell.imageView.image = menuData.image
        }
        
        let textCellRegistration = UICollectionView.CellRegistration<CardCell, MenuData> { (cell, indexPath, menuData) in
            // Populate the cell with our item description.
            cell.titleLabel.text = menuData.title
            cell.titleLabel.textColor = .white
            cell.colors = menuData.colors
            cell.imageView.image = menuData.image
            cell.contentView.layer.cornerRadius = Section(rawValue: indexPath.section)! == .vertical ? 15 : 5
            cell.radiusTopRight = 40
        }
        
        let BalanceCellRegistration = UICollectionView.CellRegistration<BalanceCell, MenuData> { (cell, indexPath, menuData) in
            // Populate the cell with our item description.
            cell.titleLabel.text = menuData.title
            cell.colors = menuData.colors
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, MenuData>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: MenuData) -> UICollectionViewCell? in
            
            //            return Section(rawValue: indexPath.section)! == .horizontal ?
            //            collectionView.dequeueConfiguredReusableCell(using: CardCellRegistration, for: indexPath, item: identifier) :
            //            collectionView.dequeueConfiguredReusableCell(using: textCellRegistration, for: indexPath, item: identifier)
            
            if  Section(rawValue: indexPath.section)! == .horizontal {
                if indexPath == IndexPath(item: 0, section: 0) {
                    return collectionView.dequeueConfiguredReusableCell(using: BalanceCellRegistration, for: indexPath, item: identifier)
                } else {
                    return collectionView.dequeueConfiguredReusableCell(using: CardCellRegistration, for: indexPath, item: identifier)
                }
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: textCellRegistration, for: indexPath, item: identifier)
            }
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
        var snapshot = NSDiffableDataSourceSnapshot<Section, MenuData>()
        Section.allCases.forEach { [weak self] section in
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
