//
//  WalletViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-08.
//

import UIKit

class WalletViewController: UIViewController {
    enum Section: Int, CaseIterable {
        case horizontal, vertical
        
        var columnCount: Int {
            switch self {
                case .horizontal:
                    return 1
                    
                case .vertical:
                    return 3
            }
        }
    }
    
    struct MenuData: Hashable {
        let section: Section
        let colors: [CGColor]
        let title: String
        let image: UIImage
        let identifier = UUID()
        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
    }
    
    var menuDataArray: [MenuData] = [
        MenuData(section: .horizontal, colors: [UIColor.red.cgColor, UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1).cgColor, UIColor.blue.cgColor], title: "Send", image: UIImage(systemName: "arrow.up")!),
        MenuData(section: .horizontal, colors: [UIColor.purple.cgColor, UIColor.orange.cgColor, UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1).cgColor], title: "Receive", image: UIImage(systemName: "arrow.down")!),
        MenuData(section: .vertical, colors: [UIColor.black.cgColor, UIColor.darkGray.cgColor, UIColor.gray.cgColor], title: "Reset Password", image: UIImage(systemName: "arrow.up")!),
        MenuData(section: .vertical, colors: [UIColor.black.cgColor, UIColor.darkGray.cgColor, UIColor.gray.cgColor], title: "Transaction History", image: UIImage(systemName: "arrow.up")!),
        MenuData(section: .vertical, colors: [UIColor.black.cgColor, UIColor.darkGray.cgColor, UIColor.gray.cgColor], title: "Private Key", image: UIImage(systemName: "arrow.up")!),
        MenuData(section: .vertical, colors: [UIColor.black.cgColor, UIColor.darkGray.cgColor, UIColor.gray.cgColor], title: "Delete", image: UIImage(systemName: "arrow.up")!)
    ]
    
    var dataSource: UICollectionViewDiffableDataSource<Section, MenuData>! = nil
    var collectionView: UICollectionView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
    }
}

extension WalletViewController {
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
        //        group.contentInsets = NSDirectionalEdgeInsets(
        //            top: 50,
        //            leading: 50,
        //            bottom: 5,
        //            trailing: 5)
        
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
            top: 20,
            leading: 20,
            bottom: 20,
            trailing: 20)
        
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

extension WalletViewController {
    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .black
        view.addSubview(collectionView)
        collectionView.delegate = self
    }
    func configureDataSource() {
        
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
            cell.titleLabel.textAlignment = .center
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, MenuData>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: MenuData) -> UICollectionViewCell? in
            // Return the cell.
            return Section(rawValue: indexPath.section)! == .horizontal ?
            collectionView.dequeueConfiguredReusableCell(using: CardCellRegistration, for: indexPath, item: identifier) :
            collectionView.dequeueConfiguredReusableCell(using: textCellRegistration, for: indexPath, item: identifier)
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

extension WalletViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        scrollView.contentOffset.y = 0.0
//    }
}

class CardCell: UICollectionViewCell {
    let gradientView = GradientView()
    var colors: [CGColor] = [] {
        didSet {
            gradientView.gradientColors = colors
        }
    }
    let titleLabel = UILabel()
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension CardCell {
    func configure() {
        gradientView.layer.cornerRadius = 10
        gradientView.clipsToBounds = true
//        gradientView.alpha = 0.7
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradientView)
        gradientView.setFill()
    
        imageView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.addSubview(imageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.rounded(ofSize: 14, weight: .bold)
        titleLabel.textAlignment = .center
        gradientView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant:50),
            imageView.widthAnchor.constraint(equalToConstant:50),
            
            titleLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            titleLabel.widthAnchor.constraint(equalTo: gradientView.widthAnchor),
        ])
    }
}
