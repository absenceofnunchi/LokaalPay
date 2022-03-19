//
//  NetworkManager.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-17.
//

/*
 Transactions are to be sent out as soon as they're created.
 The receieved transactions are to be relayed immediately as well.
 The blocks, however, are created and added on a regular interval.
 
 When a node receives a transaction, check the block number to see if latest blocks have to be downloaded from other nodes before processing the transactions to a new block.
 */

import Foundation
import MultipeerConnectivity
import MediaPlayer
import web3swift
import BigInt
import Combine

final class NetworkManager: NSObject {
    static let shared = NetworkManager()
    private let serviceType = "ledgerlink"
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    private var nearbyBrowser: MCNearbyServiceBrowser!
    var peerDataHandler: ((Data, MCPeerID) -> Void)?
    var peerConnectedHandler: ((MCPeerID) -> Void)?
    var peerDisconnectedHandler: ((MCPeerID) -> Void)?
    private let maxNumPeers: Int = 10
    private var player: AVQueuePlayer!
    private var playerLooper: AVPlayerLooper!
    private var isServerRunning = false
    private var timer: Timer!
    private let transactionService = TransactionService()
    var blockchainReceiveHandler: ((String) -> Void)?
    let notificationCenter = NotificationCenter.default
    private var storage = Set<AnyCancellable>()
    private var transactionRelayHistory = [Data: Set<MCPeerID>]()
    private var blockRelayHistory = [Data: Set<MCPeerID>]()
    
    override init() {
        super.init()
        self.configureSession()
        self.setupNotifications()
    }
    
    private func configureSession() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        nearbyBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        nearbyBrowser.delegate = self
    }
    
    // MARK: - `MPCSession` public methods.
    func start(startAutoRelay: Bool = true) {
        self.isServerRunning = true
//        guard isServerRunning == false else { return }
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: self.serviceType)
        self.nearbyServiceAdvertiser.delegate = self
        self.nearbyServiceAdvertiser?.startAdvertisingPeer()
        self.nearbyBrowser.startBrowsingForPeers()

        /// Start the pinging only at every 0 or 30 second so that all the devices could be synchronized.
        /// Auto relay is for a validate to send blocks or for guests to execute and clear validated transactions.
        /// This isn't needed for occasions like querying events (first blocks) as a new guest.
        if startAutoRelay {
            let date = Date()
            let roundedDate = date.rounded(on: 30, .second)
            if self.timer != nil {
                self.timer.invalidate()
            }
            
            /// From the 0 or 30 second mark, the auto relay is run at a specified interval
            self.timer = Timer(fireAt: roundedDate, interval: 20, target: self, selector: #selector(self.autoRelay), userInfo: nil, repeats: true)
            RunLoop.main.add(self.timer, forMode: .common)
        }
    }
    
    func suspend() {
        nearbyServiceAdvertiser?.stopAdvertisingPeer()
        nearbyBrowser.stopBrowsingForPeers()
    }
    
    func disconnect() {
        suspend()
        isServerRunning = false
        player = nil
        playerLooper = nil
        timer?.invalidate()
        session.disconnect()
    }
    
    func getServerStatus() -> Bool {
        return isServerRunning
    }
    
    func getConnectedPeerNumbers() -> Int {
        return session.connectedPeers.count
    }
    
    @objc private func autoRelay() {
        guard isServerRunning else { return }
        
        if session.connectedPeers.count == 0 {
            suspend()
            self.nearbyServiceAdvertiser?.startAdvertisingPeer()
            self.nearbyBrowser.startBrowsingForPeers()
        }

        /// Validator: dispatches newly created blocks on a regular interval
        /// Non validator: refreshes the pools of transactions accounts, operations, and the relay history on a regular interval
        /// The blocks are processed at a set internval instead of as they arrive to 1) synchronize all devices and 2) to account for the delays in the arrival of the blocks and minimize the blocks being out of the time order
        Node.shared.processBlock { [weak self] (block) in
            if let block = block {
                do {
                    let encoded = try JSONEncoder().encode(block)
                    let contractMethod = ContractMethod.sendBlock(encoded)
                    let encodedMethod = try JSONEncoder().encode(contractMethod)
                    self?.sendDataToAllPeers(data: encodedMethod)
                } catch {
                    print("block send error", error)
                }
            }
            
            self?.transactionRelayHistory.removeAll()
            self?.blockRelayHistory.removeAll()
            /// Remove all the validated txs and accounts to prepare the for the creation of the next block
            Node.shared.validatedTransactions.removeAll()
            Node.shared.validatedAccounts.removeAll()
            /// Remove all the transactions from the pool of validated operations since they have all been executed.
            Node.shared.validatedOperations.removeAll()
        }
    }
    
    // MARK: - `MPCSession` private methods.
    private func peerConnected(peerID: MCPeerID) {
        if let handler = peerConnectedHandler {
            DispatchQueue.main.async {
                handler(peerID)
            }
        }
        
        if session.connectedPeers.count == maxNumPeers {
            self.suspend()
        }
    }
    
    private func peerDisconnected(peerID: MCPeerID) {
        if (session.connectedPeers.count < maxNumPeers) && isServerRunning {
            suspend()
            self.nearbyServiceAdvertiser?.startAdvertisingPeer()
            self.nearbyBrowser.startBrowsingForPeers()
        }
        
        if let handler = peerDisconnectedHandler {
            handler(peerID)
        }
    }
    
    func sendDataToAllPeers(data: Data) {
        guard !session.connectedPeers.isEmpty else { return }
        sendData(data: data, peers: session.connectedPeers, mode: .reliable)
    }
    
    func sendData(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode) {
        do {
            let filteredPeers = peers.filter { $0 != session.myPeerID }
            try session.send(data, toPeers: filteredPeers, with: mode)
        } catch let error {
            NSLog("Error sending data: \(error)")
        }
    }
}

