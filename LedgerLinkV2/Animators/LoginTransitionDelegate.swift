//
//  LoginTransitionDelegate.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

class LoginTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var selectedTag: Int!
    
    init(selectedTag: Int) {
        self.selectedTag = selectedTag
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let forwardAnimator = IsolateAnimator(selectedTag: selectedTag)
        return forwardAnimator
    }
    
    //    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    //        return BackwardAnimator(menuData: menuData, imageRect: imageRect, constraints: constraints)
    //    }
}

/*
 Abstract:
 A custom transition from IntroVC to EventVC
 */

class IsolateAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var selectedTag: Int!
    
    init(selectedTag: Int) {
        self.selectedTag = selectedTag
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let toView = transitionContext.view(forKey: .to) else { return }
        
        guard let button = fromView.viewWithTag(selectedTag) as? UIButton else {
            return
        }
        
        let finalFrame = transitionContext.finalFrame(for: toVC)
        toView.frame = finalFrame
        //        toView.alpha = 0
        let containerView = transitionContext.containerView
        containerView.insertSubview(toView, at: 0)
        containerView.insertSubview(fromView, at: 1)
        
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: .calculationModeCubic) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) { [weak self] in
                for subview in fromView.allSubviews where subview.tag != self?.selectedTag {
                    if let label = subview as? UILabel {
                        label.alpha = 0
                        label.layer.backgroundColor = UIColor.black.cgColor
                    }
                    subview.layer.borderColor = UIColor.black.cgColor
                }
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.3) {
                let center = fromView.convert(fromView.center, from: fromView.superview)
                let xDelta = button.center.x - center.x
                let yDelta = button.center.y - center.y
                button.transform = CGAffineTransform(translationX: xDelta, y: yDelta)
            }
            
            UIView.addKeyframe(withRelativeStartTime: 1, relativeDuration: 0.3) {
                toView.alpha = 1
            }
        } completion: { (_) in
            //            snapshot.removeFromSuperview()
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
