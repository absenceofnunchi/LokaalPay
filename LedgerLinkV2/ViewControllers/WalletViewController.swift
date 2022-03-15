//
//  WalletViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-08.
//

import UIKit

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
    var subtitle: String? = nil
    let image: UIImage
    let identifier = UUID()
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

final class WalletViewController: UIViewController {
    
    private var menuDataArray: [MenuData] = [
        MenuData(section: .horizontal, colors: [UIColor(red: 251/255, green: 255/255, blue: 163/255, alpha: 1).cgColor, UIColor(red: 102/255, green: 211/255, blue: 126/255, alpha: 1).cgColor, UIColor(red: 255/255, green: 187/255, blue: 145/255, alpha: 1).cgColor], title: "Balance", image: UIImage(systemName: "arrow.down")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        MenuData(section: .horizontal, colors: [UIColor.red.cgColor, UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1).cgColor, UIColor.blue.cgColor], title: "Send", image: UIImage(systemName: "arrow.up")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        MenuData(section: .horizontal, colors: [UIColor.purple.cgColor, UIColor.orange.cgColor, UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1).cgColor], title: "Receive", image: UIImage(systemName: "arrow.down")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
//        MenuData(section: .horizontal, colors: [UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Send", image: UIImage(systemName: "arrow.up")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
//        MenuData(section: .horizontal, colors: [UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Receive", image: UIImage(systemName: "arrow.down")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        
//        MenuData(section: .vertical, colors: [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.black.cgColor], title: "Reset Password", image: UIImage(systemName: "lock.rotation.open")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
//        MenuData(section: .vertical, colors: [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.black.cgColor], title: "Transaction History", image: UIImage(systemName: "book.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
//        MenuData(section: .vertical, colors: [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.black.cgColor], title: "Private Key", image: UIImage(systemName: "lock.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
//        MenuData(section: .vertical, colors: [UIColor.black.cgColor, UIColor.black.cgColor, UIColor.black.cgColor], title: "Delete", image: UIImage(systemName: "trash.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal))
        
        MenuData(section: .vertical, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Reset Password", image: UIImage(systemName: "lock.rotation.open")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        MenuData(section: .vertical, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Transaction History", image: UIImage(systemName: "book.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        MenuData(section: .vertical, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Private Key", image: UIImage(systemName: "lock.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal)),
        MenuData(section: .vertical, colors: [UIColor(red: 70/255, green: 70/255, blue: 70/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor, UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1).cgColor], title: "Delete", image: UIImage(systemName: "trash.circle")!.withTintColor(.white, renderingMode: .alwaysOriginal))
    ]
    
    private var dataSource: UICollectionViewDiffableDataSource<Section, MenuData>! = nil
    private var collectionView: UICollectionView! = nil
    private let alert = AlertView()
    private let keysService = KeysService()
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBarTintColorToTheNavigationBar()
        configureUI()
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

extension WalletViewController {
    func configureUI() {
        title = "Wallet"
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .black
        view.addSubview(collectionView)
        collectionView.delegate = self
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

extension WalletViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        collectionView.deselectItem(at: indexPath, animated: true)
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        guard let selectedItem = dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
                
        switch selectedItem.title {
            case "Send":
                let vc = SendViewController()
                
                if UIDevice.current.userInterfaceIdiom != .phone {
                    vc.modalPresentationStyle = .fullScreen
                }
                
                present(vc, animated: true)
                break
            case "Receive":
                let vc = ReceiveViewController(infoType: .address)
                
                if UIDevice.current.userInterfaceIdiom != .phone {
                    vc.modalPresentationStyle = .fullScreen
                }
                
                present(vc, animated: true)
                break
            case "Reset Password":
                resetPassword()
            case "Private Key":
                showPrivateKey()
            case "Transaction History":
                showTransactionHistory()
            case "Delete":
                deleteAccount()
            default:
                break
        }
    }
    
    private func resetPassword() {
        // reset your password
        let prVC = PasswordResetViewController()
        prVC.titleString = "Reset your password"
        prVC.buttonAction = { [weak self] vc in
            
            self?.dismiss(animated: true, completion: {
                
                let prVC = vc as! PasswordResetViewController
                guard let oldPassword = prVC.currentPasswordTextField.text,
                      let newPassword = prVC.passwordTextField.text else { return }
                
                self?.showSpinner()

                self?.keysService.resetPassword(oldPassword: oldPassword, newPassword: newPassword) { [weak self] (wallet, error) in
                    if let error = error {
                        switch error {
                            case .failureToFetchOldPassword:
                                self?.alert.showDetail("Error", with: "Sorry, the old password couldn't be fetched", alignment: .center, for: self)
                            case .failureToRegeneratePassword:
                                self?.alert.showDetail("Error", with: "Sorry, a new password couldn't be generated", alignment: .left, for: self)
                            default:
                                self?.alert.showDetail("Error", with: "Sorry, failed to reset your password", alignment: .left, for: self)
                                break
                        }
                    }

                    if let wallet = wallet {
                        Node.shared.localStorage.saveWallet(wallet: wallet) { error in
                            if let _ = error {
                                self?.alert.showDetail("Error", with: "Sorry, there was an error generating a new password. Check to see if you're using the correct password.", alignment: .left, for: self)
                            }

                            self?.alert.showDetail("Success", with: "A new password has been generated!", alignment: .center, for: self)
                        }
                    }
                }
            })
        }
        present(prVC, animated: true, completion: nil)
    }
    
    private func showPrivateKey() {
        // show private key
        let content = [
            StandardAlertContent(
                titleString: "Private Key Retrieval",
                body: [AlertModalDictionary.passwordSubtitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
        ]
        
        let alertVC = AlertViewController(height: 350, standardAlertContent: content)
        alertVC.action = { [weak self] (modal, mainVC) in
            mainVC.buttonAction = { _ in
                guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                      !password.isEmpty else {
                          self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                          return
                      }
                
                self?.dismiss(animated: true, completion: {
                                        
                    let receiveVC = ReceiveViewController(infoType: .privateKey, password: password)
                    receiveVC.modalPresentationStyle = .fullScreen
                    self?.present(receiveVC, animated: true, completion: nil)
                })
            }
        }
        present(alertVC, animated: true, completion: nil)
    }
    
    private func showTransactionHistory() {
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
    }
    
    private func deleteAccount() {
        // delete
        let content = [
            StandardAlertContent(
                titleString: "Delete Wallet",
                body: ["": "Are you sure you want to delete your wallet from your local storage?"],
                messageTextAlignment: .left,
                alertStyle: .withCancelButton,
                buttonAction: { [weak self](_) in
                    self?.dismiss(animated: true, completion: nil)
                    Node.shared.localStorage.deleteWallet { (error) in
                        if let error = error {
                            self?.alert.showDetail("Sorry", with: error.localizedDescription, for: self)
                            return
                        }
                    }
                },
                borderColor: UIColor.clear.cgColor
            )
            
        ]
        let alertVC = AlertViewController(height: 350, standardAlertContent: content)
        alertVC.action = { [weak self] (modal, mainVC) in
            mainVC.buttonAction = { _ in
                guard let password = modal.dataDict[AlertModalDictionary.passwordSubtitle],
                      !password.isEmpty else {
                          self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                          return
                      }
                
                self?.dismiss(animated: true, completion: {
                    
                    Node.shared.deleteAll()
                    UserDefaults.standard.removeObject(forKey: UserDefaultKey.walletPassword)
                    UserDefaults.standard.removeObject(forKey: UserDefaultKey.chainID)
                    NetworkManager.shared.disconnect()
                    AuthSwitcher.logout()
                })
            }
        }
        self.present(alertVC, animated: true, completion: nil)
    }
}

enum UIUserInterfaceIdiom : Int {
    case unspecified
    
    case phone // iPhone and iPod touch style UI
    case pad   // iPad style UI (also includes macOS Catalyst)
}
