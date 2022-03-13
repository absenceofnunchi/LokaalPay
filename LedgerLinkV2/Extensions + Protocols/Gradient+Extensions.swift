//
//  Gradient+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-07.
//

import UIKit

extension CAGradientLayer {
    
    func setAnimatedColors(_ newColors: [CGColor],
                           animated: Bool = true,
                           withDuration duration: TimeInterval = 0,
                           timingFunctionName name: CAMediaTimingFunctionName? = nil) {
        
        if !animated {
            self.colors = newColors
            return
        }
        
        let colorAnimation = CABasicAnimation(keyPath: "colors")
        colorAnimation.fromValue = colors
        colorAnimation.toValue = newColors
        colorAnimation.duration = duration
        colorAnimation.isRemovedOnCompletion = false
        colorAnimation.fillMode = CAMediaTimingFillMode.forwards
        colorAnimation.repeatDuration = .greatestFiniteMagnitude
        colorAnimation.timingFunction = CAMediaTimingFunction(name: name ?? .linear)
        colorAnimation.autoreverses = true
        
        add(colorAnimation, forKey: "colorsChangeAnimation")
    }
}
