//
//  ReceiveViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-09.
//

import UIKit

final class ReceiveViewController: WalletModalViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func configureUI() {
        super.configureUI()
        
        titleLabel.text = "Receive Currency"
    }
}
