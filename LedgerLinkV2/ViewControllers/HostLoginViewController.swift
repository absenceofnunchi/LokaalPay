//
//  HostLoginViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

/*
 Abstract:
 For a host to create an event.
 It requires the name of the event, the description, an optional image, and the password.  The password will be used by the guests as the Chain ID for the blockchain.
 Lastly, it also requires the password for the host's account.
 */

import UIKit

final class HostLoginViewController: UIViewController {
    var scrollView: UIScrollView!
    var backButton: UIButton!

    /// Image upload
    private var imageTitleLabel: UILabel!
    private var imageSubtitleLabel: UILabel!
    private var gradientView: GradientView!
    private var imageButton: UIButton!
    private var imageBlurView: BlurEffectContainerView!
    private var imageSymbolView: UIImageView!
    
    /// Event name and password
    private var eventNameTextField: UITextField!
    private var currencyNameTextField: UITextField!
    private var generalInfoBoxView: UIView!
    private var hostInfoBoxView: UIView!
    private var passwordTextField: UITextField!
    private var passwordConfirmTextField: UITextField!
    private var descriptionTextView: UITextView!
    private var personalPasswordTextField: UITextField!
    private var personalPasswordConfirmTextField: UITextField!
    
    /// create event button
    private var passwordStatusLabel: UILabel!
    private var buttonGradientView: GradientView!
    private var createButton: UIButton!
    private var buttonContainer: UIView!
    private var passwordBlurView: BlurEffectContainerView!
    private var selectedTag: Int! /// For passsing the tag of the button to the custom transition animator
    private var alert: AlertView!
    private var imageData: Data!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addKeyboardObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //        let contentRect: CGRect = view.subviews.reduce(into: .zero, { rect, view in
        //            rect = rect.union(view.frame)
        //        })
        //        print("contentRect", contentRect)
        //        scrollView.contentSize = contentRect.size
        
        let height = getContentSizeHeight()
        scrollView.contentSize = CGSize(width: view.bounds.size.width, height: height)
    }
    
    final func configureUI() {
        
        view.backgroundColor = .black
        tapToDismissKeyboard()
        alert = AlertView()
        
        scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.setFill()
        
        guard let buttonImage = UIImage(systemName: "multiply")?.withTintColor(.lightGray, renderingMode: .alwaysOriginal) else { return }
        backButton = UIButton.systemButton(with: buttonImage, target: self, action: #selector(buttonPressed))
        backButton.tag = 5
        backButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(backButton)
        
        /// Image upload button
        imageTitleLabel = UILabel()
        imageTitleLabel.text = "Create Event"
        imageTitleLabel.font = UIFont.rounded(ofSize: 25, weight: .bold)
        imageTitleLabel.textColor = .lightGray
        imageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageTitleLabel)

        imageSubtitleLabel = UILabel()
        imageSubtitleLabel.text = "Event info and a passcode for your guests!"
        imageSubtitleLabel.font = UIFont.rounded(ofSize: 15, weight: .bold)
        imageSubtitleLabel.textColor = .lightGray
        imageSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageSubtitleLabel)

        gradientView = GradientView()
        gradientView.layer.cornerRadius = 10
        gradientView.clipsToBounds = true
        gradientView.translatesAutoresizingMaskIntoConstraints = false

        imageBlurView = BlurEffectContainerView(blurStyle: .regular)
        imageBlurView.isUserInteractionEnabled = false
        gradientView.addSubview(imageBlurView)
        imageBlurView.setFill()

        guard let imageSymbol = UIImage(systemName: "photo")?.withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
        imageSymbolView = UIImageView(image: imageSymbol)
        imageSymbolView.contentMode = .scaleAspectFill
        imageSymbolView.translatesAutoresizingMaskIntoConstraints = false
        imageBlurView.addSubview(imageSymbolView)

        imageButton = UIButton()
        imageButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        imageButton.tag = 1
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageButton)
        imageButton.addSubview(gradientView)
        gradientView.setFill()
        gradientView.sendSubviewToBack(gradientView)
        gradientView.isUserInteractionEnabled = false
        
        eventNameTextField = createTextField(placeHolderText: " Event Name", placeHolderImageString: "square.stack.3d.down.forward")
        eventNameTextField.delegate = self
        eventNameTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        currencyNameTextField = createTextField(placeHolderText: " Currency Name", placeHolderImageString: "creditcard")
        currencyNameTextField.delegate = self
        currencyNameTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        passwordTextField = createTextField(placeHolderText: " Passcode", placeHolderImageString: "lock", isPassword: true)
        passwordTextField.keyboardType = .decimalPad
        passwordTextField.delegate = self
        passwordTextField.tag = 100
        passwordTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        passwordConfirmTextField = createTextField(placeHolderText: " Confirm Passcode", placeHolderImageString: "lock", isPassword: true)
        passwordConfirmTextField.keyboardType = .decimalPad
        passwordConfirmTextField.delegate = self
        passwordConfirmTextField.tag = 101
        passwordConfirmTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        descriptionTextView = createTextView(placeHolderText: " Briefly describe your event", placeHolderImageString: "doc.append")
        descriptionTextView.delegate = self
        descriptionTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        generalInfoBoxView = createInfoBoxView(title: "General Information", subTitle: "To share with your guests", arrangedSubviews: [eventNameTextField, currencyNameTextField, passwordTextField, passwordConfirmTextField, descriptionTextView])
        scrollView.addSubview(generalInfoBoxView)
