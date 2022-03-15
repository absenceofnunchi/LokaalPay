//
//  WalletModalViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-13.
//

/*
 Abstract:
 ParentVC for Send and Receive VC
 */

import UIKit

class WalletModalViewController: UIViewController {
    var dismissButton: DownArrow!
    var titleLabel: UILabel!
    var lineView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tapToDismissKeyboard()
        configureUI()
        setConstraints()
    }
    
    func configureUI() {
        view.backgroundColor = .black
        
        dismissButton = DownArrow(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 50)))
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dismissButton)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        dismissButton.addGestureRecognizer(tap)
        
        titleLabel = createLabel(text: "")
        titleLabel.font = UIFont.rounded(ofSize: 20, weight: .bold)
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        view.addSubview(titleLabel)
        
        lineView = UIView()
        lineView.alpha = 0
        lineView.transform = CGAffineTransform(translationX: 0, y: 40)
        lineView.layer.borderColor = UIColor.darkGray.cgColor
        lineView.layer.borderWidth = 0.5
        lineView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dismissButton.widthAnchor.constraint(equalToConstant: 50),
            dismissButton.heightAnchor.constraint(equalToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: dismissButton.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            lineView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            lineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            lineView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            lineView.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
    
    
    @objc func tapped(_ sender: UIGestureRecognizer) {
        dismiss(animated: true)
    }
}

final class DownArrow: UIView {
    init() {
        super.init(frame: .zero)
        self.createArrow()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.createArrow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createArrow() {
        let arrowPath = UIBezierPath()
        arrowPath.move(to: .zero)
        arrowPath.addLine(to: CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2))
        arrowPath.addLine(to: CGPoint(x: self.bounds.size.width, y: 0))
        
        let arrowLayer = CAShapeLayer()
        arrowLayer.path = arrowPath.cgPath
        arrowLayer.fillColor = UIColor.clear.cgColor
        arrowLayer.strokeColor = UIColor.lightGray.cgColor
        arrowLayer.lineWidth = 2
        arrowLayer.opacity = 0.5
        arrowLayer.lineCap = .round
        
        self.layer.addSublayer(arrowLayer)
    }
}
