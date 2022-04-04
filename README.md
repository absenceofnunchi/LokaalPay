# Lokaal Pay


Offline payment solution for hosting events. If you are an event organizer for private functions, conferences, destination weddings, or festivals where the Internet connection is not readily available or if you simply want to create an enclosed ecosystem, Lokaal Pay provides an ability to create a virtual currency that will last for the duration of the event. Lokaal Pay is powered by a blockchain technology that sends, receives, and validates through a peer-to-peer method. The public ledger of the locally created blockchain provides transparency for the transactions that any participants can view and verify. It's an efficient alternative to the traditional payment solutions that obviates setting up an Internet infrastructure or RFID.

## Installation

```bash
git clone https://github.com/igibliss00/LokaalPay.git
```

## How It Works

The architecture is modelled after Ethereum. The payment process occurs in 4 steps:

1. **Transaction Creation**: Alice sends an X amount of the agreed upon custom currency to Bob by creating a transaction.  A transaction include information like the amount to send, the address of the recipient, the address of the sender, the chain ID (this is to distinguish the pertinent blockchain in case there are more than one blockchain in existence in the vicinity), nonce (the order of the transactions), etc.  The transaction is cryptographically signed to create a public signature (ECDSA).

2. **Transaction Propagation**: The transaction is then encoded into a JSON format and sent to Alice’s connected peer devices using Apple’s Multipeer Connectivity framework which adopts the UDP (User Datagram Protocol). UDP is chosen over TCP because constantly tearing down and setting up conections is costly.  If the peer device is not a host, relay the transaction to its own peers again.  This broadcasting is continued until the transaction is eventually received by the host, like a ripple effect.

3. **Transaction Validation (Block Creation)**: The host gathers all the received transactions and recovers the public keys from each to validate them.  If a transaction is valid, the host executes the transaction’s main task intended by Alice, which is to subtract an X amount from Alice’s account in the blockchain ledger and increase an X amount in Bob’s account, which are saved in Core Data.  Finally, the host includes the executed transactions in a block and broadcasts the block to its peer devices.  

4. **Block Propagation**: The peer devices accept the block sent by the host, relay it to their own peers. Every device then verifies that the block is legitimate by checking the block hash, block number, and its parent hash. If the block is legitimate, it includes it in its Core Data to reflect the updated balance of Alice and Bob. 

The host of an event is the sole validator of the blockchain, remotely akin to Ethereum’s validator in the Proof-Of-Stake consensus model.  Therefore, there is no mining involved in the validation process, which also means there is no coinbase rewarded to miners.  The validator’s sole incentive is that the validator is the host of its own event.

In short, the offline payment solution is made possible by combining the Apple framework’s way of establishing peer-to-peer connections and the distributed ledger of the blockchain technology.  A centralized web server (or the internet) is not required since every participating device has its own identical copy of the blockchain.


## Structure

1. **Network Manager**: In charge of any communication-related tasks. A singleton.
    * Detects and connects to peer devices.
    * Receives and sends transactions and blocks.
    ```swift
    func sendData(data: Data, peers: [MCPeerID], mode: MCSessionSendDataMode) {
        do {
            let filteredPeers = peers.filter { $0 != session.myPeerID }
            try session.send(data, toPeers: filteredPeers, with: mode)
        } catch let error {
            NSLog("Error sending data: \(error)")
        }
    }
    
    func relayBlock(_ blockData: Data) {
        /// Check the sent history to prevent duplicate sends
        if var sentPeersSet = blockRelayHistory[blockData] {
            /// Use MultiSet to avoid potential duplicates.
            sentPeersSet.insert(peerID)
            /// Extract only the unsent peers from the pool of connected peers
            let unsentPeers = Set(session.connectedPeers).subtracting(sentPeersSet)
            /// Send blocks to the unsent peers.
            sendData(data: blockData, peers: Array(unsentPeers), mode: .reliable)
            /// Include the list of unsent peers into a list of sent peers
            unsentPeers.forEach { sentPeersSet.insert($0) }
            /// Update the relay history in order to void sending the same block multiple times.
            blockRelayHistory.updateValue(sentPeersSet, forKey: blockData)
        } else {
            /// No peers have been contacted regarding this specific data yet.
            let unsentPeers = session.connectedPeers.filter { $0 != peerID }
            blockRelayHistory.updateValue(Set(unsentPeers), forKey: blockData)
            sendData(data: blockData, peers: session.connectedPeers, mode: .reliable)
        }
    }
    ```
    * Triggers local notification when funds are arrived or sent.
    * Tracks the device's location to indicate the distance to a host. Notifies the user if the device is outside the optimal distance.
    
