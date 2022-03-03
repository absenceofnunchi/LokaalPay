//
//  Vectors.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-11.
//

import Foundation
import web3swift
import BigInt
@testable import LedgerLinkV2

struct Vectors {
    static let hashes: [String] = [
        "d2870829bfddde366f5ed67aa5cddc8b0ad014872c27c10c1d3f0bdaed5a23a3",
        "b39e4addf3925285c9199739eb1388d682860345e2004bebf9a5fb0a41b708e0",
        "dae9ba8aab3b22e65c5be635baffd37387ee7a50b843b0695b370f2c3f91d257",
        "203fec14e308d5ef1f01dbd37d940e669dc027c804d6a47409933008a1565aa9",
        "9c78e772291c441a0a13d14cc4530cbfa376302330889513a481864319a186fd",
        "c95ce4917d14ab2bd1d20773c89b8575ada1fce1f96d2aa9e64e3c027ce265e4",
    ]
    
    static let checksumHashes: [String] = [
        "0x18cD9fDa7d584401D04E30bf73FB0013EfE65bb0",
        "0x33C5aE72aE9a5244DB3F7c494126FF5De89F8642",
        "0x0f513E0aa598E1c2D9A5C125CBa52dc2B58B19b4",
        "0xcF23D21ffcf04585898A3d2c255C7116193785a5",
        "0xb88392425e7b8Db37D43b1EB62022C9432fD997e",
        "0x139b782cE2da824b98b6Af358f725259799D2f74",
        "0xE5891F4C1369d9FBe2BF95c16Bc4C3df1d6347EA",
        "0xe6bcf1F8Bc26CbE472Bc47E4e0Cc0943eA6Ba78F",
        "0xEA674fdDe714fd979de3EdF0F56AA9716B898ec8",
        "0x4852a691e315BB889CE7292323b276f9922e5a63",
        "0x4e63118479e2184D9400aBb1Aa0b35FF904b7389",
        "0xd1B28AD163E3163Cc458978DD200408691c390fF",
        "0xb218d2D9D8Ab1d7ADffbE2FE0902A4dfC8DA05A2",
        "0xCEfeb668f38586CFC8d4610f68907f7b52aeA789",
        "0xfFbb73852d9DA0DF8a9ecEbB85e896fd1e7D51Ec",
    ]
    
    static var binaryHashes: [Data] {
        var data = [Data]()
        for hash in checksumHashes {
            guard let converted = hash.data(using: .utf8) else { continue }
            let hashData = converted.sha256()
            data.append(hashData)
        }
        return data
    }
  
    static var rawAcccountVectors: [String: [Any]] {
        var dict = [String: [Any]]()
        for i in 0 ..< checksumHashes.count {
            let arr: [Any] = [BigUInt(i), BigUInt(i), checksumHashes[i], checksumHashes[i]]
            dict.updateValue(arr, forKey: checksumHashes[i])
        }
        
        return dict
    }
    
    static var addresses: [EthereumAddress] {
        var addressArray = [EthereumAddress]()
        for i in 0 ..< checksumHashes.count {
            guard let address = EthereumAddress(checksumHashes[i]) else { continue }
            addressArray.append(address)
        }
        return addressArray
    }

    static var accounts: [Account] {
        var arr = [Account]()
        for i in 0 ..< addresses.count {
            let account = Account(address: addresses[i], nonce: BigUInt(i), balance: BigUInt(i), codeHash: checksumHashes[i], storageRoot: checksumHashes[i])
            arr.append(account)
        }
        
        arr.append(Account(address: EthereumAddress("0x035362D35E16D0E6c35cC99ECffbCbA91Ff1747F")!, nonce: BigUInt(1), balance: BigUInt(6), codeHash: "0x139b782cE2da824b98b6Af358f725259799D2f74", storageRoot: "0x")) /// missing storageRoot
        arr.append(Account(address: EthereumAddress("0x07a8ba3F4fd4Db7f3381C07ee5a309c1aacE9C59")!, nonce: BigUInt(1), balance: BigUInt(6), codeHash: "0x", storageRoot: "0x139b782cE2da824b98b6Af358f725259799D2f74")) /// missin codeHash
        return arr
    }
    
    static var treeConfigurableAccounts: [TreeConfigurableAccount] {
        var accountsArray: [TreeConfigurableAccount] = []
        for account in accounts {
            guard let treeAccount = try? TreeConfigurableAccount(data: account) else { fatalError("treeConfigurableAccounts vector error") }
            accountsArray.append(treeAccount)
        }
        return accountsArray
    }

