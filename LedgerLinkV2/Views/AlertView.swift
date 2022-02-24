//
//  AlertView.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-15.
//

import UIKit

struct AlertView {
    func show(_ error: Error?, for controller: UIViewController?) {
        guard let controller = controller else {
            return
        }

        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            controller.present(alert, animated: true, completion: nil)
        }
    }
    
    func show(_ message: String, for controller: UIViewController?) {
        guard let controller = controller else {
            return
        }

        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            controller.present(alert, animated: true, completion: nil)
        }
    }
}
