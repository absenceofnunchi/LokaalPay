//
//  NetworkManager.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-17.
//

import Foundation
import MultipeerConnectivity
import MediaPlayer
import web3swift

final class NetworkManager: NSObject {
    static let shared = NetworkManager()
    private let serviceType = "ledgerlink"
    private var peerID: MCPeerID!
    private var session: MCSession!
    private var nearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    private var nearbyBrowser: MCNearbyServiceBrowser!
    private var peerDataHandler: ((Data, MCPeerID) -> Void)?
    private var peerConnectedHandler: ((MCPeerID) -> Void)?
    private var peerDisconnectedHandler: ((MCPeerID) -> Void)?
    private let maxNumPeers: Int = 10
    private var player: AVQueuePlayer!
    private var playerLooper: AVPlayerLooper!
    private var isServerRunning = false
    private var timer: Timer!
    private var transactions: [Data] = [] // an array of transactions to be sent
    private let transactionService = TransactionService()
    var blockchainReceiveHandler: ((String) -> Void)?

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
        nearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        nearbyServiceAdvertiser.delegate = self
        nearbyServiceAdvertiser?.startAdvertisingPeer()
        nearbyBrowser.startBrowsingForPeers()
        isServerRunning = true
        
        /// Start the pinging only at every 0 or 30 second so that all the devices could be synchronized.
        let date = Date()
        let roundedDate = date.rounded(on: 30, .second)
        if timer != nil {
            timer.invalidate()
        }
        /// From the 0 or 30 second mark, the auto relay is run at a specified interval
        timer = Timer(fireAt: roundedDate, interval: 5, target: self, selector: #selector(autoRelay), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
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
        guard isServerRunning,
              transactions.count > 0,
              let compressedData = transactions.compressed else { return }
        
        sendDataToAllPeers(data: compressedData)
        transactions.removeAll()
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
            try session.send(data, toPeers: peers, with: mode)
        } catch let error {
            NSLog("Error sending data: \(error)")
        }
    }
    
    /// Add the transaction data to the queue to be compressed and sent during the auto relay.
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
        
        guard let dataArray = data.decompressedToArray else {
            return
        }
        
        
        for data in dataArray {
            /// First check and see if the transaction already exists in the node and, if it does, simply return, if it doesn't, propagate right away (don't wait for the predefined interval) then validate.
            /// If valid, include it in the block and mine. If not valid, do nothing.
            guard let decodedSig = EthereumTransaction.fromRaw(data),// RLP -> EthereumTransaction
                  let publicKey = decodedSig.recoverPublicKey(),
                  let address = Web3.Utils.publicToAddressString(publicKey),
                  let senderMetaDataAddress = decodedSig.sender?.address,
                  address == senderMetaDataAddress.lowercased(),
                  let decodedExtraData = try? JSONDecoder().decode(TransactionExtraData.self, from: decodedSig.data) else {
                      continue
                  }
            
            let contractMethodString = String(decoding: decodedExtraData.contractMethod, as: UTF8.self)
            guard let contractMethod = ContractMethods(rawValue: contractMethodString) else {
                return
            }
            print("contractMethod", contractMethod as Any)
            
            switch contractMethod {
                case .transferValue:
                    print("transferValue")
                    let tx = TreeConfigurableTransaction(rlpTransaction: data)
                    
                    do {
                        try NodeDB.shared.transfer(tx, decoded: decodedSig)
                    } catch {
                        print(error)
                    }
                    break
                case .blockchainDownloadRequest:
                    print("blockchainDownloadRequest")
                    relayBlockchain(peerID: peerID)
                    break
                case .blockchainDownloadResponse:
                    print("blockchainDownloadResponse")
                    if let handler = blockchainReceiveHandler {
                        handler("blockchainDownloadResponse")
                    }
                    break
            }
        }
    }
    
    /// When another device asks for a copy of a blockchain to download, first check to see if you have a blockchain that's up-to-date, and if yes, forward the blockchain
    private func relayBlockchain(peerID: MCPeerID) {
        print("peerID", peerID)
        /// TODO: get the entire blockchain from Core Data and send it
        
        guard let contractMethod = ContractMethods.blockchainDownloadResponse.data else {
            return
        }
        let extraData = TransactionExtraData(contractMethod: contractMethod)
        transactionService.prepareTransaction(extraData: extraData, to: nil, password: "1") { [weak self] (data, error) in
            if let error = error {
                print("blockchain download response error", error)
            }
            
            if let data = data, let compressed = [data].compressed {
                self?.sendData(data: compressed, peers: [peerID], mode: .reliable)
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceive", stream)
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
