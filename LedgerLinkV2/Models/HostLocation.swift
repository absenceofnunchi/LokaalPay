//
//  HostLocation.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-31.
//

/*
 Abstract:
 Included in the extra data section of Block by a host to let the guests know its location.
 Used in VerifyBlock in Node by guests to parse the location and view it in MapVC
 */

import Foundation

struct HostLocation: Codable {
    let longitude: String
    let latitude: String
}
