//
//  GuestLoginViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

/*
 For a guest to join an event.
 */

import UIKit
import MultipeerConnectivity

protocol BlockChainDownloadDelegate: AnyObject {
    func didReceiveBlockchain()
}

class EventsViewController: UIViewController {
    private var backButton: UIButton!
    private var dataSource: UICollectionViewDiffableDataSource<Section, EventInfo>! = nil
    private var collectionView: UICollectionView! = nil
    private var titleLabel: UILabel!
    private var alert = AlertView()
    
    private let data = [
        EventInfo(eventName: "Wedding0", currencyName: "Deniro", description: "Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! Hello! ", image: nil, chainID: "1234"),
        EventInfo(eventName: "Wedding1", currencyName: "Deniro", description: "Hello!", image: nil, chainID: "1234"),
        EventInfo(eventName: "Wedding2", currencyName: "Deniro", description: "Hello!", image: nil, chainID: "1234"),
        EventInfo(eventName: "Wedding3", currencyName: "Deniro", description: "Hello!", image: nil, chainID: "1234"),
        EventInfo(eventName: "Wedding4", currencyName: "Deniro", description: "Hello!", image: nil, chainID: "1234"),
    ]
    
    private var dataArray = [EventInfo]()
    private var createWalletMode: Bool = false
    private var isPeerConnected: Bool = false {
        didSet {
            if isPeerConnected && createWalletMode {
                /// When account creation is triggered for a non-host,
                /// wait for the connection to be established and send a request to download the blockchain
                /// createWalletMode for requestBlockchain to be only triggered during the create wallet mode and not every time peer is connected.
                requestBlockchain()
                createWalletMode = false
            }
        }
    }
    
    enum Section: Int, CaseIterable {
        case main
        
        var columnCount: Int {
            switch self {
                case .main:
                    return 1
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureDataSource()
        
        /// set up the server and node
//        Node.shared.deleteAll()
//        Node.shared.eventQueryDelegate = self /// Event Query delegate let's the GuestLoginVC know when the events have been downloaded
//        Node.shared.downloadDelegate = self /// Download delegate let's the GuestLoginVC know when the blockchain has been downloadeded by calling didReceiveBlockchain
//        NetworkManager.shared.start(startAutoRelay: false)
//        NetworkManager.shared.peerConnectedHandler = peerConnectedHandler
        
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            var snapshot = NSDiffableDataSourceSnapshot<Section, EventInfo>()
            Section.allCases.forEach { section in
                snapshot.appendSections([section])
                snapshot.appendItems(self.data)
            }
            
            self.dataSource.applySnapshotUsingReloadData(snapshot)
        }
    }
    
    
    func peerConnectedHandler(_ peerID: MCPeerID) {
        isPeerConnected = true

        do {
            let contractMethod = ContractMethod.eventsQueryRequest
            let encodedMethod = try JSONEncoder().encode(contractMethod)
            NetworkManager.shared.sendDataToAllPeers(data: encodedMethod)
        } catch {
            print("block send error", error)
        }
    }
    
    @objc final func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                dismiss(animated: true)
                break
            default:
                break
        }
    }
}

extension EventsViewController {
    /// - Tag: PerSection
    private func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int,
                                                            layoutEnvironment: NSCollectionLayoutEnvironment)
            -> NSCollectionLayoutSection? in
            
            let isWideView = layoutEnvironment.container.effectiveContentSize.width > 500
            let sectionLayoutKind = Section.allCases[sectionIndex]
            switch (sectionLayoutKind) {
                case .main: return self.generateVerticalLayout(isWide: isWideView)
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
        let groupFractionalWidth: CGFloat = isWide ? 0.425 : 1
        let groupFractionalHeight: CGFloat = 0.75
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(groupFractionalWidth),
            heightDimension: .fractionalHeight(groupFractionalHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 1)
        
        /// Section
        let section = NSCollectionLayoutSection(group: group)
        if isWide {
            section.orthogonalScrollingBehavior = .groupPaging
        }
        
        return section
    }
}

