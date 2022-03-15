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
    
    typealias Action = () -> Void
    var action: Action? = { }
    
    func showDetail(
        _ title: String,
        with message: String?,
        height: CGFloat = 350,
        fieldViewHeight: CGFloat = 150,
        index: Int = 0,
        alignment: NSTextAlignment = .left,
        for controller: UIViewController?,
        alertStyle: AlertStyle = .oneButton,
        buttonAction: Action? = nil,
        completion: Action? = nil) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .willDismiss, object: nil, userInfo: nil)
                controller?.hideSpinner {
                    controller?.dismiss(animated: true, completion: {
                        let content = [
                            StandardAlertContent(
                                index: index,
                                titleString: title,
                                body: ["": message ?? ""],
                                fieldViewHeight: fieldViewHeight,
                                messageTextAlignment: alignment,
                                alertStyle: alertStyle,
                                buttonAction: { (_) in
                                    buttonAction?()
                                    controller?.dismiss(animated: true, completion: nil)
                                })
                        ]
                        let alertVC = AlertViewController(height: height, standardAlertContent: content)
                        controller?.present(alertVC, animated: true, completion: {
                            completion?()
                        })
                    })
                }
            }
        }
    
    
    enum FadingLocation {
        case center, top
    }
    
    // MARK: - fading
    /// show a message for a brief period and disappears e.i "Copied"
    func fading(
        text: String = "Copied!",
        controller: UIViewController?,
        toBePasted: String?,
        width: CGFloat = 150,
        location: FadingLocation = .center,
        completion: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            guard let controller = controller else { return }
            let dimmingView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            dimmingView.translatesAutoresizingMaskIntoConstraints = false
            dimmingView.layer.cornerRadius = 10
            dimmingView.clipsToBounds = true
            controller.view.addSubview(dimmingView)
            
            let label = UILabel()
            label.font = UIFont.rounded(ofSize: 14, weight: .bold)
            label.text = text
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            label.sizeToFit()
            label.backgroundColor = .clear
            label.alpha = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            dimmingView.contentView.addSubview(label)
            
            if let tbp = toBePasted {
                let pasteboard = UIPasteboard.general
                pasteboard.string = tbp
            }
            
            NSLayoutConstraint.activate([
                dimmingView.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
                dimmingView.widthAnchor.constraint(equalToConstant: width),
                dimmingView.heightAnchor.constraint(equalToConstant: 150),
                
                label.centerXAnchor.constraint(equalTo: dimmingView.contentView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: dimmingView.contentView.centerYAnchor)
            ])
            
            if location == .center {
                NSLayoutConstraint.activate([
                    dimmingView.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
                ])
            } else if location == .top {
                NSLayoutConstraint.activate([
                    dimmingView.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: 200)
                ])
            }
            
            UIView.animate(withDuration: 0.3) {
                label.alpha = 1
            }
            
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { timer in
                UIView.animate(withDuration: 0.3) {
                    label.alpha = 0
                }
                dimmingView.removeFromSuperview()
                timer.invalidate()
                //                controller.dismiss(animated: true, completion: nil)
            }
            
            completion?()
        }
    }
}