// MARK: - MCSessionDelegate
extension NetworkManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
            case .connected:
                print("connected")
                peerConnected(peerID: peerID)
            case .notConnected:
                print("notConnected")
                peerDisconnected(peerID: peerID)
            case .connecting:
                print("connecting")
                break
            @unknown default:
                fatalError("Unhandled MCSessionState")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Node.shared.processTransaction(data, peerID: peerID)
    }
    
    func relayBlock(_ blockData: Data) {
        /// Check the sent history to prevent duplicate sends
        if var sentPeersSet = blockRelayHistory[blockData] {
            sentPeersSet.insert(peerID)
            let unsentPeers = Set(session.connectedPeers).subtracting(sentPeersSet)
            sendData(data: blockData, peers: Array(unsentPeers), mode: .reliable)
            unsentPeers.forEach { sentPeersSet.insert($0) }
            blockRelayHistory.updateValue(sentPeersSet, forKey: blockData)
        } else {
            /// No peers have been contacted regarding this specific data yet
            let unsentPeers = session.connectedPeers.filter { $0 != peerID }
            blockRelayHistory.updateValue(Set(unsentPeers), forKey: blockData)
            sendData(data: blockData, peers: session.connectedPeers, mode: .reliable)
        }
    }
    
    func relayTransaction(data: Data, peerID: MCPeerID) {
        /// Check the sent history to prevent duplicate sends
        if var sentPeersSet = transactionRelayHistory[data] {
            sentPeersSet.insert(peerID)
            let unsentPeers = Set(session.connectedPeers).subtracting(sentPeersSet)
            sendData(data: data, peers: Array(unsentPeers), mode: .reliable)
            unsentPeers.forEach { sentPeersSet.insert($0) }
            transactionRelayHistory.updateValue(sentPeersSet, forKey: data)
        } else {
            /// No peers have been contacted regarding this specific data yet
            let unsentPeers = session.connectedPeers.filter { $0 != peerID }
            transactionRelayHistory.updateValue(Set(unsentPeers), forKey: data)
            sendData(data: data, peers: session.connectedPeers, mode: .reliable)
        }
    }

    /// Blockchain request when there is a discrepency in the blockchain. Doesn't trigger account creation.
    func requestBlockchainFromAllPeers(upto peerNumber: Int? = nil, isInitialRequest: Bool = false, completion: @escaping(NodeError?) -> Void) {
        guard !session.connectedPeers.isEmpty else {
            completion(.generalError("No peers"))
            return
        }
        
        if let peerNumber = peerNumber {
            let partialPeers = session.connectedPeers.prefix(peerNumber)
            requestBlockchain(peerIDs: Array(partialPeers), isInitialRequest: isInitialRequest, completion: completion)
        } else {
            requestBlockchain(peerIDs: session.connectedPeers, isInitialRequest: isInitialRequest, completion: completion)
        }
    }
    
    /// Download blockchain by requesting it from another peer
    /// Request blocks with a number that's later than the latest local block.
    func requestBlockchain(peerIDs: [MCPeerID], isInitialRequest: Bool, completion: @escaping (NodeError?) -> Void) {
        do {
            
            if isInitialRequest {
                let contractMethod = ContractMethod.initialBlockchainRequest
                let data = try JSONEncoder().encode(contractMethod)
                self.sendData(data: data, peers: peerIDs, mode: .reliable)
            } else {
                let block: LightBlock? = try Node.shared.localStorage.getLatestBlock()
                /// local blockchain may or may not exists
                let blockNumber = block?.number ?? Int32(0)
                let contractMethod = ContractMethod.blockchainDownloadRequest(blockNumber)
                let data = try JSONEncoder().encode(contractMethod)
                self.sendData(data: data, peers: peerIDs, mode: .reliable)
            }

            completion(nil)
        } catch {
            print(error)
            completion(.generalError("request block error"))
        }
    }
    
    /// Request a complete blockchain.
    /// This is used when a new block to be added is incompatible with the local blockchain and needs a complete overhaul.
    func requestAllBlockchain(completion: @escaping(NodeError?) -> Void) {
        do {
            let contractMethod = ContractMethod.blockchainDownloadAllRequest
            let data = try JSONEncoder().encode(contractMethod)
            self.sendData(data: data, peers: session.connectedPeers, mode: .reliable)
            completion(nil)
        } catch {
            completion(.generalError("request block error"))
        }
    }
    
    /// Send blockchain as a response to a peer's request. Only the blocks need to be sent because the relational transactions and accounts are created upon arrival.
    /// The initial request is only for a guest at the time they choose an event.
    /// Event selection -> Blockchain download -> Account Creation.
    func sendBlockchain(_ blockNumber: Int32, format: String, peerID: MCPeerID, isInitialRequest: Bool = false) {
        Node.shared.localStorage.getBlocks(blockNumber, format: format) { (blocks: [LightBlock]?, error: NodeError?) in
            if let error = error {
                print("sendBlockchain error", error)
                return
            }
            
            if let blocks = blocks {
                /// Only blocks are sents since the accounts and the transactions are included in the block which will be saved in a relational way.
                let packet = Packet(accounts: nil, transactions: nil, blocks: blocks)
                do {
                    let contractMethod = isInitialRequest ? ContractMethod.initialBlockchainDownloadResponse(packet) : ContractMethod.blockchainDownloadResponse(packet)
                    let encodedMethod = try JSONEncoder().encode(contractMethod)
                    NetworkManager.shared.sendData(data: encodedMethod, peers: [peerID], mode: .reliable)
                } catch {
                    print("Unable to encode data", error)
                }
            }
        }
    }
    
    func sendAllBlockchain(_ blockNumber: Int32, format: String, peerID: MCPeerID) {
        Node.shared.fetch { (blocks: [LightBlock]?, error: NodeError?) in
            if let error = error {
                print("sendBlockchain error", error)
                return
            }
            
            if let blocks = blocks {
                /// Only blocks are sents since the accounts and the transactions are included in the block which will be saved in a relational way.
                let packet = Packet(accounts: nil, transactions: nil, blocks: blocks)
                do {
                    let contractMethod = ContractMethod.blockchainDownloadAllResponse(packet)
                    let encodedMethod = try JSONEncoder().encode(contractMethod)
                    NetworkManager.shared.sendData(data: encodedMethod, peers: [peerID], mode: .reliable)
                } catch {
                    print("Unable to encode data", error)
                }
            }
        }
    }
    
    /// Send blockchain without the relationship component
    func sendBlockchainNoRelationship(_ blockNumber: Int32, format: String, peerID: MCPeerID) {
        let accounts = Future<[TreeConfigurableAccount]?, NodeError> { promise in
            Node.shared.localStorage.getAllAccountsSync { (accts: [TreeConfigurableAccount]?, error: NodeError?) in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                promise(.success(accts))
            }
        }
        
        let transactions = Future<[TreeConfigurableTransaction]?, NodeError> { promise in
            Node.shared.localStorage.getAllTransactionsAsync { (tx: [TreeConfigurableTransaction]?, error: NodeError?) in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                promise(.success(tx))
            }
        }
        
        let blocks = Future<[LightBlock]?, NodeError> { promise in
            Node.shared.localStorage.getBlocks(from: blockNumber, format: format) { (blocks: [LightBlock]?, error: NodeError?) in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                promise(.success(blocks))
            }
        }
        
        Publishers.CombineLatest3(accounts, transactions, blocks)
            .collect()
            .eraseToAnyPublisher()
            .flatMap({ (results) -> AnyPublisher<Data, NodeError> in
                Future<Data, NodeError> { promise in
                    
                    var packet = Packet()
                    for (acct, tx, block) in results {
                        if let acct = acct {
                            packet.accounts?.append(contentsOf: acct)
                        }
                        
                        if let tx = tx {
                            packet.transactions?.append(contentsOf: tx)
                        }
                        
                        if let block = block {
                            packet.blocks?.append(contentsOf: block)
                        }
                    }
                    
                    do {
                        let contractMethod = ContractMethod.blockchainDownloadResponse(packet)
                        let encodedMethod = try JSONEncoder().encode(contractMethod)
                        promise(.success(encodedMethod))
                    } catch {
                        promise(.failure(.generalError("Unable to encode data")))
                        return
                    }
                }
                .eraseToAnyPublisher()
            })
            .sink { completion in
                switch completion {
                    case .finished:
                        print("sendBlockchain finished")
                    case .failure(let error):
                        print("sendBlockchain error", error)
                }
                print(completion)
            } receiveValue: { finalValue in
                print("finalValue", finalValue)
                NetworkManager.shared.sendData(data: finalValue, peers: [peerID], mode: .reliable)
            }
            .store(in: &self.storage)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceive stream", stream)
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName", resourceName)
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("didFinishReceivingResourceWithName", resourceName)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NetworkManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("didReceiveInvitationFromPeer", peerID)
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NetworkManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer", peerID)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer", peerID)
    }
}

