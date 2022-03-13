//
//  LoginTransitionDelegate.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

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
        
//        guard let button = fromView.viewWithTag(selectedTag) as? UIButton else {
//            return
//        }
        
        let finalFrame = transitionContext.finalFrame(for: toVC)
        toView.frame = finalFrame
        toView.alpha = 0
        let containerView = transitionContext.containerView
        containerView.addSubview(toView)
//        containerView.insertSubview(toView, at: 0)
//        containerView.insertSubview(fromView, at: 1)
        
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: .calculationModeCubic) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) { [weak self] in
                for subview in fromView.allSubviews where subview.tag != self?.selectedTag {
                    if let label = subview as? UILabel {
                        label.alpha = 0
                        label.layer.backgroundColor = UIColor.black.cgColor
                    }
                    subview.layer.borderColor = UIColor.black.cgColor
                }
                
                let imageView = fromView.viewWithTag(200)
                imageView?.alpha = 0
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.3) {
//                let center = fromView.convert(fromView.center, from: fromView.superview)
//                let xDelta = button.center.x - center.x
//                let yDelta = button.center.y - center.y
//                button.transform = CGAffineTransform(translationX: xDelta, y: yDelta)
                fromView.alpha = 0
            }
            
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.3) {
                toView.alpha = 1
            }
        } completion: { (_) in
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class BackwardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var selectedTag: Int!
    
    init(selectedTag: Int) {
        self.selectedTag = selectedTag
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let toView = transitionContext.view(forKey: .to) else { return }
     
        let fromVCInitialFrame = transitionContext.initialFrame(for: fromVC)
        fromView.frame = fromVCInitialFrame
        
        let finalFrame = transitionContext.finalFrame(for: toVC)
        toView.frame = finalFrame
        
        let containerView = transitionContext.containerView
        containerView.insertSubview(toView, belowSubview: fromView)
        
        UIView.animateKeyframes(withDuration: 2, delay: 0, options: .calculationModeCubic) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                fromView.alpha = 0
                let imageView = toView.viewWithTag(200)
                imageView?.alpha = 1
            }

            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.3) {
                
            }

            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.3) { [weak self] in
                for subview in toView.allSubviews where subview.tag != self?.selectedTag {
                    if let label = subview as? UILabel {
                        label.alpha = 1
                        label.layer.backgroundColor = UIColor.clear.cgColor
                    }
                    subview.layer.borderColor = UIColor.white.cgColor
                }
                
                toView.alpha = 1
            }
        } completion: { (_) in
            //            snapshot.removeFromSuperview()
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

protocol TransferableLayout {
    var constant: CGFloat { get set }
    var attribute: NSLayoutConstraint.Attribute { get }
    var relatedBy: NSLayoutConstraint.Relation { get }
}

struct TransferableConstraint: TransferableLayout {
    var attribute: NSLayoutConstraint.Attribute
    let relatedBy: NSLayoutConstraint.Relation
    let attribute2: NSLayoutConstraint.Attribute
    let multiplier: CGFloat
    var constant: CGFloat
}

struct TransferableConstantAnchor: TransferableLayout {
    let attribute: NSLayoutConstraint.Attribute
    var constant: CGFloat
    var relatedBy: NSLayoutConstraint.Relation
}
