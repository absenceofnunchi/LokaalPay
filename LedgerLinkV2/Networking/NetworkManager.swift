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
    private var transactions: [Data] = [] // transactions to be sent
    private let transactionService = TransactionService()
    var blockchainReceiveHandler: ((String) -> Void)?
    let notificationCenter = NotificationCenter.default
    private var storage = Set<AnyCancellable>()
    
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
    
    enum Methods: String {
        case transfer
        case downloadBlockchain
        case blockchainReceived
    }
    
    // MARK: - `MPCSession` public methods.
    func start() {
        guard isServerRunning == false else { return }
        self.nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: self.serviceType)
        self.nearbyServiceAdvertiser.delegate = self
        self.nearbyServiceAdvertiser?.startAdvertisingPeer()
        self.nearbyBrowser.startBrowsingForPeers()
        self.isServerRunning = true
        
        /// Start the pinging only at every 0 or 30 second so that all the devices could be synchronized.
        let date = Date()
        let roundedDate = date.rounded(on: 30, .second)
        if self.timer != nil {
            self.timer.invalidate()
        }
        /// From the 0 or 30 second mark, the auto relay is run at a specified interval
        self.timer = Timer(fireAt: roundedDate, interval: 10, target: self, selector: #selector(self.autoRelay), userInfo: nil, repeats: true)
        RunLoop.main.add(self.timer, forMode: .common)
    }
    
    func suspend() {
        nearbyServiceAdvertiser?.stopAdvertisingPeer()
        nearbyBrowser.stopBrowsingForPeers()
        player = nil
        playerLooper = nil
        timer?.invalidate()
        isServerRunning = false
    }
    
    func disconnect() {
        suspend()
        session.disconnect()
    }
    
    func getServerStatus() -> Bool {
        return isServerRunning
    }
    
    func getConnectedPeerNumbers() -> Int {
        return session.connectedPeers.count
    }
    
    @objc private func autoRelay() {
        print("autoRelay")
        guard isServerRunning else { return }
        
        /// This is going to be used for dispatching blocks only
        
        Node.shared.createBlock { [weak self] (blockNumber) in
            guard let transactions = self?.transactions,
                  transactions.count > 0,
                  let compressed = transactions.compressed else { return }
                  
            self?.sendDataToAllPeers(data: compressed)
            self?.transactions.removeAll()
            
//            var dict: [String : Data] = [:]
//
//            do {
//                let encodedTransactions = try JSONEncoder().encode(transactions)
//                let encodedBlockNumber = try JSONEncoder().encode(blockNumber)
//
//                dict.updateValue(encodedTransactions, forKey: "transactions")
//                dict.updateValue(encodedBlockNumber, forKey: "blockNumber")
//
//                guard let compressedData = dict.compressed else { return }
//
//                self?.sendDataToAllPeers(data: compressedData)
//                self?.transactions.removeAll()
//            } catch {
//                print(error)
//            }
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
        if let handler = peerDisconnectedHandler {
            DispatchQueue.main.async {
                handler(peerID)
            }
        }
        
        if session.connectedPeers.count < maxNumPeers {
            self.start()
        }
    }
    
    func sendDataToAllPeers(data: Data) {
        print("session.connectedPeers", session.connectedPeers)
        guard !session.connectedPeers.isEmpty else { return }
        sendData(data: data, peers: session.connectedPeers, mode: .reliable)
    }
    
    func sendData(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode) {
        do {
            let filteredPeers = peers.filter { $0 != session.myPeerID }
            print("filteredPeers", filteredPeers as Any)
            try session.send(data, toPeers: filteredPeers, with: mode)
        } catch let error {
            NSLog("Error sending data: \(error)")
        }
    }
    
    /// Add the transaction data to the queue to be compressed and sent during the auto relay.
    /// Any transactions to be sent out also have to be processed by the sender themselves as if these were received from another device
    func enqueue(_ data: Data) {
        transactions.append(data)
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

    /*
     Session delegate method that gets called when data is sent from another peer through MPC using the send method.
     The order of parsing:
     
     1. Decompress.
     2. Deserialize from RLP to EthereumTransaction.
     3. Recover the public key from the public signature within EthereumTransaction.
     4. Derive an Ethereum address from the public key and compare it to the sender's address.  If same, it validates the public signature, therefore, proceed.
     5. Parse the parameters to an array of Data.  The Data could be either the UTF8 encoding of ContractMethods's raw data or other types to be defined in the future.
     6. Depending on what the ContractMethod is, execute the transaction.
     */
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceive", data)
        let queue = OperationQueue()
        
        /// Any non-transactions don't have to go through the queue
        /// Any compressed data falls under the first condition: blockchain request (blocks, tx, and accts compressed).
        if let uncompressed = data.decompressed {
            guard let packet = try? JSONDecoder().decode(Packet.self, from: uncompressed) else {
                print("unable to decode packet")
                return
            }
            
            if let blocks = packet.blocks, blocks.count > 0 {
                
            }
            
            
            if let blocks = try? JSONDecoder().decode([LightBlock].self, from: data) {
                print("downloaded blocks0", blocks as Any)
                guard blocks.count > 0 else { return }
                print("downloaded blocks1", blocks as Any)
                /// Blockchain data received as a response to a request for a portion of blockchain
                /// Bring the local blockchian up-to-date
                Node.shared.localStorage.getLatestBlock { (block: LightBlock?, error: NodeError?) in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    if let block = block {
                        /// Only save the blocks that are greater in its block number than then the already existing blocks.
                        let nonExistingBlocks = blocks.filter { $0.number > block.number }
                        /// There is a chance that the local blockchain size might have increased during the transfer. If so, ignore the received block
                        if nonExistingBlocks.count > 0 {
                            Node.shared.saveSync(nonExistingBlocks) { error in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                
                                //                            self?.notificationCenter.post(name: .didReceiveBlockchain, object: nil)
                            }
                        } else {
                            //                        self?.notificationCenter.post(name: .didReceiveBlockchain, object: nil)
                        }
                    } else {
                        /// no local blockchain exists yet because it's a brand new account
                        /// delete potentially existing ones since no transactions could've/should've been occured
                        Node.shared.deleteAll(of: .blockCoreData)
                        Node.shared.saveSync(blocks) { error in
                            if let error = error {
                                print(error)
                                return
                            }
                        }
                    }
                }
            }
        } else if let blockNumber = try? JSONDecoder().decode(Int32.self, from: data) {
            print("block request received from \(peerID) for \(session.myPeerID)", blockNumber as Any)
            /// Sending over the requested portion of blockchain
            sendBlockchain(blockNumber, format: "number > %i", peerID: peerID)
        } else if let rlpDataArray = data.decompressedToArray {
            print("rlpDataArray", rlpDataArray as Any)
            /// Parse an array of RLP-encoded transactions sent from peers and add them to the queue
            for rlpData in rlpDataArray {
                let parseOperation = ParseTransactionOperation(rlpData: rlpData, peerID: peerID)
                let contractMethodOperation = ContractMethodOperation()
                contractMethodOperation.addDependency(parseOperation)
                
                queue.addOperations([parseOperation, contractMethodOperation], waitUntilFinished: true)
                print("Operation finished with: \(contractMethodOperation.result!)")
            }
        } else {
            print("single RLP")
            /// Parse a single uncompressed, RLP-encoded transaction and add it to the queue. Account creation and value transfer are sent this way.
            let parseOperation = ParseTransactionOperation(rlpData: data, peerID: peerID)
            let contractMethodOperation = ContractMethodOperation()
            contractMethodOperation.addDependency(parseOperation)
            queue.addOperations([parseOperation, contractMethodOperation], waitUntilFinished: true)
            print("Operation finished with: \(contractMethodOperation.result!)")
        }
    }
    
    func requestBlockchainFromAllPeers(completion: @escaping(NodeError?) -> Void) {
        guard !session.connectedPeers.isEmpty else {
            completion(.generalError("No peers"))
            return
        }
        requestBlockchain(peerIDs: session.connectedPeers, completion: completion)
    }
    
    /// When another device asks for a copy of a blockchain to download, first check to see if you have a blockchain that's up-to-date, and if yes, forward the blockchain
    func requestBlockchain(peerIDs: [MCPeerID], completion: @escaping (NodeError?) -> Void) {
        do {
            let block: LightBlock? = try Node.shared.localStorage.getLastestBlockSync()
            print("latestBlock", block as Any)
            /// local blockchain may or may not exists
            let blockNumber = block?.number ?? Int32(0)
            let data = try JSONEncoder().encode(blockNumber)
            print("encoded latest block", data)
            self.sendData(data: data, peers: peerIDs, mode: .reliable)
            completion(nil)
        } catch {
            print(error)
            completion(.generalError("request block error"))
        }
        
        //        Node.shared.localStorage.getLatestBlock { (block: LightBlock?, error: NodeError?) in
        //            if let error = error {
        //                completion(error)
        //            }
        //
        //            if let block = block {
        //                guard let blockNumber = try? JSONEncoder().encode(block.number) else { return }
        //                self.sendData(data: blockNumber, peers: [peerID], mode: .reliable)
        //            }
        //
        //            guard let blockNumber = try? JSONEncoder().encode(0) else { return }
        //            self.sendData(data: blockNumber, peers: [peerID], mode: .reliable)
        //        }
    }
    
    func sendBlockchain(_ blockNumber: Int32, format: String, peerID: MCPeerID) {
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
                        let encoded = try JSONEncoder().encode(packet)
                        guard let compressed = encoded.compressed else {
                            promise(.failure(.generalError("Unable to compress data")))
                            return
                        }
                        promise(.success(compressed))
                    } catch {
                        promise(.failure(.generalError("Unable to encode data")))
                        return
                    }
                }
                .eraseToAnyPublisher()
            })
            .sink { completion in
                print(completion)
            } receiveValue: { finalValue in
                print("finalValue", finalValue)
                NetworkManager.shared.sendData(data: finalValue, peers: [peerID], mode: .reliable)
            }
            .store(in: &self.storage)
    }
    
