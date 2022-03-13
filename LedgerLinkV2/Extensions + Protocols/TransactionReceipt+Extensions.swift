//
//  TransactionReceipt+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-12.
//

import Foundation
import web3swift
import BigInt
    
extension TransactionReceipt {
    public func getHash() -> String? {
        guard let encoded = self.encode(),
              let compressed = encoded.compressed else { return nil }
        return compressed.sha256().toHexString()
    }
    
    public func encode() -> Data? {
//        let fields =  [transactionHash, blockHash, blockNumber, transactionIndex, contractAddress ?? EthereumAddress("0x")!, cumulativeGasUsed, gasUsed, status, logsBloom ?? EthereumBloomFilter()] as [AnyObject]
        
        var fields: [AnyObject]
        if let address = contractAddress?.addressData {
            fields =  [transactionHash, blockHash, blockNumber, transactionIndex, address, cumulativeGasUsed, gasUsed] as [AnyObject]
        } else {
            fields =  [transactionHash, blockHash, blockNumber, transactionIndex, cumulativeGasUsed, gasUsed] as [AnyObject]
        }

        return RLP.encode(fields)
    }
    
    public static func fromRaw(_ raw: Data, toChecksumFormat: Bool = true) throws -> TransactionReceipt? {
        guard let totalItem = RLP.decode(raw) else {return nil}
        guard let rlpItem = totalItem[0] else {return nil}
        
        var transactionHash, blockHash: Data
        var blockNumber, transactionIndex, cumulativeGasUsed, gasUsed: BigUInt
        var contractAddress: EthereumAddress
//        var logs: [EventLog]
//        var status: TXStatus
//        var logsBloom: EthereumBloomFilter
        
        switch rlpItem.count {
            case 7:
                guard let transactionHashData = rlpItem[0]!.data else {return nil}
                transactionHash = transactionHashData
                
                guard let blockHashData = rlpItem[1]!.data else {return nil}
                blockHash = blockHashData
                
                guard let blockNumberData = rlpItem[2]!.data else {return nil}
                blockNumber = BigUInt(blockNumberData)
                
                guard let transactionIndexData = rlpItem[3]!.data else {return nil}
                transactionIndex = BigUInt(transactionIndexData)
                
                switch rlpItem[4]!.content {
                    case .noItem:
                        contractAddress = EthereumAddress.contractDeploymentAddress()
                    case .data(let addressData):
                        if addressData.count == 0 {
                            contractAddress = EthereumAddress.contractDeploymentAddress()
                        } else if addressData.count == 20 {
                            guard let addr = EthereumAddress(addressData) else {return nil}
                            contractAddress = addr
                        } else {
                            return nil
                        }
                    case .list(_, _, _):
                        return nil
                }
                
                guard let cumulativeGasUsedData = rlpItem[5]!.data else {return nil}
                cumulativeGasUsed = BigUInt(cumulativeGasUsedData)
                
                guard let gasUsedData = rlpItem[6]!.data else {return nil}
                gasUsed = BigUInt(gasUsedData)
                
//                let decoder = JSONDecoder()
//                guard let logsData = rlpItem[7]!.data else {return nil}
//                do {
//                    logs = try decoder.decode([EventLog].self, from: logsData)
//                } catch {
//                    throw NodeError.decodingError
//                }
//
//                guard let statusData = rlpItem[7]!.data else {return nil}
//                do {
//                    status = try decoder.decode(TXStatus.self, from: statusData)
//                } catch {
//                    throw NodeError.decodingError
//                }
//
//                guard let statusData = rlpItem[8]!.data else {return nil}
//                do {
//                    status = try decoder.decode(TXStatus.self, from: statusData)
//                } catch {
//                    throw NodeError.decodingError
//                }
//
//                guard let logsBloomData = rlpItem[9]!.data else {return nil}
//                do {
//                    logsBloom = try decoder.decode(EthereumBloomFilter.self, from: logsBloomData)
//                } catch {
//                    throw NodeError.decodingError
//                }
                
                return TransactionReceipt(transactionHash: transactionHash, blockHash: blockHash, blockNumber: blockNumber, transactionIndex: transactionIndex, contractAddress: contractAddress, cumulativeGasUsed: cumulativeGasUsed, gasUsed: gasUsed, logs: [EventLog](), status: .ok, logsBloom: EthereumBloomFilter())
            case 6:
                guard let transactionHashData = rlpItem[0]!.data else {return nil}
                transactionHash = transactionHashData
                
                guard let blockHashData = rlpItem[1]!.data else {return nil}
                blockHash = blockHashData
                
                guard let blockNumberData = rlpItem[2]!.data else {return nil}
                blockNumber = BigUInt(blockNumberData)
                
                guard let transactionIndexData = rlpItem[3]!.data else {return nil}
                transactionIndex = BigUInt(transactionIndexData)
                
                guard let cumulativeGasUsedData = rlpItem[4]!.data else {return nil}
                cumulativeGasUsed = BigUInt(cumulativeGasUsedData)
                
                guard let gasUsedData = rlpItem[5]!.data else {return nil}
                gasUsed = BigUInt(gasUsedData)
                
                return TransactionReceipt(transactionHash: transactionHash, blockHash: blockHash, blockNumber: blockNumber, transactionIndex: transactionIndex, contractAddress: nil, cumulativeGasUsed: cumulativeGasUsed, gasUsed: gasUsed, logs: [EventLog](), status: .ok, logsBloom: EthereumBloomFilter())
            default:
                return nil
        }
    }
}

extension TransactionReceipt.TXStatus: Decodable {
    enum CodingKeys: String, CodingKey {
        case ok
        case failed
        case notYetProcessed
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let status = try? container.decode(TransactionReceipt.TXStatus.self, forKey: .ok) {
            self = status
            return
        }
        
        if let status = try? container.decode(TransactionReceipt.TXStatus.self, forKey: .failed) {
            self = status
            return
        }
        
        if let status = try? container.decode(TransactionReceipt.TXStatus.self, forKey: .notYetProcessed) {
            self = status
            return
        }
        
        throw NodeError.decodingError
    }
}

extension EthereumBloomFilter: Decodable {
    enum CodingKeys: String, CodingKey {
        case bytes
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .bytes)
        self.init(data)
    }
}
