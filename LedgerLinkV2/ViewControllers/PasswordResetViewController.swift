//
//  PasswordResetViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-14.
//

/*
 Abstract:
 Password reset for wallet
 */

import UIKit

class PasswordResetViewController: UIViewController {
    var titleString: String?
    private var titleLabel: UILabel!
    private var messageLabel: UILabel!
    private var height: CGFloat!
    var buttonAction: ((UIViewController)->Void)?
    private var buttonPanel: UIView!
    private var closeButton: UIButton!
    private var cancelButton: UIButton!
    var currentPasswordTextField: UITextField!
    var passwordTextField: UITextField!
    var repeatPasswordTextField: UITextField!
    private var passwordsDontMatch: UILabel!
    private var textFields = [UITextField]()
    private lazy var customTransitioningDelegate = PopupTransitioningDelegate(height: height)
    
    init(height: CGFloat = 410, buttonTitle: String = "OK", messageTextAlignment: NSTextAlignment = .center) {
        super.init(nibName: nil, bundle: nil)
        
        self.height = height
        
        self.closeButton = UIButton()
        self.closeButton.setTitle(buttonTitle, for: .normal)
        
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("fatal error")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setConstraints()
    }
    
    override func loadView() {
        view = BlurEffectContainerView(blurStyle: .light)
    }
}

private extension PasswordResetViewController {
    func configure() {
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        transitioningDelegate = customTransitioningDelegate
    }
    
    func configureUI() {
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        
        // passwords don't match label
        passwordsDontMatch = UILabel()
        passwordsDontMatch.textColor = .red
        passwordsDontMatch.translatesAutoresizingMaskIntoConstraints = false
        passwordsDontMatch.isHidden = true
        view.addSubview(passwordsDontMatch)
        
        titleLabel = UILabel()
        titleLabel.textColor = .lightGray
        titleLabel.text = titleString
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        messageLabel = UILabel()
        messageLabel.textColor = .lightGray
        messageLabel.text = "Minimum 4 digits"
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        
        // current password
        currentPasswordTextField = UITextField()
        currentPasswordTextField.delegate = self
        currentPasswordTextField.clipsToBounds = true
        currentPasswordTextField.keyboardType = .decimalPad
        currentPasswordTextField.isSecureTextEntry = true
        currentPasswordTextField.attributedPlaceholder = createAttributedString(imageString: "lock", imageColor: .lightGray, text: "Current passcode")
        currentPasswordTextField.autocapitalizationType = .none
        currentPasswordTextField.leftPadding(10)
        currentPasswordTextField.layer.borderWidth = 0.7
        currentPasswordTextField.layer.cornerRadius = 10
        currentPasswordTextField.layer.borderColor = UIColor.lightGray.cgColor
        textFields.append(currentPasswordTextField)
        currentPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentPasswordTextField)
        
        // new password
        passwordTextField = UITextField()
        passwordTextField.isSecureTextEntry = true
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.clipsToBounds = true
        passwordTextField.keyboardType = .decimalPad
        passwordTextField.delegate = self
        passwordTextField.attributedPlaceholder = createAttributedString(imageString: "lock", imageColor: .lightGray, text:  "New passscode")
        passwordTextField.autocapitalizationType = .none
        passwordTextField.leftPadding(10)
        passwordTextField.layer.borderWidth = 0.7
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.layer.borderColor = UIColor.lightGray.cgColor
        textFields.append(passwordTextField)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordTextField)
        
        repeatPasswordTextField = UITextField()
        repeatPasswordTextField.isSecureTextEntry = true
        repeatPasswordTextField.layer.cornerRadius = 10
        repeatPasswordTextField.clipsToBounds = true
        repeatPasswordTextField.keyboardType = .decimalPad
        repeatPasswordTextField.delegate = self
        repeatPasswordTextField.attributedPlaceholder = createAttributedString(imageString: "lock", imageColor: .lightGray, text:  "New passscode again")
        repeatPasswordTextField.autocapitalizationType = .none
        repeatPasswordTextField.leftPadding(10)
        repeatPasswordTextField.layer.borderWidth = 0.7
        repeatPasswordTextField.layer.cornerRadius = 10
        repeatPasswordTextField.layer.borderColor = UIColor.lightGray.cgColor
        textFields.append(repeatPasswordTextField)
        repeatPasswordTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(repeatPasswordTextField)
        
        buttonPanel = UIView()
        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonPanel)
        
        closeButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        closeButton.isEnabled = false
        closeButton.backgroundColor = .black
        closeButton.layer.cornerRadius = 10
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(closeButton)
        
        cancelButton = UIButton()
        cancelButton.backgroundColor = .gray
        cancelButton.setTitleColor(UIColor.darkGray, for: .normal)
        cancelButton.layer.cornerRadius = 10
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelHandler), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        buttonPanel.addSubview(cancelButton)
    }
    
    func setConstraints() {
        var constraints = [NSLayoutConstraint]()
        
        constraints.append(contentsOf: [
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            messageLabel.heightAnchor.constraint(equalToConstant: 30),
            
            currentPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            currentPasswordTextField.bottomAnchor.constraint(equalTo: passwordTextField.topAnchor, constant: -20),
            currentPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            passwordTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            repeatPasswordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            repeatPasswordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            repeatPasswordTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            repeatPasswordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordsDontMatch.topAnchor.constraint(equalTo: repeatPasswordTextField.bottomAnchor, constant: 5),
            passwordsDontMatch.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordsDontMatch.widthAnchor.constraint(equalToConstant: 200),
            passwordsDontMatch.heightAnchor.constraint(equalToConstant: 50),
            
            buttonPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            buttonPanel.heightAnchor.constraint(equalToConstant: 50),
            
            closeButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            closeButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
            closeButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
            
            cancelButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
            cancelButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
        ])
        
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func tapped() {
        if let buttonAction = self.buttonAction {
            buttonAction(self)
        }
    }
    
    @objc func cancelHandler() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension PasswordResetViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.returnKeyType = closeButton.isEnabled ? UIReturnKeyType.done : .next
        textField.textColor = UIColor.orange
        if textField == passwordTextField || textField == repeatPasswordTextField {
            passwordsDontMatch.isHidden = true
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.textColor = UIColor.darkGray
        
        guard textField == repeatPasswordTextField ||
                textField == passwordTextField else {
                    return true
                }
        
        if (!(passwordTextField.text?.isEmpty ?? true) ||
            !(repeatPasswordTextField.text?.isEmpty ?? true)) &&
            passwordTextField.text != repeatPasswordTextField.text {
            passwordsDontMatch.isHidden = false
            passwordsDontMatch.text = "Passwords don't match"
            repeatPasswordTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
        } else if (!(passwordTextField.text?.isEmpty ?? true) ||
                   !(repeatPasswordTextField.text?.isEmpty ?? true)) &&
                    ((passwordTextField.text?.count)! < 4) {
            passwordsDontMatch.isHidden = false
            passwordsDontMatch.text = "Password is too short"
            repeatPasswordTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
        } else {
            repeatPasswordTextField.textColor = UIColor.darkGray
            passwordTextField.textColor = UIColor.darkGray
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .done && closeButton.isEnabled && ((passwordTextField.text?.count)! > 4) {
            print("account created")
        } else if textField.returnKeyType == .next {
            let index = textFields.firstIndex(of: textField) ?? 0
            let nextIndex = (index == textFields.count - 1) ? 0 : index + 1
            textFields[nextIndex].becomeFirstResponder()
        } else {
            view.endEditing(true)
        }
        return true
    }
}