    static var transactions: [EthereumTransaction] {
        var txArray = [EthereumTransaction]()
        for i in 0 ..< addresses.count {
            let tx = EthereumTransaction(gasPrice: BigUInt(i), gasLimit: BigUInt(i + 100), to: addresses[i], value: BigUInt(i), data: Data())
            txArray.append(tx)
        }
        return txArray
    }
    
    static var treeConfigurableTransactions: [TreeConfigurableTransaction] {
        var txArray = [TreeConfigurableTransaction]()
        for i in 0 ..< transactions.count {
            let transaction = transactions[i]
            guard let tx = try? TreeConfigurableTransaction(data: transaction) else { fatalError("treeConfigurableTransactions vector error") }
            txArray.append(tx)
        }
        return txArray
    }
    
    static var receipts: [TransactionReceipt] {
        var arr = [TransactionReceipt]()
        for i in 0 ..< addresses.count {

            let receipt = TransactionReceipt(transactionHash: binaryHashes[i], blockHash: Data(), blockNumber: BigUInt(i), transactionIndex: BigUInt(i), contractAddress: addresses[i], cumulativeGasUsed: BigUInt(i), gasUsed: BigUInt(i), logs: [EventLog](), status: .ok, logsBloom: nil)
            arr.append(receipt)
        }
        
        return arr
    }
    
    static var treeConfigurableReceipts: [TreeConfigurableReceipt] {
        var txArray = [TreeConfigurableReceipt]()
        for i in 0 ..< receipts.count {
            let receipt = receipts[i]
            guard let tx = try? TreeConfigurableReceipt(data: receipt) else { fatalError("treeConfigurableReceipts vector error") }
            txArray.append(tx)
        }
        return txArray
    }
    
    static var blocks: [FullBlock] {
        var blocks = [FullBlock]()
        for i in 0 ..< binaryHashes.count {
            guard let block = try? FullBlock(number: BigUInt(i), parentHash: binaryHashes[i], transactionsRoot: binaryHashes[i], stateRoot: binaryHashes[i], receiptsRoot: binaryHashes[i], miner: addresses[0].address, transactions: treeConfigurableTransactions, accounts: treeConfigurableAccounts) else { fatalError("blocks vector error") }
            blocks.append(block)
        }
        return blocks
    }
    
    static var lightBlocks: [LightBlock] {
        var lBlocks = [LightBlock]()
        for block in blocks {
            guard let block = try? LightBlock(data: block) else { fatalError("lightBlocks vector error") }
            lBlocks.append(block)
        }
        return lBlocks
    }
    
    /// contract creation signed transaction
    static var accountCreationTx: EthereumTransaction? {
        let chainID = 111111
        UserDefaults.standard.set(chainID, forKey: "chainID")
        
        guard let address = EthereumAddress("0xB81f0619b1A1fdD4Dd5282AFBfc13aA8Cac918Cf") else {
            return nil
        }
        
        let account = Account(address: address, nonce: BigUInt(0))
        let extraData = TransactionExtraData(account: account, timestamp: Date(), latestBlockNumber: BigUInt(10))
        guard let encodedExtraData = try? JSONEncoder().encode(extraData) else {
            return nil
        }
        var tx = EthereumTransaction(nonce: BigUInt(2), gasPrice: BigUInt(0), gasLimit: BigUInt(0), to: address, value: BigUInt(0), data: encodedExtraData, v: BigUInt(22257), r: BigUInt("6007923474381374080880944521528258202877536805082233532075661902678712469057"), s: BigUInt("40249239055129623847703970368931024850481646373911873763272102908962840697775"))
        tx.UNSAFE_setChainID(BigUInt(chainID))
        print("tx", tx)
        return tx
    }
}

//Nonce: 1
//Gas price: 0
//Gas limit: 0
//To: 0xB81f0619b1A1fdD4Dd5282AFBfc13aA8Cac918Cf
//Value: 0
//Data: 0x7b226163636f756e74223a7b226e6f6e6365223a5b222b222c315d2c2273746f72616765526f6f74223a223078222c22636f646548617368223a223078222c2262616c616e6365223a5b222b222c313030305d2c2261646472657373223a22307862383166303631396231613166646434646435323832616662666331336161386361633931386366227d2c226c6174657374426c6f636b4e756d626572223a5b222b222c315d2c2274696d657374616d70223a3636383031333631302e30333135383239357d
//v: 22257
//r: 6007923474381374080880944521528258202877536805082233532075661902678712469057
//s: 40249239055129623847703970368931024850481646373911873763272102908962840697775
//Intrinsic chainID: Optional(11111)
//Infered chainID: Optional(11111)
//sender: Optional("0xB81f0619b1A1fdD4Dd5282AFBfc13aA8Cac918Cf")
//hash: Optional("0xe5eb4e5e6f19c6e90c1a27b21b39952ed975cd20b789b9ad853882efce71eeb2")
