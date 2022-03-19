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
    var section: Section! {
        didSet {
            if section == .horizontal {
                setHorizontalConstraints()
            } else {
                setVerticalConstraints()
            }
        }
    }
    
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
        gradientView.alpha = 0.9
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradientView)
        gradientView.setFill()
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.addSubview(imageView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        gradientView.addSubview(titleLabel)
    }
    
    private func setHorizontalConstraints() {
        titleLabel.font = UIFont.rounded(ofSize: 15, weight: .bold)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
            imageView.heightAnchor.constraint(equalToConstant:40),
            imageView.widthAnchor.constraint(equalToConstant:40),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
        ])
    }
    
    private func setVerticalConstraints() {
        titleLabel.font = UIFont.rounded(ofSize: 12, weight: .bold)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 20),
            imageView.heightAnchor.constraint(equalToConstant:40),
            imageView.widthAnchor.constraint(equalToConstant:40),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 20),
        ])
    }
}

final class BalanceCell: UICollectionViewCell {
    let gradientView = GradientView()
    var colors: [CGColor] = [] {
        didSet {
            gradientView.gradientColors = colors
        }
    }
    let balanceLabel = UILabel()
    let titleLabel = UILabel()
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
        getBalance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

extension BalanceCell {
    func configure() {
        contentView.roundCorners(topLeft: radiusTopLeft, topRight: radiusTopRight, bottomLeft: radiusBottomLeft, bottomRight: radiusBottomRight)
        
        gradientView.clipsToBounds = true
        gradientView.alpha = 0.9
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradientView)
        gradientView.setFill()
        
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        balanceLabel.adjustsFontForContentSizeCategory = true
        balanceLabel.font = UIFont.rounded(ofSize: 22, weight: .bold)
        balanceLabel.textAlignment = .center
        balanceLabel.textColor = .white
        gradientView.addSubview(balanceLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = UIFont.rounded(ofSize: 15, weight: .bold)
        titleLabel.textAlignment = .center
        gradientView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
//            balanceLabel.topAnchor.constraint(equalTo: gradientView.topAnchor, constant: 20),
//            balanceLabel.leadingAnchor.constraint(equalTo: gradientView.leadingAnchor, constant: 20),
            balanceLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            balanceLabel.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
            balanceLabel.heightAnchor.constraint(equalToConstant:40),
            balanceLabel.widthAnchor.constraint(equalTo: gradientView.widthAnchor, multiplier: 0.7),
            
            titleLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
        ])
    }
    
    /// Get balance and the currency name
    func getBalance() {
        Node.shared.getMyAccount { (acct: Account?, error: NodeError?) in
            if let _ = error {
                return
            }
            
            if let acct = acct {
                
                Node.shared.localStorage.getBlock(Int32(0)) { [weak self] (block: FullBlock?, error: NodeError?) in
                    if let _ = error {
                        return
                    }
                    
                    if let block = block,
                       let extraData = block.extraData,
                       let eventInfo = try? JSONDecoder().decode(EventInfo.self, from: extraData) {
                        self?.balanceLabel.text = "\(acct.balance) \(eventInfo.currencyName)"
                    }
                }
            }
        }
    }
}
