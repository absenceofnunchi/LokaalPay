//
//  AsyncOperation.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-24.
//

import Foundation
import web3swift
import MultipeerConnectivity

// MARK: - Operation

public extension Operation {
    @discardableResult func observeStateChanges() -> [NSKeyValueObservation] {
        let keyPaths: [KeyPath<Operation, Bool>] = [
            \Operation.isExecuting,
             \Operation.isCancelled,
             \Operation.isFinished
        ]
        
        return keyPaths.map { keyPath in
            observe(keyPath, options: .new) { (_, value) in
                print("- \(keyPath._kvcKeyPathString!) is now \(value.newValue!)")
            }
        }
    }
}

// MARK: - AsyncOperation

open class AsyncOperation: Operation {
    private let lockQueue = DispatchQueue(label: "com.ledgerLink.asyncoperation", attributes: .concurrent)
    
    override open var isAsynchronous: Bool {
        return true
    }
    
    private var _isExecuting: Bool = false
    override open private(set) var isExecuting: Bool {
        get {
            return lockQueue.sync { () -> Bool in
                return _isExecuting
            }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            lockQueue.sync(flags: [.barrier]) {
                _isExecuting = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }
    
    private var _isFinished: Bool = false
    override open private(set) var isFinished: Bool {
        get {
            return lockQueue.sync { () -> Bool in
                return _isFinished
            }
        }
        set {
            willChangeValue(forKey: "isFinished")
            lockQueue.sync(flags: [.barrier]) {
                _isFinished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override open func start() {
        guard !isCancelled else {
            finish()
            return
        }
        
        isFinished = false
        isExecuting = true
        main()
    }
    
    override open func main() {
        /// Use a dispatch after to mimic the scenario of a long-running task.
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1), execute: {
            print("Executing")
            self.finish()
        })
    }
    
    open func finish() {
        isExecuting = false
        isFinished = true
    }
}

// MARK: - AsyncResultOperation

open class AsyncResultOperation<Success, Failure>: AsyncOperation where Failure: Error {
    
    private(set) public var result: Result<Success, Failure>! {
        didSet {
            onResult?(result)
        }
    }
    
    public var onResult: ((_ result: Result<Success, Failure>) -> Void)?
    
    final override public func finish() {
        guard !isCancelled else { return super.finish() }
        fatalError("Make use of finish(with:) instead to ensure a result")
    }
    
    public func finish(with result: Result<Success, Failure>) {
        self.result = result
        super.finish()
    }
    
    override open func cancel() {
        fatalError("Make use of cancel(with:) instead to ensure a result")
    }
    
    public func cancel(with error: Failure) {
        self.result = .failure(error)
        super.cancel()
    }
}

open class ChainedAsyncResultOperation<Input, Output, Failure>: AsyncResultOperation<Output, Failure> where Failure: Swift.Error {
    
    private(set) public var input: Input?
    
    public init(input: Input? = nil) {
        self.input = input
    }
    
    override public final func start() {
        updateInputFromDependencies()
        super.start()
    }
    
    /// Updates the input by fetching the output of its dependencies.
    /// Will always get the first output matching dependency.
    /// If `input` is already set, the input from dependencies will be ignored.
    private func updateInputFromDependencies() {
        guard input == nil else { return }
        input = dependencies.compactMap { dependency in
            return (dependency as? ChainedOperationOutputProviding)?.output as? Input
        }.first
    }
}

// MARK: - ChainedOperationOutputProviding

protocol ChainedOperationOutputProviding {
    var output: Any? { get }
}

extension ChainedAsyncResultOperation: ChainedOperationOutputProviding {
    var output: Any? {
        return try? result?.get()
    }
}

/// Preliminary process prior to executing the contract methods. Parse the transaction so that:
/// 1. Checks if the transaction already exists.
/// 2. Checks if the local blockchain is up-to-date
///     A. If it is, proceed to the execution of the contract methods.
///     B. If not up-to-date, download the blockchain.
///     C. If the local is more up-to-date then the peer, send the rest of the blockchain to the peer.
final class ParseTransactionOperation: ChainedAsyncResultOperation<Void, (TransactionExtraData, EthereumTransaction), NodeError> {
    private var rlpData: Data // RLP encoded transaction
    private var peerID: MCPeerID
    private var decodedTx: EthereumTransaction!
    private var decodedExtraData: TransactionExtraData!
    
    init(rlpData: Data, peerID: MCPeerID) {
        self.rlpData = rlpData
        self.peerID = peerID
    }
    
    override func main() {
        
        /// 1. Verify signature
        /// 2. Check if it already exists. If it does, do nothing. If it doesn't, propagate
        /// 3. Check if the latest block matches the one you have
        /// 4. Determine the purpose of the transaction by parsing the contract method
        /// 5. For transferValue and createAccount, compare the block number to ensure the node is up-to-date.
        ///     A. If not up-to-date, ping the sender peer to download the blockchain.
        ///     B. If up-to-date, proceed
        /// 6. Add the transactions to the validated pool to be added to a block.
        
        /// 1. Verify signature
        guard let decodedTx = EthereumTransaction.fromRaw(rlpData),// RLP -> EthereumTransaction
              let publicKey = decodedTx.recoverPublicKey(),
              let senderAddress = Web3.Utils.publicToAddressString(publicKey),
              let senderAddressToBeCompared = decodedTx.sender?.address,
              senderAddress == senderAddressToBeCompared.lowercased(),
              let decodedExtraData = try? JSONDecoder().decode(TransactionExtraData.self, from: decodedTx.data) else {
                  self.finish(with: .failure(NodeError.generalError("Unable to parse transaction")))
                  return
              }
        
        /// Retained to be used in Notification Center's listener
        self.decodedTx = decodedTx
        self.decodedExtraData = decodedExtraData
        
        guard let compressed = rlpData.compressed else {
            self.finish(with: .failure(NodeError.generalError("Compression of RLP-encoded data error")))
            return
        }
        
        /// 2. Check if the transaction already exists. Abort if it already exists
        Node.shared.fetch(compressed.sha256().toHexString()) { [weak self] (txs: [TreeConfigurableTransaction]?, error: NodeError?) in
            if let error = error {
                self?.finish(with: .failure(error))
                return
            }
            
            print("txs", txs as Any)
            
            /// No matching transaction exists in Core Data so proceed to process the transaction
            guard let txs = txs, txs.count == 0  else {
                self?.finish(with: .failure(NodeError.generalError("Already exists")))
                return
            }
            
            /// 3. Compare your node's latest block number to the lastest number provided by the transation
            Node.shared.localStorage.getLatestBlock { (block: LightBlock?, error: NodeError?) in
                if let error = error {
                    self?.finish(with: .failure(error))
                    return
                }
                
                print("block", block as Any)
                /// If both the latest block number from Core Data and the block number from the sender of the transaction are the same, proceed with the processing of the transaction
                /// If you have a lower block number than the transaction's, request to download the rest of the blockchain.
                /// If you have a higher block number, then send the rest of the blocks to the sender of the transaction
                guard let block = block else {
                    self?.finish(with: .failure(NodeError.generalError("Unable to determine the latest block")))
                    return
                }

                if block.number == decodedExtraData.latestBlockNumber {
                    print("1")
                    /// The local blockchain is up-to-date and good to go . Transfer value or create account
                    self?.finish(with: .success((decodedExtraData, decodedTx)))
                } else if block.number > decodedExtraData.latestBlockNumber {
                    print("2")
                    /// Send a portion of the blockchain to the peer whose blockchain isn't up-to-date and proceed with the rest of the transaction.
                    guard let self = self,
                          let convertedNumber = Int32(decodedExtraData.latestBlockNumber.description) else { return }
                    NetworkManager.shared.sendBlockchain(convertedNumber, format: "number > %i", peerID: self.peerID)
                    self.finish(with: .success((decodedExtraData, decodedTx)))
                } else if block.number < decodedExtraData.latestBlockNumber {
                    print("3")
                    /// Current blockchain not up-to-date. Send a request to download a blockchain
                    guard let peerID = self?.peerID else {
                        self?.finish(with: .failure(NodeError.generalError("Unable to parse PeerID")))
                        return
                    }

                    
                    /// Prevent the isFinished KVO from being triggered until the blockchain is full updated.
                    NetworkManager.shared.requestBlockchain(peerIDs: [peerID]) { error in
                        if let error = error {
                            self?.finish(with: .failure(error))
                            return
                        }
                        
                        self?.finish(with: .success((decodedExtraData, decodedTx)))
                    }
                }
            }
        }
    }
    
    override func cancel() {
        super.cancel()
    }
}

///
final class ContractMethodOperation: ChainedAsyncResultOperation<(TransactionExtraData, EthereumTransaction), Bool, NodeError> {
    override final public func main() {
        NetworkManager.shared.notificationCenter.removeObserver(self, name: .didReceiveBlockchain, object: nil)
        guard let input = input else { return finish(with: .failure(.generalError("Unable to process the dependency input"))) }
        do {
            try self.executeContractMethod(extraData: input.0, decodedTx: input.1)
            Node.shared.addValidatedTransaction(input.1)
        } catch {
            self.finish(with: .failure(error as! NodeError))
        }
        
        self.finish(with: .success(true))
    }
    
    func executeContractMethod(extraData: TransactionExtraData, decodedTx: EthereumTransaction) throws {
//        let contractMethodString = String(decoding: extraData.contractMethod, as: UTF8.self)
//        guard let contractMethod = ContractMethods(rawValue: contractMethodString) else {
//            throw NodeError.generalError("Unable to parse the contract method")
//        }
//        print("contractMethod", contractMethod as Any)
//        
//        switch contractMethod {
//            case .transferValue:
//                print("transferValue")
//                Node.shared.transfer(transaction: decodedTx)
//                break
//            case .createAccount:
//                print("createAccount")
//                guard let newAccount = extraData.account else { return }
//                /// validated accounts are to be included in the block
//                Node.shared.addValidatedAccount(newAccount)
//                print("newAccount", newAccount as Any)
//                Node.shared.saveSync([newAccount]) { error in
//                    if let error = error {
//                        print(error as Any)
//                        return
//                    }
//                    print("saved")
//                }
//                break
//            default:
//                break
//        }
    }
    
    override final public func cancel() {
        cancel(with: .generalError("Cancelled"))
    }
}

//public typealias ShortURL = URL
//public typealias LongURL = URL
//
//public final class UnfurlURLChainedOperation: ChainedAsyncResultOperation<ShortURL, LongURL, UnfurlURLChainedOperation.Error> {
//    public enum Error: Swift.Error {
//        case canceled
//        case missingInputURL
//        case missingRedirectURL
//        case underlying(error: Swift.Error)
//    }
//
//    private var dataTask: URLSessionTask?
//
//    public init(shortURL: URL) {
//        super.init(input: shortURL)
//    }
//
//    override final public func main() {
//        guard let input = input else { return finish(with: .failure(.missingInputURL)) }
//
//        var request = URLRequest(url: input)
//        request.httpMethod = "HEAD"
//
//        dataTask = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (_, response, error) in
//            if let error = error {
//                self?.finish(with: .failure(.underlying(error: error)))
//                return
//            }
//
//            guard let longURL = response?.url else {
//                self?.finish(with: .failure(.missingRedirectURL))
//                return
//            }
//
//            self?.finish(with: .success(longURL))
//        })
//        dataTask?.resume()
//    }
//
//    override final public func cancel() {
//        dataTask?.cancel()
//        cancel(with: .canceled)
//    }
//}

//
//public final class FetchTitleChainedOperation: ChainedAsyncResultOperation<URL, String, FetchTitleChainedOperation.Error> {
//    public enum Error: Swift.Error {
//        case canceled
//        case dataParsingFailed
//        case missingInputURL
//        case missingPageTitle
//        case underlying(error: Swift.Error)
//    }
//
//    private var dataTask: URLSessionTask?
//
//    override final public func main() {
//        guard let input = input else { return finish(with: .failure(.missingInputURL)) }
//
//        var request = URLRequest(url: input)
//        request.httpMethod = "GET"
//
//        dataTask = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
//            do {
//                if let error = error {
//                    throw error
//                }
//
//                guard let data = data, let html = String(data: data, encoding: .utf8) else {
//                    throw Error.dataParsingFailed
//                }
//
//                guard let pageTitle = self?.pageTitle(for: html) else {
//                    throw Error.missingPageTitle
//                }
//
//                self?.finish(with: .success(pageTitle))
//            } catch {
//                if let error = error as? Error {
//                    self?.finish(with: .failure(error))
//                } else {
//                    self?.finish(with: .failure(.underlying(error: error)))
//                }
//            }
//        })
//        dataTask?.resume()
//    }
//
//    private func pageTitle(for html: String) -> String? {
//        guard let rangeFrom = html.range(of: "<title>")?.upperBound else { return nil }
//        guard let rangeTo = html[rangeFrom...].range(of: "</title>")?.lowerBound else { return nil }
//        return String(html[rangeFrom..<rangeTo])
//    }
//
//    override final public func cancel() {
//        dataTask?.cancel()
//        cancel(with: .canceled)
//    }
//}
