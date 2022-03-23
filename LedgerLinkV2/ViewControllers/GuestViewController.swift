//
//  GuestViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-19.
//

/*
 ParentVC for GuestLoginVC and GuestImportVC
 
 */

import UIKit

class GuestViewController: UIViewController, TopWarningPanel, UITextFieldDelegate {
    private var backButton: UIButton!
    var passwordBlurView: BlurEffectContainerView!
    var passwordStatusLabel: UILabel!
    var infoBoxView: UIView!
    var passwordTextField: UITextField!
    var passwordConfirmTextField: UITextField!
    var buttonContainer: UIView!
    var createButton: ButtonWithShadow!
    var importButton: UIButton!
    let dissolveAnimator = DissolveTransitionAnimator()
    private var presentingController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tapToDismissKeyboard()
        configureUI()
        configureTopWarningPanel()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentingController = presentingViewController
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
        
        infoBoxView = createInfoBoxView(title: "Account Information", subTitle: "4 digit password required", arrangedSubviews: [passwordTextField, passwordConfirmTextField])
        infoBoxView.backgroundColor = .black
        view.addSubview(infoBoxView)
        
        buttonContainer = UIView()
        buttonContainer.tag = 4
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainer)
        
        createButton = ButtonWithShadow()
        createButton.setTitle("Create Account", for: .normal)
        createButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        createButton.tag = 1
        createButton.backgroundColor = .darkGray
        createButton.titleLabel?.font = UIFont.rounded(ofSize: 18, weight: .bold)
        buttonContainer.addSubview(createButton)
        createButton.setFill()
        
        importButton = UIButton()
        importButton.tag = 2
        importButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        let attTitle = createAttributedString(imageString: nil, imageColor: nil, text: "Already have an account")
        importButton.setAttributedTitle(attTitle, for: .normal)
        importButton.titleLabel?.textAlignment = .right
        importButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(importButton)
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
            
            importButton.topAnchor.constraint(equalTo: buttonContainer.bottomAnchor, constant: 15),
            buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            importButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            importButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    
    @objc func buttonPressed(_ sender: UIButton) {

    }
    
    func goToImportAccount() {
        let vc = GuestImportViewController()
        // this allows the custom transition animator's fromView and fromVC to be the current one and not UITabBarVC
        vc.transitioningDelegate = dissolveAnimator
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    /// The warning display for the inaccurate or incomplete info the in the form fields.
    /// Validates two form components: text field and text view
    func isFieldValid(_ inputField: UIView, alertMsg: String, width: CGFloat = 250) -> Bool {
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

/// The transition delegate is located in the presenting VC instead of in a class of its own in order for the animation for dismiss delegate method to be called by it.
extension GuestViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let forwardAnimator = IsolateAnimator(selectedTag: 1)
        return forwardAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BackwardAnimator(selectedTag: 1)
    }
}
