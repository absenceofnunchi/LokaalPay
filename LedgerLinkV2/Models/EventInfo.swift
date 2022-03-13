//
//  EventInfo.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-10.
//

import Foundation

/// The event info that will be included int the genesis block.
/// The info will be queries and shown to the guests when they want to join an event.
struct EventInfo: Codable, Equatable, Hashable {
    let eventName: String
    let currencyName: String
    var description: String?
    var image: Data?
    var chainID: String /// chain ID works as the password
}
