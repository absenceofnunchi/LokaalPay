//
//  EventViewController.swift
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

final class EventViewController: RegisterViewController {
    /// Image upload
    private var imageTitleLabel: UILabel!
    private var imageSubtitleLabel: UILabel!
    private var gradientView: GradientView!
    private var imageButton: UIButton!
    private var imageBlurView: BlurEffectContainerView!
    private var imageSymbolView: UIImageView!
    private var passwordTextField: UITextField!
    private var passwordConfirmTextField: UITextField!
    private var personalPasswordTextField: UITextField!
    private var personalPasswordConfirmTextField: UITextField!
    
    /// Event name and password
    private var generalInfoBoxView: UIView!
    private var hostInfoBoxView: UIView!
    
    /// create event button
    private var passwordStatusLabel: UILabel!
    private var buttonGradientView: GradientView!
    private var createButton: UIButton!
    private var buttonContainer: UIView!
    private var passwordBlurView: BlurEffectContainerView!
    private var selectedTag: Int! /// For passsing the tag of the button to the custom transition animator
    
    final override func configureUI() {
        super.configureUI()
        
        /// Image upload button
        imageTitleLabel = UILabel()
        imageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageTitleLabel.text = "Create Event"
        imageTitleLabel.font = UIFont.rounded(ofSize: 25, weight: .bold)
        imageTitleLabel.textColor = .lightGray
        scrollView.addSubview(imageTitleLabel)
        
        imageSubtitleLabel = UILabel()
        imageSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageSubtitleLabel.text = "Event info and a password for your guests!"
        imageSubtitleLabel.font = UIFont.rounded(ofSize: 15, weight: .bold)
        imageSubtitleLabel.textColor = .lightGray
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
        imageSymbolView.isUserInteractionEnabled = false

        imageButton = UIButton()
        imageButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        imageButton.tag = 1
        imageButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageButton)
        imageButton.addSubview(gradientView)
        gradientView.setFill()
        gradientView.sendSubviewToBack(gradientView)
        gradientView.isUserInteractionEnabled = false
        
        let eventNameTextField = createTextField(placeHolderText: " Event Name", placeHolderImageString: "square.stack.3d.down.forward")
        passwordTextField = createTextField(placeHolderText: " Password", placeHolderImageString: "lock", isPassword: true)
        passwordTextField.tag = 100
        passwordConfirmTextField = createTextField(placeHolderText: " Confirm Password", placeHolderImageString: "lock", isPassword: true)
        passwordConfirmTextField.tag = 101
        let descriptionTextView = createTextView(placeHolderText: " Briefly describe your event", placeHolderImageString: "doc.append")
        
        generalInfoBoxView = createInfoBoxView(title: "General Information", subTitle: "To share with your guests", arrangedSubviews: [eventNameTextField, passwordTextField, passwordConfirmTextField, descriptionTextView])
        scrollView.addSubview(generalInfoBoxView)
        
        personalPasswordTextField = createTextField(placeHolderText: " Password", placeHolderImageString: "lock", isPassword: true)
        personalPasswordTextField.tag = 102
        personalPasswordConfirmTextField = createTextField(placeHolderText: " Confirm Password", placeHolderImageString: "lock", isPassword: true)
        personalPasswordConfirmTextField.tag = 103
        
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
    
    final override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
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
            generalInfoBoxView.heightAnchor.constraint(equalToConstant: 420),
            
            hostInfoBoxView.topAnchor.constraint(equalTo: generalInfoBoxView.bottomAnchor, constant: 40),
            hostInfoBoxView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            hostInfoBoxView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            hostInfoBoxView.heightAnchor.constraint(equalToConstant: 210),
            
//            passwordBlurView.topAnchor.constraint(equalTo: view.topAnchor, constant: -100),
//            passwordBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
//            passwordBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
//            passwordBlurView.heightAnchor.constraint(equalToConstant: 100),
            
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

