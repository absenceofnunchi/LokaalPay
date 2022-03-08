//
//  ButtonWithShadow.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-07.
//

/*
 Abstract:
 Button with a dropshadow. Requires it to be embedded in a container view.
 */

import UIKit.UIButton

class ButtonWithShadow: UIButton {
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted == true {
                guard let superview = self.superview else { return }
                superview.layer.shadowRadius = 0
                superview.layer.shadowOffset = .zero
                superview.layer.shadowColor = .none
                superview.layer.shadowOpacity = 0
                
                UIView.animate(withDuration: 0.2) { [weak self] in
                    self?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
            } else {
                UIView.animate(withDuration: 0.2) { [weak self] in
                    self?.transform = .identity
                    guard let self = self,
                          let superview = self.superview else { return }
                    superview.layer.shadowRadius = 2
                    superview.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
                    superview.layer.shadowColor = UIColor.gray.cgColor
                    superview.layer.shadowOpacity = 1.0
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        updateLayerProperties()
    }
    
    override var intrinsicContentSize : CGSize {
        return super.intrinsicContentSize.withDelta(dw:25, dh: 20)
    }
    
    override func backgroundImage(for state: UIControl.State) -> UIImage? {
        return UIImage()
    }
    
    override func backgroundRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.backgroundRect(forBounds:bounds)
        if self.isHighlighted {
            result = result.insetBy(dx: 100, dy: 100)
        }
        return result
    }
    
    func updateLayerProperties() {
        layer.masksToBounds = true
        layer.cornerRadius = 12.0
        
        //superview is your optional embedding UIView
        if let superview = superview {
            superview.backgroundColor = UIColor.clear
            superview.layer.shadowColor = UIColor.gray.cgColor
            superview.layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12.0).cgPath
            superview.layer.shadowOffset = CGSize(width: 2.0, height: 2.0)
            superview.layer.shadowOpacity = 1.0
            superview.layer.shadowRadius = 2
            superview.layer.masksToBounds = true
            superview.clipsToBounds = false
        }
    }
}

extension CGSize {
    func withDelta(dw:CGFloat, dh:CGFloat) -> CGSize {
        return CGSize(width: self.width + dw, height: self.height + dh)
    }
}
