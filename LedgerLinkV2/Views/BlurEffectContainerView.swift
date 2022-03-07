//
//  BlurEffectContainerView.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-07.
//

import UIKit

class BlurEffectContainerView: UIView {
    convenience init(blurStyle: UIBlurEffect.Style, effectViewAlpha: CGFloat? = nil) {
        self.init(frame: .zero, blurStyle: blurStyle, effectViewAlpha: effectViewAlpha)
    }
    
    init(frame: CGRect, blurStyle: UIBlurEffect.Style, effectViewAlpha: CGFloat? = nil) {
        super.init(frame: frame)
        
        configure(blurStyle: blurStyle, effectViewAlpha: effectViewAlpha)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(blurStyle: UIBlurEffect.Style = UIBlurEffect.Style.light, effectViewAlpha: CGFloat? = nil) {
        // layer
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = 6
        
        // blur effect
        let blurEffect = UIBlurEffect(style: blurStyle)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        if let vfxSubView = blurEffectView.subviews.first(where: { String(describing: type(of: $0)) == "_UIVisualEffectSubview" }),
           let effectViewAlpha = effectViewAlpha {
            vfxSubView.backgroundColor = UIColor.black.withAlphaComponent(effectViewAlpha)
        }
        blurEffectView.frame = self.bounds
//        blurEffectView.layer.cornerRadius = 20
        blurEffectView.clipsToBounds = true
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(blurEffectView)
    }
}