//    func sendBlockchain(_ blockNumber: Int32, format: String, peerID: MCPeerID, completion: @escaping (NodeError?) -> Void) {
//        print("blockNumber in send blockchain", blockNumber as Any)
//        Node.shared.localStorage.getBlocks(from: blockNumber, format: format) { (blocks: [LightBlock]?, error: NodeError?) in
//            if let error = error {
//                completion(error)
//                return
//            }
//
//            print("blocks to send in sendBlockchain0", blocks as Any)
//            guard let blocks = blocks else {
//                completion(.generalError("Unable to fetch blocks"))
//                return
//            }
//
//
//            Node.shared.fetch { (accounts: [TreeConfigurableAccount]?, error: NodeError?) in
//                if let error = error {
//                    completion(error)
//                    return
//                }
//            }
//
//            print("blocks to send in sendBlockchain1", blocks as Any)
//            do {
//                let encoded = try JSONEncoder().encode(blocks)
//                print("encoded lightblocks", encoded)
//                NetworkManager.shared.sendData(data: encoded, peers: [peerID], mode: .reliable)
//            } catch {
//                completion(.generalError("Unable to send blockchain"))
//                return
//            }
//        }
//    }

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

//extension NetworkManager: MCBrowserViewControllerDelegate {
//    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
//        dismiss(animated: true)
//    }
//
//    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
//        dismiss(animated: true)
//    }
//}

// MARK: - MCNearbyServiceBrowserDelegate
extension NetworkManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer", peerID)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)

        //        session.nearbyConnectionData(forPeer: peerID) { [weak self] (data, error) in
        //            if let error = error {
        //                print("nearby error", error)
        //            }
        //
        //            if let data = data {
        //                print("connectPeer", data)
        //                self?.session.connectPeer(peerID, withNearbyConnectionData: data)
        //            }
        //        }
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
