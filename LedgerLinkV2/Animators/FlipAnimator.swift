//
//  FlipAnimator.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-09.
//

/*
 Flip transition animation
 */

import UIKit

class FlipTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var indexItem: Int!
    
    init(indexItem: Int) {
        self.indexItem = indexItem
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let forwardAnimator = FlipAnimator(indexItem: indexItem)
        return forwardAnimator
    }
    
    //    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    //        return BackwardAnimator(menuData: menuData, imageRect: imageRect, constraints: constraints)
    //    }
}

class FlipAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var indexItem: Int!
    
    init(indexItem: Int) {
        self.indexItem = indexItem
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
//        guard let fromView = transitionContext.view(forKey: .from),
//              let toVC = transitionContext.viewController(forKey: .to),
//              let toView = transitionContext.view(forKey: .to) else { return }
//        

    }
}
