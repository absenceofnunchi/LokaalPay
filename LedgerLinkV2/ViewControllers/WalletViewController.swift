//
//  WalletViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-08.
//

import UIKit

struct MyData: Hashable {
    let colors: [CGColor]
    let title: String
    let image: UIImage
    let identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

class WalletViewController: UIViewController {

    enum Section: Int {
        case horizontal
        case vertical
        
        var columnCount: Int {
            switch self {
                case .horizontal:
                    return 1
                case .vertical:
                    return 2
            }
        }
    }
    
    /// items
    var myDataCollection: [MyData] = [
        MyData(colors: [UIColor.red.cgColor, UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1).cgColor, UIColor.blue.cgColor], title: "Send", image: UIImage(systemName: "arrow.up")!),
        MyData(colors: [UIColor.purple.cgColor, UIColor.orange.cgColor, UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1).cgColor], title: "Receive", image: UIImage(systemName: "arrow.down")!)
    ]
    
    var dataSource: UICollectionViewDiffableDataSource<Section, MyData>! = nil
    var collectionView: UICollectionView! = nil
    
    override func loadView() {
        let v = UIView()
        v.backgroundColor = .black
        view = v
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
    }
}

extension WalletViewController {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            // item
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.5))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            guard let layoutKind = Section(rawValue: sectionIndex) else { return nil }
            
            // group
            var group: NSCollectionLayoutGroup!
            let groupFractionalWidth = CGFloat(layoutEnvironment.container.effectiveContentSize.width > 500 ? 0.425 : 0.60)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(groupFractionalWidth), heightDimension: .absolute(layoutEnvironment.container.effectiveContentSize.height))
            if layoutKind == .horizontal {
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: layoutKind.columnCount)
                group.contentInsets = NSDirectionalEdgeInsets(top: 50, leading: 5, bottom: 0, trailing: 5)
            } else {
                group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: layoutKind.columnCount)
                group.contentInsets = NSDirectionalEdgeInsets(top: 50, leading: 5, bottom: 0, trailing: 5)
            }
            
            // section
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
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: config)
        return layout
    }
}

extension WalletViewController {
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }
    
    private func configureDataSource() {
        
        let horizontalCellRegistration = UICollectionView.CellRegistration<CardCell, MyData> { (cell, indexPath, myData) in
            cell.colors = myData.colors
            cell.titleLabel.text = myData.title
            cell.imageView.image = myData.image
        }
        
        let verticalCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, MyData> { (cell, indexPath, myData) in
            cell.backgroundView?.backgroundColor = .red
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, MyData>(collectionView: collectionView, cellProvider: { (collectionView: UICollectionView, indexPath, myData: MyData) -> UICollectionViewCell? in
            return Section(rawValue: indexPath.section)! == .horizontal ?
            collectionView.dequeueConfiguredReusableCell(using: horizontalCellRegistration, for: indexPath, item: myData) :
            collectionView.dequeueConfiguredReusableCell(using: verticalCellRegistration, for: indexPath, item: myData)
        })
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, MyData>()
        snapshot.appendSections([.horizontal, .vertical])
        snapshot.appendItems(myDataCollection)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension WalletViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset.y = 0.0
    }
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