//
        personalPasswordTextField = createTextField(placeHolderText: " Passcode", placeHolderImageString: "lock", isPassword: true)
        personalPasswordTextField.keyboardType = .decimalPad
        personalPasswordTextField.delegate = self
        personalPasswordTextField.tag = 102
        personalPasswordTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        personalPasswordConfirmTextField = createTextField(placeHolderText: " Confirm Passcode", placeHolderImageString: "lock", isPassword: true)
        personalPasswordConfirmTextField.keyboardType = .decimalPad
        personalPasswordConfirmTextField.delegate = self
        personalPasswordConfirmTextField.tag = 103
        personalPasswordConfirmTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true

        hostInfoBoxView = createInfoBoxView(title: "Host Account", subTitle: "For the host only", arrangedSubviews: [personalPasswordTextField, personalPasswordConfirmTextField])
        scrollView.addSubview(hostInfoBoxView)

        passwordBlurView = BlurEffectContainerView(blurStyle: .regular)
        passwordBlurView.frame = CGRect(origin: CGPoint(x: view.bounds.origin.x, y: view.bounds.origin.y), size: CGSize(width: view.bounds.size.width, height: 100))
        passwordBlurView.transform = CGAffineTransform(translationX: 0, y: -100)
        view.addSubview(passwordBlurView)

        passwordStatusLabel = createLabel(text: "")
        passwordStatusLabel.textAlignment = .center
        passwordStatusLabel.backgroundColor = .clear
        passwordStatusLabel.font = UIFont.rounded(ofSize: 14, weight: .regular)
        passwordStatusLabel.textColor = UIColor.red
        passwordStatusLabel.isHidden = true
        passwordBlurView.addSubview(passwordStatusLabel)

        buttonContainer = UIView()
        buttonContainer.tag = 4
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(buttonContainer)

        buttonGradientView = GradientView()
        buttonGradientView.layer.cornerRadius = 10
        buttonGradientView.clipsToBounds = true
        buttonGradientView.isUserInteractionEnabled = false
        buttonGradientView.alpha = 0

        createButton = ButtonWithShadow()
        createButton.setTitle("Create Event", for: .normal)
        createButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        createButton.tag = 4
        createButton.backgroundColor = .darkGray
        createButton.addSubview(buttonGradientView)
        createButton.sendSubviewToBack(buttonGradientView)
        createButton.titleLabel?.font = UIFont.rounded(ofSize: 18, weight: .bold)
        buttonContainer.addSubview(createButton)
        buttonGradientView.setFill()
        createButton.setFill()
    }
    
    final func setConstraints() {
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 50),
            backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            backButton.widthAnchor.constraint(equalToConstant: 50),
            
            imageTitleLabel.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 100),
            imageTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            imageTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            imageTitleLabel.heightAnchor.constraint(equalToConstant: 30),

            imageSubtitleLabel.topAnchor.constraint(equalTo: imageTitleLabel.bottomAnchor, constant: 0),
            imageSubtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            imageSubtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            imageSubtitleLabel.heightAnchor.constraint(equalToConstant: 40),

            imageSymbolView.centerXAnchor.constraint(equalTo: imageBlurView.centerXAnchor),
            imageSymbolView.centerYAnchor.constraint(equalTo: imageBlurView.centerYAnchor),
            imageSymbolView.widthAnchor.constraint(equalToConstant: 50),
            imageSymbolView.heightAnchor.constraint(equalToConstant: 50),

            imageButton.topAnchor.constraint(equalTo: imageSubtitleLabel.bottomAnchor, constant: 20),
            imageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            imageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            imageButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
            
            generalInfoBoxView.topAnchor.constraint(equalTo: imageButton.bottomAnchor, constant: 40),
            generalInfoBoxView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            generalInfoBoxView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            generalInfoBoxView.heightAnchor.constraint(equalToConstant: 470),

            hostInfoBoxView.topAnchor.constraint(equalTo: generalInfoBoxView.bottomAnchor, constant: 40),
            hostInfoBoxView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            hostInfoBoxView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            hostInfoBoxView.heightAnchor.constraint(equalToConstant: 210),

            passwordStatusLabel.bottomAnchor.constraint(equalTo: passwordBlurView.bottomAnchor, constant: 0),
            passwordStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            passwordStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            passwordStatusLabel.heightAnchor.constraint(equalToConstant: 50),

            buttonContainer.topAnchor.constraint(equalTo: hostInfoBoxView.bottomAnchor, constant: 40),
            buttonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            buttonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            buttonContainer.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    
    func getContentSizeHeight() -> CGFloat {
        return backButton.bounds.size.height
        + imageTitleLabel.bounds.size.height
        + imageSubtitleLabel.bounds.size.height
        + imageButton.bounds.size.height
        + generalInfoBoxView.bounds.size.height
        + hostInfoBoxView.bounds.size.height
        + buttonContainer.bounds.size.height
        + 250
    }
    
    @objc final func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 1:
                /// Prompt user for camera or gallery to upload an image
                let buttonInfoArr = [
                    ButtonInfo(title: "Camera", tag: 2, backgroundColor: .black),
                    ButtonInfo(title: "Gallery", tag: 3, backgroundColor: .black)
                ]
                
                let alertVC = ActionSheetViewController(content: .button(buttonInfoArr))
                alertVC.buttonAction = { [weak self] tag in
                    self?.dismiss(animated: true, completion: {
                        switch tag {
                            case 2:
                                let pickerVC = UIImagePickerController()
                                pickerVC.sourceType = .camera
                                pickerVC.allowsEditing = true
                                pickerVC.delegate = self
                                self?.present(pickerVC, animated: true)
                                break
                            case 3:
                                let pickerVC = UIImagePickerController()
                                pickerVC.sourceType = .photoLibrary
                                pickerVC.allowsEditing = true
                                pickerVC.delegate = self
                                self?.present(pickerVC, animated: true)
                            default:
                                break
                        }
                    })
                }
                present(alertVC, animated: true)
            case 4:
                /// Validate the fields
                /// The fields cannot be empty