2. **Node**: In charge of transactions and blocks. A singleton.
    * Creates transactions and public signatures.
    * A validator creates genesis and onward blocks.
    * A validator verifies and executes transactions, such as account creation or balance transfer.
    * As the order of execution is important, the received transactions are arranged in the asynchronous and chained `Operation` and executed sequentially by a validator.
    ```swift
    final class TransferValueOperation: ChainedAsyncResultOperation<Void, Bool, NodeError> {
        var transaction: EthereumTransaction
        
        init(transaction: EthereumTransaction) {
            self.transaction = transaction
        }
        
        override final public func main() {
            Node.shared.transfer(transaction: transaction)
            self.finish(with: .success(true))
        }
        
        override final public func cancel() {
            cancel(with: .generalError("Cancelled"))
        }
    }
    ```
    * Interacts with Core Data.
    * Creates wallet.

3. **Core Data**: 
    * Saves Accounts, Transactions, Blocks and Wallets.
    * Accounts, Transactions, and Blocks are RLP-encoded and compressed using LZFSE before being saved in Core Data.
    ```swift
    init(data: Account) throws {
            guard let encoded = data.encode() else {
            throw NodeError.encodingError
        }
        
        guard let compressed = encoded.compressed else {
            throw NodeError.compressionError
        }
        
        self.id = data.address.address
        self.data = compressed
    }
    ```
    * Blocks to Accounts and Transactions have a one-to-many relationship.  When a series of blocks, or a blockchain, is downloaded by a peer, the related transactions and accounts are automatically saved in a one-to-many relationship.  Likewise, if a block is to be deleted, all the related transactions and accounts are deleted accordingly.
    ```swift
      func saveRelationalBlock(block: FullBlock, completion: @escaping (NodeError?) -> Void) {
        /// Halt if a block already exists
        let existingBlock: LightBlock? = try? getBlock(block.hash.toHexString())
        if existingBlock != nil {
            completion(NodeError.generalError("Block already exists"))
            return
        }
        
        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "saveTransactionContext"
        taskContext.transactionAuthor = "transactionSaver"
        
        taskContext.performAndWait {
            do {
                let blockObject = BlockCoreData(context: taskContext)
                let lightBlock = try LightBlock(data: block)
                blockObject.id = lightBlock.id
                let number = Int32(lightBlock.number)
                blockObject.number = number
                blockObject.data = lightBlock.data
                
                if let transactions = block.transactions {
                    for tx in transactions {
                        let transactionObject = TransactionCoreData(context: taskContext)
                        transactionObject.id = tx.id
                        transactionObject.data = tx.data
                        blockObject.addToTransactions(transactionObject)
                    }
                }
                
                if let accounts = block.accounts {
                    for account in accounts {
                        let stateObject = StateCoreData(context: taskContext)
                        stateObject.id = account.id
                        stateObject.data = account.data
                        blockObject.addToStates(stateObject)
                    }
                }
                
                try taskContext.save()
                completion(nil)
            } catch {
                completion(NodeError.generalError("Block save error"))
            }
        }
    }
    ```

4. **Background Mode**
    * Tracks the location of the user's device upon authorization to determine whether the user is within the optimal proximity to a host.
    ```swift
    func getUserLocation() {
        locationManager = CLLocationManager()
        locationManager?.requestAlwaysAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.distanceFilter = kCLDistanceFilterNone
        locationManager?.startUpdatingLocation()
    }
    ```
    * App continously receives and relays transactions and blocks when backgrounded.


## Screenshots

1. Event registration by a host

![](https://github.com/igibliss00/LokaalPay/blob/main/ReadmeAssets/1.jpg)


2. Wallet view controller showing the menu and the balance

![](https://github.com/igibliss00/LokaalPay/blob/main/ReadmeAssets/2.jpg)


3. Explorer to view the details of the blockchain

![](https://github.com/igibliss00/LokaalPay/blob/main/ReadmeAssets/3.jpg)


4. Server view controller showing the status of the connection

![](https://github.com/igibliss00/LokaalPay/blob/main/ReadmeAssets/4.jpg)


5. Map showing the optimal parameter of a host in relation to the location of the user's own device

![](https://github.com/igibliss00/LokaalPay/blob/main/ReadmeAssets/6.jpg)


6. Local notification to let a user know that they are outside the optimal distance from a host

![](https://github.com/igibliss00/LokaalPay/blob/main/ReadmeAssets/5.jpg)







