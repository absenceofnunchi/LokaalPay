//
//  NetworkTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-24.
//

import XCTest
import MultipeerConnectivity
import web3swift
import BigInt
import Combine
@testable import LedgerLinkV2

final class NetworkTests: XCTestCase {
    let password = "1"
    var storage = Set<AnyCancellable>()

    
    func test_createNewBlock() {
        Node.shared.deleteAll()
        for i in 0...5 {
            Node.shared.createBlock { (lightBlock: LightBlock) in
                XCTAssertEqual(lightBlock.number, Int32(i + 1))
                
                Node.shared.fetch(lightBlock.id) { (fetchedBlocks: [LightBlock]?, error: NodeError?) in
                    if let error = error {
                        XCTAssertNil(error)
                    }
                    
                    XCTAssertTrue(fetchedBlocks!.count > 0)
                    if let blocks = fetchedBlocks, let block = blocks.first {
                        XCTAssertEqual(block, lightBlock)
                    }
                }
            }
        }
        Node.shared.deleteAll()
    }
    
    func test_test() {
//        let date0 = Date()
//        let date1 = Date().advanced(by: 100)
//
//        print("A", date0 < date1)
//        print("B", date0 > date1)
        
        for transaction in transactions {
            guard let encodedTx = transaction.encode() else { return }
            let timeStampedTx = [
                Date(): encodedTx
            ]
            
            do {
                let encoded = try JSONEncoder().encode(timeStampedTx)
                print("encoded", encoded)
                guard let result = parse(encoded) else { return }
                switch result {
                    case .data(let data):
                        print("data", data)
                        break
                    case .date(let date):
                        print("date", date)
                        break
                    case .timeStampedData(let data):
                        print("timestamped", data)
                        break
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func parse(_ data: Data) -> Result? {
        if let decompressed = data.decompressed {
            return .data(decompressed)
        } else if let decoded = try? JSONDecoder().decode(Date.self, from: data) {
            return .date(decoded)
        } else if let decoded = try? JSONDecoder().decode([Date: Data].self, from: data) {
            return .timeStampedData(decoded)
        }
        
        return nil
    }
    
    enum Result {
        case data(Data)
        case date(Date)
        case timeStampedData([Date: Data])
    }
    
    struct Example: Codable {
        var extraData: Data?
        
        enum CodingKeys: String, CodingKey {
            case extraData
        }
        
        func encode(to encoder: Encoder) throws {
            var encoder = encoder.container(keyedBy: CodingKeys.self)
            try encoder.encode(extraData, forKey: .extraData)
        }
        
        init(extraData: Data?) {
            self.extraData = extraData
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.extraData = try container.decodeIfPresent(Data.self, forKey: .extraData)
        }
    }
    
    func test_test1() {
//        guard let rlp1 = transactions[0].encode() else {
//            print("no")
//            return
//        }
//        let rlp2 = transactions[1].encode()!
//        let rlp3 = transactions[0].encode()!
//
//
//        print("1", rlp1 == rlp2)
//        print("2", rlp1 == rlp3)
//
//        let decoded = EthereumTransaction.fromRaw(rlp1)
//        print(decoded)
        
        do {
            var keystoreManager: KeystoreManager?
            do {
                keystoreManager = try KeysService().keystoreManager()
                print("keystoreManager", keystoreManager?.addresses?.first)
            } catch {
                print("keystore error", error)
            }
            
            // Create a public signature
            let tx = EthereumTransaction.createLocalTransaction(nonce: BigUInt(100), to: addresses[1], value: BigUInt(10), data: Data())
            guard let signedTx = try EthereumTransaction.signLocalTransaction(keystoreManager: keystoreManager, transaction: tx, from: EthereumAddress("0x193d729335a03f2b94a4fae4e34423e66987089e")!, password: "1") else {
                print("Unable to sign transaction")
                return
            }
            
            guard let encodedSig = signedTx.encode(forSignature: false) else {
                print("Unable to RLP-encode the signed transaction")
                return
            }

            print("encodedSig", encodedSig)

            let decoded = EthereumTransaction.fromRaw(encodedSig)
            guard let publicKey = decoded?.recoverPublicKey() else { return }
            print("publicKey", publicKey)
            let senderAddress = Web3.Utils.publicToAddressString(publicKey)
            print("sender", senderAddress)
        } catch {
            print("sig error", error)
        }
    }
    
    func test_test5() {
        let set0: Set<Int> = [1, 2, 3]
        let set1: Set<Int> = [3, 4, 5]
        let final = set0.subtracting(set1)
        print("f", final)
        print("array", Array(final))
        
        let final1 = set0.filter { !set1.contains($0) }
        print("f1", final1)
    }
  
}
