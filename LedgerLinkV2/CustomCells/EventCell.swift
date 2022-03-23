//
//  EventCell.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-10.
//

import UIKit

final class EventCell: UICollectionViewCell {
    static let identifier = "reuse-eventCell-identifier"
    
    let containerView = UIView()
    let eventImageView = UIImageView()
    let gradientView = GradientView()
    let nameTitleLabel = UILabel()
    let nameLabel = UILabel()
    let currencyTitleLabel = UILabel()
    let currencyLabel = UILabel()
    let descTitleLabel = UILabel()
    let descTextView = UITextView()
    
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
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    func configure() {
        
        self.backgroundColor = .black
        
        containerView.backgroundColor = .clear
        containerView.layer.borderColor = UIColor.gray.cgColor
        containerView.layer.borderWidth = 0.5
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        eventImageView.contentMode = .scaleAspectFill
        eventImageView.clipsToBounds = true
        eventImageView.layer.cornerRadius = 0
//        eventImageView.clipsToBounds = true
        eventImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(eventImageView)
        
        gradientView.layer.cornerRadius = 0
//        gradientView.clipsToBounds = true
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        eventImageView.addSubview(gradientView)
        
        nameTitleLabel.text = "Event Name"
        nameTitleLabel.font = UIFont.rounded(ofSize: 12, weight: .bold)
        nameTitleLabel.textColor = .darkGray
        nameTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameTitleLabel)
        
        nameLabel.textColor = .lightGray
        nameLabel.backgroundColor = .black
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        currencyTitleLabel.text = "Currency"
        currencyTitleLabel.textColor = .darkGray
        currencyTitleLabel.font = UIFont.rounded(ofSize: 12, weight: .bold)
        currencyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(currencyTitleLabel)
        
        currencyLabel.textColor = .lightGray
        currencyLabel.backgroundColor = .black
        currencyLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(currencyLabel)
        
        descTitleLabel.text = "Description"
        descTitleLabel.textColor = .darkGray
        descTitleLabel.font = UIFont.rounded(ofSize: 12, weight: .bold)
        descTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descTitleLabel)
        
        descTextView.textColor = .lightGray
        descTextView.backgroundColor = .black
        descTextView.isEditable = false
        descTextView.isScrollEnabled = true
        descTextView.clipsToBounds = true
        descTextView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descTextView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            eventImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            eventImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            eventImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            eventImageView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.45),
            
            gradientView.topAnchor.constraint(equalTo: containerView.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 0),
            gradientView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 0),
            gradientView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.45),

            nameTitleLabel.topAnchor.constraint(equalTo: eventImageView.bottomAnchor, constant: 10),
            nameTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            nameTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            nameTitleLabel.heightAnchor.constraint(equalToConstant: 22),
            
            nameLabel.topAnchor.constraint(equalTo: nameTitleLabel.bottomAnchor, constant: 0),
            nameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            nameLabel.heightAnchor.constraint(equalToConstant: 30),
            
            currencyTitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            currencyTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            currencyTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            currencyTitleLabel.heightAnchor.constraint(equalToConstant: 22),
            
            currencyLabel.topAnchor.constraint(equalTo: currencyTitleLabel.bottomAnchor, constant: 0),
            currencyLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            currencyLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            currencyLabel.heightAnchor.constraint(equalToConstant: 30),
            
            descTitleLabel.topAnchor.constraint(equalTo: currencyLabel.bottomAnchor, constant: 10),
            descTitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            descTitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            descTitleLabel.heightAnchor.constraint(equalToConstant: 22),
            
            descTextView.topAnchor.constraint(equalTo: descTitleLabel.bottomAnchor, constant: 0),
            descTextView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            descTextView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            descTextView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
        ])
    }
    
    func set(eventInfo: EventInfo) {
        if let image = eventInfo.image {
            eventImageView.image = UIImage(data: image)
            gradientView.alpha = 0
        }
        
        nameLabel.text = eventInfo.eventName
        currencyLabel.text = eventInfo.currencyName
        descTextView.text = eventInfo.description
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        eventImageView.image = nil
        nameLabel.text = nil
        currencyLabel.text = nil
        descTextView.text = nil
    }
}
