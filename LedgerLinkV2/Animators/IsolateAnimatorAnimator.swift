//
//  IsolateAnimator.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

class IsolateAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let toView = transitionContext.view(forKey: .to) else { return }
        
        // snapshot before the non-selected elements become transparent
//        let snapshot = fromView.snapshotView(afterScreenUpdates: true)!
        
        // make everything transparent except for the selected element
//        for v in fromView.allSubviews {
//            if v.tag != 2 {
//                if let label = v as? UILabel {
//                    label.textColor = .black
//                }
//
//                v.layer.borderWidth = 0
//            }
//        }

        guard let button = fromView.viewWithTag(2) as? UIButton else {
            return
        }
        
        let finalFrame = transitionContext.finalFrame(for: toVC)
        toView.frame = finalFrame
//        toView.alpha = 0
        let containerView = transitionContext.containerView
        containerView.insertSubview(toView, at: 0)
        containerView.insertSubview(fromView, at: 1)
//        containerView.insertSubview(snapshot, at: 2)

        UIView.animateKeyframes(withDuration: 2, delay: 0, options: .calculationModeCubic) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
//                snapshot.alpha = 0
                for subview in fromView.allSubviews where subview.tag != 2 {
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