//                guard isFieldValid(eventNameTextField, alertMsg: "Event name cannot be empty.") else {
//                    return
//                }
//
//                guard isFieldValid(currencyNameTextField, alertMsg: "Currency name cannot be empty") else {
//                    return
//                }
//
//                guard isFieldValid(passwordTextField, alertMsg: "Event password cannot be empty") else {
//                    return
//                }
//
//                guard isNumber(passwordTextField, alertMsg: "The passcode has to be numerical") else {
//                    return
//                }
//
//                guard isFieldValid(passwordConfirmTextField, alertMsg: "Event password cannot be empty") else {
//                    return
//                }
//
//                guard isNumber(passwordConfirmTextField, alertMsg: "The passcode has to be numerical") else {
//                    return
//                }
//
//                guard isFieldValid(descriptionTextView, alertMsg: "Description cannot be empty") else {
//                    return
//                }
//
//                guard isFieldValid(personalPasswordTextField, alertMsg: "Your password cannot be empty") else {
//                    return
//                }
//
//                guard isNumber(personalPasswordTextField, alertMsg: "The host passcode has to be numerical") else {
//                    return
//                }
//
//                guard isFieldValid(personalPasswordConfirmTextField, alertMsg: "Your password cannot be empty") else {
//                    return
//                }
//
//                guard isNumber(personalPasswordConfirmTextField, alertMsg: "The host passcode has to be numerical") else {
//                    return
//                }

                UIView.animate(withDuration: 2) { [weak self] in
                    guard let view = self?.view else { return }
                    for subview in view.allSubviews where subview.tag != 4 {
                        if let label = subview as? UILabel {
                            label.alpha = 0
                            label.textColor = .clear
                        }

                        if let textView = subview as? UITextView {
                            textView.alpha = 0
                            textView.textColor = .clear
                            textView.backgroundColor = UIColor.black
                        }

                        subview.layer.borderColor = UIColor.black.cgColor
                    }

                    self?.buttonGradientView.alpha = 1
                }

                buttonGradientView.animate()
