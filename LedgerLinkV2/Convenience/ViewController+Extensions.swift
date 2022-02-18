//
//  ViewController+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-06.
//

import Foundation
import UIKit

extension UIViewController {
    func tapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func tappedToDismiss() {
        view.endEditing(true)
    }
}
