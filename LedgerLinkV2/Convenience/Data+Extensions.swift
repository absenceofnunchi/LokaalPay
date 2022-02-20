//
//  Data+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-11.
//

import Foundation

extension Data {
    var compressed: Data? {
        guard let compressed = try? (self as NSData).compressed(using: .lzfse) else {
            return nil
        }
        
        return Data(compressed)
    }
    
    var decompressedToArray: [Data]? {
        guard let decompressed = try? (self as NSData).decompressed(using: .lzfse) else {
            return nil
        }
        
        let data = Data(referencing: decompressed)
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode([Data].self, from: data) else {
            return nil
        }
        
        return decoded
    }
    
//    var decompressed: Data? {
//        guard let decompressed = try? (self as NSData).decompressed(using: .lzfse) else {
//            return nil
//        }
//
//        let data = Data(referencing: decompressed)
//        let decoder = JSONDecoder()
//        guard let decoded = try? decoder.decode(Data.self, from: data) else {
//            return nil
//        }
//
//        return decoded
//    }
    
    var decompressed: Data? {
        guard let decompressed = try? (self as NSData).decompressed(using: .lzfse) else {
            return nil
        }
        
        return Data(decompressed)
    }
}