//                UIView.animate(withDuration: 2, delay: 0, usingSpringWithDamping: 100, initialSpringVelocity: 100, options: [.curveEaseIn]) { [weak self] in
//                    guard let self = self else { return }
//                    let center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
//                    let yDelta = self.buttonContainer.center.y - center.y
////                    self.buttonGradientView.transform = CGAffineTransform(translationX: 0, y: yDelta)
//                    self.buttonContainer.center = center
//
//                } completion: { isFinished in
//                    print(isFinished)
//                }


                startBlockchain(password: passwordTextField.text!, chainID: personalPasswordTextField.text!) { [weak self] (_) in
                    self?.buttonGradientView.alpha = 0
                    self?.buttonContainer.alpha = 0
                    AuthSwitcher.loginAsHost()
                }

                /// Fade out all the elements except for the button
//                UIView.animateKeyframes(withDuration: 3, delay: 0, options: .calculationModeCubic) {
//                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/4) { [weak self] in
//                        guard let view = self?.view else { return }
//                        for subview in view.allSubviews where subview.tag != 4 {
//                            if let label = subview as? UILabel {
//                                label.alpha = 0
//                            }
//
//                            if let textView = subview as? UITextView {
//                                textView.alpha = 0
//                                textView.backgroundColor = UIColor.black
//                            }
//
//                            subview.layer.borderColor = UIColor.black.cgColor
//                        }
//                    }
//
//                    UIView.addKeyframe(withRelativeStartTime: 1/4, relativeDuration: 2/4) { [weak self] in
//                        self?.buttonGradientView.alpha = 1
//                        self?.buttonGradientView.animate()
//                    }
//
//                    UIView.addKeyframe(withRelativeStartTime: 0.9, relativeDuration: 1/4) { [weak self] in
//                        self?.buttonGradientView.alpha = 0
//                        self?.buttonContainer.alpha = 0
//                    }
//                } completion: { (_) in
//                    AuthSwitcher.loginAsHost()
//                }

                break
            case 5:
                dismiss(animated: true)
                break
            default:
                break
        }
    }
    
    /// Starts the server, creates a wallet, and creates a genesis block.
    private func startBlockchain(password: String, chainID: String, completion: @escaping (Data) -> Void) {
        /// start the server
        NetworkManager.shared.start()
        Node.shared.deleteAll()
        
        /// save the password and the chain ID for future transactions
        UserDefaults.standard.set(password, forKey: UserDefaultKey.walletPassword)
        UserDefaults.standard.set(chainID, forKey: UserDefaultKey.chainID)
        
        /// Event info to be included in the genesis block's extra data.
        /// This will be queried by the guests to choose the event from.
        let eventInfo = EventInfo(eventName: eventNameTextField.text!, currencyName: currencyNameTextField.text!, description: descriptionTextView.text, image: imageData, chainID: chainID)
        
        do {
            let encodedExtraData = try JSONEncoder().encode(eventInfo)
            /// create a wallet
            Node.shared.createWallet(password: password, chainID: chainID, isHost: true, extraData: encodedExtraData, completion: completion)
        } catch {
            alert.show(error, for: self)
        }
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
        guard textField.tag == 100 || textField.tag == 101 || textField.tag == 102 || textField.tag == 103 else {
            return true
        }
        
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
    
    func showAlert(alertMsg: String) {
        passwordStatusLabel.isHidden = false
        passwordStatusLabel.text = alertMsg
        
        /// Get the y coordinate distance of the password view and the screen so the animation could be toggled between those two coordinates
        let yDelta = view.bounds.origin.y - passwordBlurView.frame.origin.y
        
        let animation = UIViewPropertyAnimator(duration: 4, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1/4) {
                    self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 1/4, relativeDuration: 1/2) {
                    // pause
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2/3, relativeDuration: 1/4) {
                    self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 0 : -100)
                }
            })
        }
        
        animation.startAnimation()
    }
}

