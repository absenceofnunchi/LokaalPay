//
//  String+Extension.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-18.
//

import Foundation

extension String {
    func stripHexPrefix() -> String {
        if self.hasPrefix("0x") {
            let indexStart = self.index(self.startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }
}
