//
//  RegisterViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

protocol ModalConfigrable {
    
}

class RegisterViewController: UIViewController {
    var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
        tapToDismissKeyboard()
    }

    func configureUI() {
        view.backgroundColor = .black
        
        guard let buttonImage = UIImage(systemName: "multiply")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal) else { return }
        backButton = UIButton.systemButton(with: buttonImage, target: self, action: #selector(buttonPressed))
        backButton.tag = 5
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            backButton.widthAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 5:
                dismiss(animated: true)
                break
            default:
                break
        }
    }
    
//    func getContentSizeHeight() -> CGFloat {
//        return backButton.bounds.size.height
//    }
}
