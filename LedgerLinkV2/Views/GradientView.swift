//
//  GradientView.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-07.
//

import UIKit

class GradientView: UIView {
    var gradientLayer: CAGradientLayer!
    var gradientColors: [CGColor]! {
        didSet {
            gradientLayer.colors = gradientColors
        }
    }
    
    let newColors = [
        UIColor.purple.cgColor,
        UIColor.red.cgColor,
        UIColor.orange.cgColor
    ]
    
    convenience init(colors: [CGColor] = [UIColor.red.cgColor, UIColor.purple.cgColor, UIColor.cyan.cgColor], isAnimated: Bool = false) {
        self.init(frame: .zero, colors: colors, isAnimated: isAnimated)
    }
    
    init(frame: CGRect, colors: [CGColor], isAnimated: Bool) {
        super.init(frame: frame)
        
        gradientLayer = CAGradientLayer()
        gradientLayer.type = .axial
        gradientLayer.colors = gradientColors
        gradientLayer.shouldRasterize = true
        gradientLayer.locations = [0, 0.25, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.colors = colors
        
        if isAnimated {
            gradientLayer.setAnimatedColors(newColors,
                                            animated: true,
                                            withDuration: 5,
                                            timingFunctionName: .linear)
        }
        self.layer.addSublayer(gradientLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = self.bounds
    }
    
    func animate() {
        gradientLayer.setAnimatedColors(newColors,
                                        animated: true,
                                        withDuration: 5,
                                        timingFunctionName: .linear)
    }
}
