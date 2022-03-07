//
//  UIViewController+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-27.
//

import UIKit

extension UIViewController {
    /*! @fn showSpinner
     @brief Shows the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func showSpinner(message: String? = "Please Wait...\n\n\n\n", _ completion: (() -> Void)?) {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: nil, message: message,
                                                    preferredStyle: .alert)
            SaveAlertHandle.set(alertController)
            let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
            spinner.color = UIColor(ciColor: .black)
            spinner.center = CGPoint(x: alertController.view.frame.midX,
                                     y: alertController.view.frame.midY)
            spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                        .flexibleLeftMargin, .flexibleRightMargin]
            spinner.startAnimating()
            alertController.view.addSubview(spinner)
            self?.present(alertController, animated: true, completion: completion)
        }
    }
    
    func showSpinner() {
        DispatchQueue.main.async { [weak self] in
            let alertController = UIAlertController(title: nil, message: "Please Wait...\n\n\n\n",
                                                    preferredStyle: .alert)
            SaveAlertHandle.set(alertController)
            let spinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
            spinner.color = UIColor(ciColor: .black)
            spinner.center = CGPoint(x: alertController.view.frame.midX,
                                     y: alertController.view.frame.midY)
            spinner.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin,
                                        .flexibleLeftMargin, .flexibleRightMargin]
            spinner.startAnimating()
            alertController.view.addSubview(spinner)
            self?.present(alertController, animated: true, completion: nil)
        }
    }
    
    /*! @fn hideSpinner
     @brief Hides the please wait spinner.
     @param completion Called after the spinner has been hidden.
     */
    func hideSpinner(_ completion: (() -> Void)?) {
        if let controller = SaveAlertHandle.get() {
            SaveAlertHandle.clear()
            DispatchQueue.main.async {
                controller.dismiss(animated: true, completion: completion)
            }
        } else {
            completion!()
        }
    }
    
    func hideSpinner() {
        if let controller = SaveAlertHandle.get() {
            SaveAlertHandle.clear()
            DispatchQueue.main.async {
                controller.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func tapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func tappedToDismiss() {
        view.endEditing(true)
    }
}

// MARK: - SaveAlertHandle
private class SaveAlertHandle {
    static var alertHandle: UIAlertController?
    
    class func set(_ handle: UIAlertController) {
        alertHandle = handle
    }
    
    class func clear() {
        alertHandle = nil
    }
    
    class func get() -> UIAlertController? {
        return alertHandle
    }
}

extension UIView {
    var allSubviews: [UIView] {
        return self.subviews.flatMap { [$0] + $0.allSubviews }
    }
}
