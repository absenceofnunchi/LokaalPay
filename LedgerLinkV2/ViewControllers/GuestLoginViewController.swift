//
//  GuestLoginViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-13.
//

import UIKit

final class GuestLoginViewController: UIViewController, TopWarningPanel {
    private var backButton: UIButton!
    var passwordBlurView: BlurEffectContainerView!
    var passwordStatusLabel: UILabel!
    private var infoBoxView: UIView!
    private var passwordTextField: UITextField!
    private var passwordConfirmTextField: UITextField!
    private var buttonContainer: UIView!
    private var createButton: ButtonWithShadow!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tapToDismissKeyboard()
        configureUI()
        configureTopWarningPanel()
        setConstraints()
    }

    func configureUI() {
        view.backgroundColor = .black

        /// modal close button
        guard let buttonImage = UIImage(systemName: "multiply")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal) else { return }
        backButton = UIButton.systemButton(with: buttonImage, target: self, action: #selector(buttonPressed))
        backButton.tag = 0
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        passwordTextField = createTextField(placeHolderText: " Passcode", placeHolderImageString: "lock", isPassword: true, delegate: self)
        passwordTextField.keyboardType = .decimalPad
        
        passwordConfirmTextField = createTextField(placeHolderText: " Confirm Passcode", placeHolderImageString: "lock", isPassword: true, delegate: self)
        passwordConfirmTextField.keyboardType = .decimalPad
        
        infoBoxView = createInfoBoxView(title: "Account Information", subTitle: "Create 4 digit password for your wallet", arrangedSubviews: [passwordTextField, passwordConfirmTextField])
        infoBoxView.backgroundColor = .black
        view.addSubview(infoBoxView)
        
        buttonContainer = UIView()
        buttonContainer.tag = 4
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainer)
        
        createButton = ButtonWithShadow()
        createButton.setTitle("Create Event", for: .normal)
        createButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        createButton.tag = 1
        createButton.backgroundColor = .darkGray
        createButton.titleLabel?.font = UIFont.rounded(ofSize: 18, weight: .bold)
        buttonContainer.addSubview(createButton)
        createButton.setFill()
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            
            infoBoxView.topAnchor.constraint(equalTo: view.topAnchor, constant: 130),
            infoBoxView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            infoBoxView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            infoBoxView.heightAnchor.constraint(equalToConstant: 220),
            
            buttonContainer.topAnchor.constraint(equalTo: infoBoxView.bottomAnchor, constant: 40),
            buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            buttonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            buttonContainer.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    
    @objc final func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                dismiss(animated: true, completion: nil)
            case 1:
                createAccount()
            default:
                break
        }
    }
    
    private func createAccount() {
        guard isFieldValid(passwordTextField, alertMsg: "Event password cannot be empty") else {
            return
        }
        
        guard isNumber(passwordTextField, alertMsg: "The passcode has to be numerical") else {
            return
        }
        
        guard isFieldValid(passwordConfirmTextField, alertMsg: "Event password cannot be empty") else {
            return
        }
        
        guard isNumber(passwordConfirmTextField, alertMsg: "The passcode has to be numerical") else {
            return
        }
        
        guard let password = passwordTextField.text else {
            return
        }
        
        UserDefaults.standard.set(password, forKey: UserDefaultKey.walletPassword)
        passwordTextField.text = nil
        passwordConfirmTextField.text = nil
        
        let vc = EventsViewController()
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    /// The warning display for the inaccurate or incomplete info the in the form fields.
    /// Validates two form components: text field and text view
    private func isFieldValid(_ inputField: UIView, alertMsg: String, width: CGFloat = 250) -> Bool {
        if let textField = (inputField as? UITextField), let text = textField.text {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            /// Certain fields cannot be empty
            if trimmed.isEmpty {
                showAlert(alertMsg: alertMsg)
                return false
            }
        } else if let textView = (inputField as? UITextView) {
            /// If the text color is gray, then the field only contains the placeholder.  The placeholder text for text view is just a regular text with a different text color. Therefore, delete.
            if textView.textColor == UIColor.gray {
                textView.text = nil
            }
        }
        
        return true
    }
    
    /// The passcode fields have to be numerical.
    func isNumber(_ textField: UITextField, alertMsg: String) -> Bool {
        /// If the text fields are one of the 4, the content has to be numerical
        if textField.text!.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil {
            // string is a valid number
            return true
        } else {
            // string contained non-digit characters
            showAlert(alertMsg: alertMsg)
            return false
        }
    }
}

extension GuestLoginViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        createButton.isEnabled = false
        
        let yDelta = view.bounds.origin.y - passwordBlurView.frame.origin.y

        if (!(passwordTextField.text?.isEmpty ?? true) ||
            !(passwordConfirmTextField.text?.isEmpty ?? true)) &&
            passwordTextField.text != passwordConfirmTextField.text {
            passwordStatusLabel.isHidden = false
            passwordStatusLabel.text = "Passwords don't match"
            passwordTextField.textColor = UIColor.red
            passwordConfirmTextField.textColor = UIColor.red
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
            }
        } else if (!(passwordTextField.text?.isEmpty ?? true) ||
                   !(passwordConfirmTextField.text?.isEmpty ?? true)) &&
                    ((passwordTextField.text?.count)! != 4) {
            passwordStatusLabel.isHidden = false
            passwordStatusLabel.text = "Password has to be 4 digits"
            passwordConfirmTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
            }
        } else {
            passwordTextField.textColor = UIColor.lightGray
            passwordConfirmTextField.textColor = UIColor.lightGray

            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 0 : -100)
            }
            
            createButton.isEnabled = true
        }

        return true
    }
}

/// The transition delegate is located in the presenting VC instead of in a class of its own in order for the animation for dismiss delegate method to be called by it.
extension GuestLoginViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let forwardAnimator = IsolateAnimator(selectedTag: 1)
        return forwardAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BackwardAnimator(selectedTag: 1)
    }
}
