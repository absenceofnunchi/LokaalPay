//
//  CustomTabBarController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-04.
//

import UIKit

class CustomTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        batteryAlert()
    }
    
    func batteryAlert() {
        if ProcessInfo.processInfo.isLowPowerModeEnabled, isViewLoaded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.displayBatteryPowermodeAlert()
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(powerStateChanged), name: Notification.Name.NSProcessInfoPowerStateDidChange, object: nil)
    }
    
    @objc func powerStateChanged(_ notification: Notification) {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            displayBatteryPowermodeAlert()
        }
    }
    
    func displayBatteryPowermodeAlert() {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: "Low Battery Power Mode", message: "If you have your low battery power mode on, this app will not work properly.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(ac, animated: true, completion: nil)
        }
    }
}
