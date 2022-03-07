//
//  ActionSheetViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-07.
//

import UIKit

final class ActionSheetViewController: UIViewController {
    private var gradientView: GradientView!
    private var bgBlurView: BlurEffectContainerView!

    init() {
        
        super.init(nibName: nil, bundle: nil)
        self.transitioningDelegate = self
        if self.traitCollection.userInterfaceIdiom == .phone {
            self.modalPresentationStyle = .custom
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        setConstraints()
    }

    func configure() {
//        view.backgroundColor = .black
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        
//        gradientView = GradientView(colors: [UIColor.white.cgColor, UIColor.purple.cgColor, UIColor.blue.cgColor])
//        gradientView.layer.cornerRadius = 10
//        gradientView.clipsToBounds = true
//        gradientView.backgroundColor = .black
////        gradientView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(gradientView)
//        gradientView.setFill()
        
        bgBlurView = BlurEffectContainerView(blurStyle: .dark, effectViewAlpha: 0.8)
        view.addSubview(bgBlurView)
        view.setFill()
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            
        ])
    }
    
    @objc final func swiped() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ActionSheetViewController: UIViewControllerTransitioningDelegate {
    final func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = PartialPresentationController(presentedViewController: presented, presenting: presenting)
        return pc
    }
    
    final func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