extension EventsViewController {
    func configureHierarchy() {
        view.backgroundColor = .black

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: generateLayout())
        collectionView.backgroundColor = .black
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        guard let buttonImage = UIImage(systemName: "multiply", withConfiguration: config)?.withTintColor(.lightGray, renderingMode: .alwaysOriginal) else { return }
        backButton = UIButton.systemButton(with: buttonImage, target: self, action: #selector(buttonPressed))
        backButton.tag = 0
        backButton.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(backButton)
        
        titleLabel = UILabel()
        titleLabel.text = "Choose An Event"
        titleLabel.font = UIFont.rounded(ofSize: 25, weight: .bold)
        titleLabel.textColor = .lightGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            backButton.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: -100),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: -50),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func configureDataSource() {
        
        let CellRegistration = UICollectionView.CellRegistration<EventCell, EventInfo> { (cell, indexPath, eventInfo) in
            // Populate the cell with our item description.
            if let image = eventInfo.image {
                cell.eventImageView.image = UIImage(data: image)
            }

            cell.set(eventInfo: eventInfo)
            
            if indexPath.item % 2 == 0 {
                cell.radiusTopRight = 40
                cell.radiusBottomLeft = 40
            } else {
                cell.radiusTopLeft = 40
                cell.radiusBottomRight = 40
            }
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, EventInfo>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: EventInfo) -> UICollectionViewCell? in
            // Return the cell.
            return collectionView.dequeueConfiguredReusableCell(using: CellRegistration, for: indexPath, item: identifier)
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
        var snapshot = NSDiffableDataSourceSnapshot<Section, EventInfo>()
        Section.allCases.forEach { section in
            snapshot.appendSections([section])
            snapshot.appendItems(dataArray)
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension EventsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        guard let event = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
    
        let content = [
            StandardAlertContent(
                titleString: "Enter Event's Password",
                body: [AlertModalDictionary.passwordTitle: ""],
                isEditable: true,
                fieldViewHeight: 40,
                messageTextAlignment: .left,
                alertStyle: .withCancelButton
            ),
        ]
        
        DispatchQueue.main.async { [weak self] in
            let alertVC = AlertViewController(height: 350, standardAlertContent: content)
            alertVC.action = { [weak self] (modal: AlertViewController, mainVC: StandardAlertViewController) in
                mainVC.buttonAction = { _ in
                    guard let password = modal.dataDict[AlertModalDictionary.passwordTitle],
                          !password.isEmpty else {
                              self?.alert.fading(text: "Password cannot be empty!", controller: mainVC, toBePasted: nil, width: 250)
                              return
                          }
                    
        
                    guard password == event.chainID else {
                        self?.alert.fading(text: "Incorrect password", controller: mainVC, toBePasted: nil, width: 250)
                        return
                    }
                    
                    self?.dismiss(animated: true, completion: {
                        self?.showSpinner()
                        NetworkManager.shared.start()
                        self?.createWalletMode = true

                    })
                }
            }
            
            self?.present(alertVC, animated: true)
        }
    }
    
    func didReceiveBlockchain() {
        print("didReceiveBlockchain")
        guard let password = UserDefaults.standard.string(forKey: "password"),
              let chainID = UserDefaults.standard.string(forKey: "chainID") else {
                  alert.show("Requires Password and the Chain ID", for: self)
                  return
              }
        
        Node.shared.createWallet(password: password, chainID: chainID, isHost: false) { [weak self] (data) in
            self?.hideSpinner()
            self?.createWalletMode = false
//            let account = Node.shared.getMyAccount()
//            self?.addressLabel.text = account?.address.address
            NetworkManager.shared.sendDataToAllPeers(data: data)
        }
    }
    
    private func requestBlockchain() {
        NetworkManager.shared.requestBlockchainFromAllPeers(upto: 1) { [weak self](error) in
            if let error = error {
                self?.dismiss(animated: true, completion: nil)
                self?.alert.show(error, for: self)
                return
            }
        }
    }
}

extension EventsViewController: EventQueryDelegate {
    /// Fetched response from the event query in Node
    /// A list of genesis blocks from peers
    func didGetEvent(_ blocks: [LightBlock]?) {
        guard let blocks = blocks else { return }
        blocks.forEach { [weak self] in
            guard $0.number == Int32(0),
                  let fullBlock = $0.decode(),
                  let extraData = fullBlock.extraData,
                  let eventInfo = try? JSONDecoder().decode(EventInfo.self, from: extraData) else { return }
            
            var snapshot = NSDiffableDataSourceSnapshot<Section, EventInfo>()
            Section.allCases.forEach { section in
                snapshot.appendSections([section])
                snapshot.appendItems([eventInfo])
            }
            
            self?.dataSource.applySnapshotUsingReloadData(snapshot)
        }
    }
}

protocol EventQueryDelegate: AnyObject {
    func didGetEvent(_ blocks: [LightBlock]?)
}
