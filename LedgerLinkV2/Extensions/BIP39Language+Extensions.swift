//
//  BIP39Language+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-14.
//

import Foundation
import web3swift

extension BIP39Language {
    public init?(language: String) {
        switch language {
            case "english":
                self = .english
            case "chinese_simplified":
                self = .chinese_simplified
            case "chinese_traditional":
                self = .chinese_traditional
            case "japanese":
                self = .japanese
            case "korean":
                self = .korean
            case "french":
                self = .french
            case "italian":
                self = .italian
            case "spanish":
                self = .spanish
            default:
                return nil
        }
    }
}