// MARK: - Player
extension NetworkManager {
    private func getPlayerItems() -> [AVPlayerItem] {
        let itemNames = ["1"]
        return itemNames.map {
            let url = Bundle.main.url(forResource: $0, withExtension: "mp3")!
            return AVPlayerItem(url: url)
        }
    }
    
    private func makePlayer() -> AVQueuePlayer? {
        let player = AVQueuePlayer()
        let items = getPlayerItems()
        guard let item = items.first else { return nil }
        player.replaceCurrentItem(with: item)
        player.actionAtItemEnd = .advance
        //        player.addObserver(self, forKeyPath: "currentItem", options: [.new, .initial] , context: nil)
        player.volume = 0
        
        self.playerLooper = makeLooper(player: player, item: item)
        return player
    }
    
    private func makeLooper(player: AVQueuePlayer, item: AVPlayerItem) -> AVPlayerLooper {
        let looper = AVPlayerLooper(player: player, templateItem: item)
        return looper
    }
    
    /// Checking the state of the application twice seem redundant, but background to foreground sometimes triggers the player.
    private func stateCheckAndPlay() {
        DispatchQueue.main.async { [weak self] in
            if UIApplication.shared.applicationState == .active {
                self?.toggleBackgroundMode(false)
            } else if UIApplication.shared.applicationState == .inactive {
            } else if UIApplication.shared.applicationState == .background {
                self?.toggleBackgroundMode(true)
            }
        }
    }
    
