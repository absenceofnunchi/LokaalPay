//
//  MiningTests.swift
//  LedgerLinkV2Tests
//
//  Created by J C on 2022-02-14.
//

import XCTest
@testable import LedgerLinkV2

final class MiningTests: XCTestCase {
    func test_Start() throws {
        let mine = Mine()
        try mine.start(with: "abc123abc123abc123")
//        XCTAssertEqual("08a2c2b35f695bc08f60b9536e30685e4197b911e22e5874f1e6e3c931d3abdd", <#T##() -> T#>)
    }
}