    private func createLabel(text: String, size: CGFloat = 18) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.rounded(ofSize: size, weight: .bold)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func createTextField(placeHolderText: String, placeHolderImageString: String, height: CGFloat = 50, isPassword: Bool = false) -> UITextField {
        let textField = UITextField()
        textField.font = UIFont.rounded(ofSize: 14, weight: .bold)
        textField.leftPadding()
        textField.delegate = self
        textField.textColor = .lightGray
        textField.isSecureTextEntry = isPassword
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.borderWidth = 0.5
        textField.layer.cornerRadius = 10
        textField.attributedPlaceholder = createAttributedString(imageString: placeHolderImageString, imageColor: .gray, text: placeHolderText)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: height).isActive = true
        return textField
    }
    
    private func createTextView(placeHolderText: String, placeHolderImageString: String, height: CGFloat = 100) -> UITextView {
        let textView = UITextView()
        textView.delegate = self
        textView.textColor = .lightGray
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = true
        textView.autocorrectionType = .yes
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 0.5
        textView.layer.cornerRadius = 10
        textView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        textView.clipsToBounds = true
        textView.isScrollEnabled = true
        textView.font = UIFont.rounded(ofSize: 14, weight: .bold)
        textView.attributedText = createAttributedString(imageString: placeHolderImageString, imageColor: UIColor.gray, text: placeHolderText)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(equalToConstant: height).isActive = true

        return textView
    }
    
    // Info box consists of a unit of text fields and text views
    private func createInfoBoxView(title: String, subTitle: String, arrangedSubviews: [UIView]) -> UIView {
        let boxContainerView = UIView()
        boxContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        /// Event name and password
        let titleLabel = createLabel(text: title)
        boxContainerView.addSubview(titleLabel)
        
        let subtitleLabel = createLabel(text: subTitle, size: 12)
        subtitleLabel.textColor = .gray
        boxContainerView.addSubview(subtitleLabel)
        
        let lineView = UIView()
        lineView.layer.borderColor = UIColor.darkGray.cgColor
        lineView.layer.borderWidth = 0.5
        lineView.translatesAutoresizingMaskIntoConstraints = false
        boxContainerView.addSubview(lineView)
        
        //        gradientView2 = GradientView(colors: [UIColor.white.cgColor, UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1).cgColor, UIColor.blue.cgColor])
//        let gradientView = GradientView(colors: [UIColor.white.cgColor, UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor, UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1).cgColor])
//        gradientView.layer.cornerRadius = 10
//        gradientView.clipsToBounds = true
//        gradientView.backgroundColor = .black
//        gradientView.translatesAutoresizingMaskIntoConstraints = false
//        boxContainerView.addSubview(gradientView)
//
//        let blurView = BlurEffectContainerView(blurStyle: .dark, effectViewAlpha:  0.8) /// The alpha is for the black color of the effect view's background.
//        blurView.layer.cornerRadius = 10
//        blurView.translatesAutoresizingMaskIntoConstraints = false
//        gradientView.addSubview(blurView)
//        blurView.setFill()
        
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        boxContainerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: boxContainerView.topAnchor, constant: 0),
            titleLabel.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
            titleLabel.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
            titleLabel.heightAnchor.constraint(equalToConstant: 25),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            subtitleLabel.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
            subtitleLabel.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 20),
            
            lineView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            lineView.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
            lineView.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
            lineView.heightAnchor.constraint(equalToConstant: 0.5),
            
//            gradientView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
//            gradientView.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
//            gradientView.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
//            gradientView.bottomAnchor.constraint(equalTo: boxContainerView.bottomAnchor),
            
