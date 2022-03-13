//
//  Font+Extensions.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

// MARK: - UIFont
extension UIFont {
    class func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let font: UIFont
        
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: descriptor, size: size)
        } else {
            font = systemFont
        }
        return font
    }
}

extension UITextField {
    func leftPadding(_ paddingWidth: CGFloat = 10) {
        self.leftView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: paddingWidth, height: self.bounds.size.height)))
        self.leftViewMode = .always
    }
}