    final func toggleBackgroundMode(_ isBackgrounded: Bool) {
        if isBackgrounded {
            guard isServerRunning == true else { return }
            if player == nil {
                player = self.makePlayer()
            }
            player.play()
            player.volume = 0

            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: .mixWithOthers )
            } catch {
                print("Failed to set audio session category. Error: \(error)")
            }
            
            let seconds: Float64 = 10;
            let preferredTimeScale: Int32 = 1;
            let forInterval = CMTimeMakeWithSeconds(seconds, preferredTimescale: preferredTimeScale)
            
            player.addPeriodicTimeObserver(forInterval: forInterval, queue: DispatchQueue.main) { time in
                
            }
        } else {
            player = nil
            playerLooper = nil
        }
    }
    
    /// Observe the audio interruptions.
    private func setupNotifications() {
        // Get the default notification center instance.
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(handleInterruption),
                       name: AVAudioSession.interruptionNotification,
                       object: AVAudioSession.sharedInstance())
        
        nc.addObserver(self,
                       selector: #selector(handleRouteChange),
                       name: AVAudioSession.routeChangeNotification,
                       object: nil)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                  return
              }
        
        /// Interuption ended takes time to reboot.
        switch type {
            case .began:
                break
            case .ended:
                stateCheckAndPlay()
                break
            default: ()
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        stateCheckAndPlay()
    }
    
    private func hasHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
        // Filter the outputs to only those with a port type of headphones.
        return !routeDescription.outputs.filter({$0.portType == .headphones}).isEmpty
    }
}

struct Packet: Codable {
    var accounts: [TreeConfigurableAccount]?
    var transactions: [TreeConfigurableTransaction]?
    var blocks: [LightBlock]?
}