//            stackView.topAnchor.constraint(equalTo: blurView.topAnchor, constant: 20),
//            stackView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: 20),
//            stackView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -20),
//            stackView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor, constant: -20),
            
            stackView.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: boxContainerView.leadingAnchor, constant: 0),
            stackView.trailingAnchor.constraint(equalTo: boxContainerView.trailingAnchor, constant: 0),
            stackView.bottomAnchor.constraint(equalTo: boxContainerView.bottomAnchor, constant: 0),
        ])
        
        return boxContainerView
    }
    
    private func createAttributedString(imageString: String, imageColor: UIColor, text: String) -> NSMutableAttributedString {
        /// Create an attributed strings using a symbol and a text
        let imageAttahment = NSTextAttachment()
        imageAttahment.image = UIImage(systemName: imageString)?.withTintColor(imageColor, renderingMode: .alwaysOriginal)
        let imageOffsetY: CGFloat = -5.0
        imageAttahment.bounds = CGRect(x: 0, y: imageOffsetY, width: imageAttahment.image!.size.width, height: imageAttahment.image!.size.height)
        let imageString = NSAttributedString(attachment: imageAttahment)
        let textString = NSAttributedString(string: text)
        
        /// Add them to a mutable attributed string
        let mas = NSMutableAttributedString(string: "")
        mas.append(imageString)
        mas.append(textString)
        
        /// Add attributes
        let rangeText = (mas.string as NSString).range(of: mas.string)
        mas.addAttributes([
            NSAttributedString.Key.foregroundColor: UIColor.gray,
            .font: UIFont.rounded(ofSize: 14, weight: .bold)
        ], range: rangeText)
        
        return mas
    }
    
    override func getContentSizeHeight() -> CGFloat {
        return super.getContentSizeHeight()
        + imageTitleLabel.bounds.size.height
        + imageSubtitleLabel.bounds.size.height
        + imageButton.bounds.size.height
        + generalInfoBoxView.bounds.size.height
        + hostInfoBoxView.bounds.size.height
        + buttonContainer.bounds.size.height
        + 250
    }
    
    @objc final override func buttonPressed(_ sender: UIButton) {
        super.buttonPressed(sender)
        
        switch sender.tag {
            case 1:
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
                UIView.animateKeyframes(withDuration: 2, delay: 0, options: .calculationModeCubic) {
                    UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) { [weak self] in
                        guard let view = self?.view else { return }
                        for subview in view.allSubviews where subview.tag != 4 {
                            if let label = subview as? UILabel {
                                label.alpha = 0
                            }

                            if let textView = subview as? UITextView {
                                textView.alpha = 0
                                textView.backgroundColor = UIColor.black
                            }


                            subview.layer.borderColor = UIColor.black.cgColor
                        }
                    }
                    
                    UIView.addKeyframe(withRelativeStartTime: 0.1, relativeDuration: 0.3) { [weak self] in
                        self?.buttonGradientView.alpha = 1
                        self?.buttonGradientView.animate()
                    }
                    
                    UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.3) { [weak self] in
//                        guard let self = self else { return }
//                        let center = self.view.convert(self.view.center, from: self.view.superview)
//                        print("center", center)
//                        let xDelta = self.createButton.center.x - center.x
//                        print("xDelta", xDelta)
//                        let yDelta = self.createButton.center.y - center.y
//                        self.createButton.transform = CGAffineTransform(translationX: xDelta, y: yDelta)
                        
//
                        self?.createButton.layer.shadowRadius = 0
                        self?.createButton.layer.shadowOffset = .zero
                        self?.createButton.layer.shadowColor = .none
                        self?.createButton.layer.shadowOpacity = 0
                        self?.buttonContainer.allSubviews.forEach {
                            $0.backgroundColor = .black
                            $0.alpha = 0
                        }

                    }
                } completion: { (_) in
                    AuthSwitcher.loginAsHost()
                }
                
                break
            default:
                break
        }
    }
}

extension EventViewController: UITextViewDelegate, UITextFieldDelegate {
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

extension EventViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let url = info[UIImagePickerController.InfoKey.imageURL] as? URL,
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
                  return
              }
        
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
