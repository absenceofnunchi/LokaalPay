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
    
    /// Event name and password
    private var eventInfoLabel: UILabel!
    private var gradientView2: GradientView!
    private var textFieldBlurView: BlurEffectContainerView!
    private var imageBlurView: BlurEffectContainerView!
    private var eventNameTextField: UITextField!
    private var passwordTextField: UITextField!
    private var passwordConfirmTextField: UITextField!
    private var descriptionTextView: UITextView!
    private var stackView: UIStackView!
    private var imageSymbolView: UIImageView!    
    
    final override func configureUI() {
        super.configureUI()
        
        /// title and subtitle label
        let testTextField = UITextField()
        testTextField.layer.borderColor = UIColor.white.cgColor
        testTextField.layer.borderWidth = 1
        testTextField.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(testTextField)
        
        NSLayoutConstraint.activate([
            testTextField.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 550),
            testTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            testTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            testTextField.heightAnchor.constraint(equalToConstant: 50),
        ])
        
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

        /// Event name and password
        eventInfoLabel = UILabel()
        eventInfoLabel.text = "General Information"
        eventInfoLabel.font = UIFont.rounded(ofSize: 18, weight: .bold)
        eventInfoLabel.textColor = .lightGray
        eventInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(eventInfoLabel)
        
//        gradientView2 = GradientView(colors: [UIColor.white.cgColor, UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1).cgColor, UIColor.blue.cgColor])
        gradientView2 = GradientView(colors: [UIColor.white.cgColor, UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor, UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1).cgColor])
        gradientView2.layer.cornerRadius = 10
        gradientView2.clipsToBounds = true
        gradientView2.backgroundColor = .black
        gradientView2.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(gradientView2)

        textFieldBlurView = BlurEffectContainerView(blurStyle: .dark, effectViewAlpha:  0.8) /// The alpha is for the black color of the effect view's background.
        textFieldBlurView.layer.cornerRadius = 10
        textFieldBlurView.translatesAutoresizingMaskIntoConstraints = false
        gradientView2.addSubview(textFieldBlurView)
        textFieldBlurView.setFill()

        /// Event name label
        eventNameTextField = UITextField()
        eventNameTextField.font = UIFont.rounded(ofSize: 14, weight: .bold)
        eventNameTextField.leftPadding()
        eventNameTextField.textColor = .lightGray
        eventNameTextField.layer.borderColor = UIColor.lightGray.cgColor
        eventNameTextField.layer.borderWidth = 0.5
        eventNameTextField.layer.cornerRadius = 10
        eventNameTextField.attributedPlaceholder = createAttributedString(imageString: "square.stack.3d.down.forward", imageColor: .gray, text: " Event Name")
        eventNameTextField.translatesAutoresizingMaskIntoConstraints = false

        /// Password name label
        passwordTextField = UITextField()
        passwordTextField.font = UIFont.rounded(ofSize: 14, weight: .bold)
        passwordTextField.leftPadding()
        passwordTextField.textColor = .lightGray
        passwordTextField.isSecureTextEntry = true
        passwordTextField.layer.borderColor = UIColor.lightGray.cgColor
        passwordTextField.layer.borderWidth = 0.5
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.attributedPlaceholder = createAttributedString(imageString: "lock", imageColor: .gray, text: " Password")
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false

        /// Password confirmation label
        passwordConfirmTextField = UITextField()
//        passwordConfirmTextField.font = UIFont.rounded(ofSize: 14, weight: .bold)
        passwordConfirmTextField.leftPadding()
        passwordConfirmTextField.textColor = .lightGray
        passwordConfirmTextField.isSecureTextEntry = true
        passwordConfirmTextField.layer.borderColor = UIColor.lightGray.cgColor
        passwordConfirmTextField.layer.borderWidth = 0.5
        passwordConfirmTextField.layer.cornerRadius = 10
        passwordConfirmTextField.attributedPlaceholder = createAttributedString(imageString: "lock", imageColor: .gray, text: " Confirm Password")
        passwordConfirmTextField.translatesAutoresizingMaskIntoConstraints = false
        
        /// Description textview
        descriptionTextView = UITextView()
        descriptionTextView.delegate = self
        descriptionTextView.textColor = .lightGray
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.allowsEditingTextAttributes = true
        descriptionTextView.autocorrectionType = .yes
        descriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.cornerRadius = 10
        descriptionTextView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        descriptionTextView.clipsToBounds = true
        descriptionTextView.isScrollEnabled = true
        descriptionTextView.font = UIFont.rounded(ofSize: 14, weight: .bold)
        descriptionTextView.attributedText = createAttributedString(imageString: "doc.append", imageColor: UIColor.gray, text: " Briefly describe your event!")
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(descriptionTextView)

        stackView = UIStackView(arrangedSubviews: [eventNameTextField, passwordTextField, passwordConfirmTextField, descriptionTextView])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        textFieldBlurView.addSubview(stackView)
    }
    
    // Info box consists of a unit of text fields and text views
    private func createInfoBox() {
        let boxContainerView = UIView()
        
        /// Event name and password
        let eventInfoLabel = UILabel()
        eventInfoLabel.text = "General Information"
        eventInfoLabel.font = UIFont.rounded(ofSize: 18, weight: .bold)
        eventInfoLabel.textColor = .lightGray
        eventInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        boxContainerView.addSubview(eventInfoLabel)
        
        //        gradientView2 = GradientView(colors: [UIColor.white.cgColor, UIColor(red: 240/255, green: 248/255, blue: 255/255, alpha: 1).cgColor, UIColor.blue.cgColor])
        let gradientView2 = GradientView(colors: [UIColor.white.cgColor, UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor, UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1).cgColor])
        gradientView2.layer.cornerRadius = 10
        gradientView2.clipsToBounds = true
        gradientView2.backgroundColor = .black
        gradientView2.translatesAutoresizingMaskIntoConstraints = false
        boxContainerView.addSubview(gradientView2)
        
        textFieldBlurView = BlurEffectContainerView(blurStyle: .dark, effectViewAlpha:  0.8) /// The alpha is for the black color of the effect view's background.
        textFieldBlurView.layer.cornerRadius = 10
        textFieldBlurView.translatesAutoresizingMaskIntoConstraints = false
        gradientView2.addSubview(textFieldBlurView)
        textFieldBlurView.setFill()
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
            
            eventInfoLabel.topAnchor.constraint(equalTo: imageButton.bottomAnchor, constant: 40),
            eventInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            eventInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            eventInfoLabel.heightAnchor.constraint(equalToConstant: 30),
            
            gradientView2.topAnchor.constraint(equalTo: eventInfoLabel.bottomAnchor, constant: 10),
            gradientView2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            gradientView2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            gradientView2.heightAnchor.constraint(equalToConstant: 370),

            stackView.topAnchor.constraint(equalTo: gradientView2.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: textFieldBlurView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: textFieldBlurView.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: textFieldBlurView.bottomAnchor, constant: -30),

            eventNameTextField.heightAnchor.constraint(equalToConstant: 50),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            passwordConfirmTextField.heightAnchor.constraint(equalToConstant: 50),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    override func getContentSizeHeight() -> CGFloat {
        return super.getContentSizeHeight() + imageTitleLabel.bounds.size.height + imageSubtitleLabel.bounds.size.height + gradientView2.bounds.size.height + stackView.bounds.size.height + eventInfoLabel.bounds.size.height + 100
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