extension HostLoginViewController: UITextViewDelegate, UITextFieldDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.gray {
            textView.text = nil
            textView.textColor = UIColor.lightGray
        }
        
        var point = textView.frame.origin
        point.y += textView.bounds.size.height
        scrollView.setContentOffset(point, animated: true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.attributedText = createAttributedString(imageString: "doc.append", imageColor: UIColor.gray, text: " Briefly describe your event")
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        var point = textField.frame.origin
        point.y += textField.bounds.size.height
        scrollView.setContentOffset(point, animated: true)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {

        let yDelta = view.bounds.origin.y - passwordBlurView.frame.origin.y
        
        if (!(passwordTextField.text?.isEmpty ?? true) ||
            !(passwordConfirmTextField.text?.isEmpty ?? true)) &&
            passwordTextField.text != passwordConfirmTextField.text {
            passwordStatusLabel.isHidden = false
            passwordStatusLabel.text = "Guest passwords don't match"
            passwordTextField.textColor = UIColor.red
            passwordConfirmTextField.textColor = UIColor.red
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
            }
        } else if (!(passwordTextField.text?.isEmpty ?? true) ||
                   !(passwordConfirmTextField.text?.isEmpty ?? true)) &&
                    ((passwordTextField.text?.count)! < 3) {
            passwordStatusLabel.isHidden = false
            passwordStatusLabel.text = "Guest password is too short"
            passwordConfirmTextField.textColor = UIColor.red
            passwordTextField.textColor = UIColor.red
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
            }
        } else if (!(personalPasswordTextField.text?.isEmpty ?? true) ||
                   !(personalPasswordConfirmTextField.text?.isEmpty ?? true)) &&
                    personalPasswordTextField.text != personalPasswordConfirmTextField.text {
            passwordStatusLabel.isHidden = false
            passwordStatusLabel.text = "Host passwords don't match"
            personalPasswordTextField.textColor = UIColor.red
            personalPasswordConfirmTextField.textColor = UIColor.red
            
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
            }
        } else if (!(personalPasswordTextField.text?.isEmpty ?? true) ||
                   !(personalPasswordConfirmTextField.text?.isEmpty ?? true)) &&
                    ((personalPasswordTextField.text?.count)! < 3) {
            passwordStatusLabel.isHidden = false
            passwordStatusLabel.text = "Host password is too short"
            personalPasswordConfirmTextField.textColor = UIColor.red
            personalPasswordTextField.textColor = UIColor.red
            
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 100 : 0)
            }
        } else {
            
            if textField.tag == 100 || textField.tag == 101 {
                passwordTextField.textColor = UIColor.lightGray
                passwordConfirmTextField.textColor = UIColor.lightGray
                
                UIView.animate(withDuration: 0.5) { [weak self] in
                    self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 0 : -100)
                }
            } else {
                personalPasswordTextField.textColor = UIColor.lightGray
                personalPasswordConfirmTextField.textColor = UIColor.lightGray
                
                UIView.animate(withDuration: 0.5) { [weak self] in
                    self?.passwordBlurView.transform = CGAffineTransform(translationX: 0, y: yDelta == -100 ? 0 : -100)
                }
            }
        }
        
        return true
    }
}

extension HostLoginViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
//              let data = try? Data(contentsOf: url),
//              let image = UIImage(data: data) else {
                  return
              }
        
        /// Retain the image data to be included in the first block
        imageData = image.jpegData(compressionQuality: 0.6)
        
        /// Display the image for the form
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageButton.addSubview(imageView)
        imageView.setFill()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension HostLoginViewController {
    // MARK: - addKeyboardObserver
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - removeKeyboardObserver
    private func removeKeyboardObserver(){
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        //Need to calculate keyboard exact size due to Apple suggestions
        
        guard let info = notification.userInfo,
              let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size else { return }
        
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        //Once keyboard disappears, restore original positions
        self.scrollView.contentInset = .zero
        self.scrollView.scrollIndicatorInsets = .zero
        self.view.endEditing(true)
    }
}
