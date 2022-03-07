//
//  RegisterViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

class RegisterViewController: UIViewController {
    var backButton: UIButton!
    var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
    }
    
    func configureUI() {
        view.backgroundColor = .black
        
        guard let buttonImage = UIImage(systemName: "multiply")?.withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
        backButton = UIButton.systemButton(with: buttonImage, target: self, action: #selector(buttonPressed))
        backButton.tag = 0
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 30),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                dismiss(animated: true)
                break
            default:
                break
        }
    }
}
