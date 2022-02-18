//
//  ConnectionStatus.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-04.
//

import Foundation

struct ConnectionStatus {
    var listenerState: String?
    var browserState: String?
    var connectionState: String?
    
    enum State {
        case listenSuccess(String)
        case listenFail(String)
        case browseSuccess(String)
        case browseFail(String)
        case connectionSuccess(String)
        case connectionFail(String)
    }
}
