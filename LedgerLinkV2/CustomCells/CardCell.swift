//
//  CardCell.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-10.
//

/*
 Abstract:
 Menu for WalletVC.
 */

import UIKit

final class CardCell: UICollectionViewCell {
    let gradientView = GradientView()
    var colors: [CGColor] = [] {
        didSet {
            gradientView.gradientColors = colors
        }
    }
    let titleLabel = UILabel()
    let imageView = UIImageView()
    var radiusTopLeft: CGFloat = 20 {
        didSet {
            contentView.roundCorners(topLeft: radiusTopLeft, topRight: radiusTopRight, bottomLeft: radiusBottomLeft, bottomRight: radiusBottomRight)
        }
    }
    
    var radiusTopRight: CGFloat = 20 {
        didSet {
            contentView.roundCorners(topLeft: radiusTopLeft, topRight: radiusTopRight, bottomLeft: radiusBottomLeft, bottomRight: radiusBottomRight)
        }
    }
    
    var radiusBottomLeft: CGFloat = 20 {
        didSet {
            contentView.roundCorners(topLeft: radiusTopLeft, topRight: radiusTopRight, bottomLeft: radiusBottomLeft, bottomRight: radiusBottomRight)
        }
    }
    
    var radiusBottomRight: CGFloat = 20 {
        didSet {
            contentView.roundCorners(topLeft: radiusTopLeft, topRight: radiusTopRight, bottomLeft: radiusBottomLeft, bottomRight: radiusBottomRight)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension CardCell {
    func configure() {
        contentView.roundCorners(topLeft: radiusTopLeft, topRight: radiusTopRight, bottomLeft: radiusBottomLeft, bottomRight: radiusBottomRight)
        
        gradientView.clipsToBounds = true
        gradientView.alpha = 0.7
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradientView)
        gradientView.setFill()
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.addSubview(imageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.rounded(ofSize: 13, weight: .bold)
        titleLabel.textAlignment = .center
        gradientView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            //            imageView.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            //            imageView.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor, constant: -20),
            //            imageView.heightAnchor.constraint(equalToConstant:40),
            //            imageView.widthAnchor.constraint(equalToConstant:40),
            
            //            titleLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            //            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            //            titleLabel.widthAnchor.constraint(equalTo: gradientView.widthAnchor),
            
            imageView.topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 20),
            imageView.heightAnchor.constraint(equalToConstant:40),
            imageView.widthAnchor.constraint(equalToConstant:40),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 20),
            //            titleLabel.widthAnchor.constraint(equalTo: gradientView.widthAnchor),
        ])
    }
}
