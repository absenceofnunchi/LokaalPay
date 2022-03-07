//
//  LoginAnimator.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

class LoginAnimator: NSObject, UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let forwardAnimator = IsolateAnimator()
        return forwardAnimator
    }
    
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return BackwardAnimator(menuData: menuData, imageRect: imageRect, constraints: constraints)
//    }
}
