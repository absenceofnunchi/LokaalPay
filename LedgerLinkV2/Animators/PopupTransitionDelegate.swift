//
//  PopupTransitionDelegate.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-12.
//

import UIKit

class PopupTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    var height: CGFloat!
    
    init(height: CGFloat = 300) {
        self.height = height
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting, height: height)
    }
}
