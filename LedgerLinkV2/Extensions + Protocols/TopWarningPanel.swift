//
//  TopWarningPanel.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-13.
//

import UIKit

protocol TopWarningPanel where Self: UIViewController {
    var passwordBlurView: BlurEffectContainerView! { get set }
    var passwordStatusLabel: UILabel! { get set }
}

extension TopWarningPanel {
    func configureTopWarningPanel() {
        passwordBlurView = BlurEffectContainerView(blurStyle: .regular)
        passwordBlurView.frame = CGRect(origin: CGPoint(x: view.bounds.origin.x, y: view.bounds.origin.y), size: CGSize(width: view.bounds.size.width, height: 100))
        passwordBlurView.transform = CGAffineTransform(translationX: 0, y: -100)
        view.addSubview(passwordBlurView)
        
        passwordStatusLabel = createLabel(text: "")
        passwordStatusLabel.textAlignment = .center
        passwordStatusLabel.backgroundColor = .clear
        passwordStatusLabel.font = UIFont.rounded(ofSize: 14, weight: .regular)
        passwordStatusLabel.textColor = UIColor.red
        passwordStatusLabel.isHidden = true
        passwordBlurView.addSubview(passwordStatusLabel)
        
        NSLayoutConstraint.activate([
            passwordStatusLabel.bottomAnchor.constraint(equalTo: passwordBlurView.bottomAnchor, constant: 0),
            passwordStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            passwordStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            passwordStatusLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    func showAlert(alertMsg: String) {
        passwordStatusLabel.isHidden = false
        passwordStatusLabel.text = alertMsg
        
        /// Get the y coordinate distance of the password view and the screen so the animation could be toggled between those two coordinates
        let yDelta = view.bounds.origin.y - passwordBlurView.frame.origin.y
        
        let animation = UIViewPropertyAnimator(duration: 4, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/4) {
                    self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 1/4, relativeDuration: 1/2) {
                    // pause
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2/3, relativeDuration: 1/4) {
                    self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 0 : -100)
                }
            })
        }
        
        animation.startAnimation()
    }
}
