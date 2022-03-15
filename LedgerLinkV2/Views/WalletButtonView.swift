//
//  WalletButtonView.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-14.
//

/*
 Abstract:
 Wallet button view for ReceiveVC
 */

import UIKit

class WalletButtonView: UIView {
    var image: UIImage!
    var labelName: String!
    var buttonAction: (()->Void)?
    var label: UILabel!
    var button: UIButton!
    var containerView = UIView()
    var bgColor: UIColor!
    var labelTextColor: UIColor!
    var imageTintColor: UIColor!
    
    init(imageName: String,
         labelName: String, bgColor: UIColor? = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1),
         labelTextColor: UIColor? = .white,
         imageTintColor: UIColor? = .white
    ) {
        super.init(frame: .zero)
        self.image = UIImage(systemName: imageName)?.withTintColor(imageTintColor!, renderingMode: .alwaysOriginal)
        self.labelName = labelName
        self.bgColor = bgColor
        self.labelTextColor = labelTextColor
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        configure()
        setConstraints()
    }
}

extension WalletButtonView {
    func configure() {
        containerView.backgroundColor = bgColor
        containerView.frame = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
        containerView.layer.cornerRadius = containerView.frame.size.width / 2
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(containerView)
        
        //add label and button
        button = UIButton.systemButton(with: image, target: self, action:  #selector(buttonTapped(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(button)
        
        label = UILabel()
        label.text = labelName
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = labelTextColor
        label.sizeToFit()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.5),
            containerView.widthAnchor.constraint(equalTo: containerView.heightAnchor),
            containerView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            containerView.topAnchor.constraint(equalTo: self.topAnchor),
            
            // button
            button.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            button.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.8),
            button.widthAnchor.constraint(equalTo: button.heightAnchor),
            
            // label
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.50),
            label.widthAnchor.constraint(equalTo: label.heightAnchor),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        if let buttonAction = self.buttonAction {
            buttonAction()
        }
    }
}
