//
//  EventViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

final class EventViewController: RegisterViewController {
    /// Image upload
    private var imageTitleLabel: UILabel!
    private var imageSubtitleLabel: UILabel!
    private var gradientView: GradientView!
    private var imageButton: UIButton!
    
    /// Event name and password
    private var gradientView2: GradientView!
    private var textFieldBlurView: BlurEffectContainerView!
    private var imageBlurView: BlurEffectContainerView!
    private var eventNameTextField: UITextField!
    private var passwordTextField: UITextField!
    private var passwordConfirmTextField: UITextField!
    private var stackView: UIStackView!
    private var imageSymbolView: UIImageView!

    final override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
    }
    
    final override func configureUI() {
        super.configureUI()
        
        /// Image setup
        imageTitleLabel = UILabel()
        imageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageTitleLabel.text = "Create Event"
        imageTitleLabel.font = UIFont.rounded(ofSize: 25, weight: .bold)
        imageTitleLabel.textColor = .lightGray
        view.addSubview(imageTitleLabel)
        
        imageSubtitleLabel = UILabel()
        imageSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        imageSubtitleLabel.text = "Event info and a password for your guests!"
        imageSubtitleLabel.font = UIFont.rounded(ofSize: 15, weight: .bold)
        imageSubtitleLabel.textColor = .lightGray
        view.addSubview(imageSubtitleLabel)
        
        gradientView = GradientView()
        gradientView.layer.cornerRadius = 10
        gradientView.clipsToBounds = true
        gradientView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(gradientView)
        
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
        view.addSubview(imageButton)
        imageButton.addSubview(gradientView)
        gradientView.setFill()
        gradientView.sendSubviewToBack(gradientView)
        gradientView.isUserInteractionEnabled = false
        
        /// Event name and password setup
        gradientView2 = GradientView(colors: [UIColor.white.cgColor, UIColor.white.cgColor, UIColor.blue.cgColor])
        gradientView2.layer.cornerRadius = 10
        gradientView2.clipsToBounds = true
        gradientView2.backgroundColor = .black
        gradientView2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView2)
        
        textFieldBlurView = BlurEffectContainerView(blurStyle: .dark, effectViewAlpha:  0.8)
        textFieldBlurView.layer.cornerRadius = 10
        textFieldBlurView.translatesAutoresizingMaskIntoConstraints = false
        gradientView2.addSubview(textFieldBlurView)
        textFieldBlurView.setFill()
        
        eventNameTextField = UITextField()
        eventNameTextField.leftPadding()
        eventNameTextField.textColor = .lightGray
        eventNameTextField.layer.borderColor = UIColor.lightGray.cgColor
        eventNameTextField.layer.borderWidth = 0.5
        eventNameTextField.layer.cornerRadius = 10
        eventNameTextField.attributedPlaceholder = createAttributedString(imageString: "square.stack.3d.down.forward", imageColor: .lightGray, text: " Event Name")
        eventNameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        passwordTextField = UITextField()
        passwordTextField.leftPadding()
        passwordTextField.textColor = .lightGray
        passwordTextField.isSecureTextEntry = true
        passwordTextField.layer.borderColor = UIColor.lightGray.cgColor
        passwordTextField.layer.borderWidth = 0.5
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.attributedPlaceholder = createAttributedString(imageString: "lock", imageColor: .lightGray, text: " Password")
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        
        passwordConfirmTextField = UITextField()
        passwordConfirmTextField.leftPadding()
        passwordConfirmTextField.textColor = .lightGray
        passwordConfirmTextField.isSecureTextEntry = true
        passwordConfirmTextField.layer.borderColor = UIColor.lightGray.cgColor
        passwordConfirmTextField.layer.borderWidth = 0.5
        passwordConfirmTextField.layer.cornerRadius = 10
        passwordConfirmTextField.attributedPlaceholder = createAttributedString(imageString: "lock", imageColor: .lightGray, text: " Confirm Password")
        passwordConfirmTextField.translatesAutoresizingMaskIntoConstraints = false
        
        stackView = UIStackView(arrangedSubviews: [eventNameTextField, passwordTextField, passwordConfirmTextField])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        textFieldBlurView.addSubview(stackView)
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
            NSAttributedString.Key.foregroundColor: UIColor.lightGray,
            .font: UIFont.rounded(ofSize: 14, weight: .bold)
        ], range: rangeText)
        
        return mas
    }
    
    final override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
            imageTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            imageTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            imageTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            imageTitleLabel.heightAnchor.constraint(equalToConstant: 30),
            
            imageSubtitleLabel.topAnchor.constraint(equalTo: imageTitleLabel.bottomAnchor, constant: 0),
            imageSubtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            imageSubtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            imageSubtitleLabel.heightAnchor.constraint(equalToConstant: 40),
            
//            gradientView.topAnchor.constraint(equalTo: imageSubtitleLabel.bottomAnchor, constant: 20),
//            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
//            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
//            gradientView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
            
            imageSymbolView.centerXAnchor.constraint(equalTo: imageBlurView.centerXAnchor),
            imageSymbolView.centerYAnchor.constraint(equalTo: imageBlurView.centerYAnchor),
            imageSymbolView.widthAnchor.constraint(equalToConstant: 50),
            imageSymbolView.heightAnchor.constraint(equalToConstant: 50),
            
            imageButton.topAnchor.constraint(equalTo: imageSubtitleLabel.bottomAnchor, constant: 20),
            imageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            imageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            imageButton.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
            
            gradientView2.topAnchor.constraint(equalTo: imageButton.bottomAnchor, constant: 40),
            gradientView2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            gradientView2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            gradientView2.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),

            stackView.topAnchor.constraint(equalTo: gradientView2.topAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: textFieldBlurView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: textFieldBlurView.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: textFieldBlurView.bottomAnchor, constant: -30),
            
//            eventNameTextField.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100),
//            eventNameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
//            eventNameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            eventNameTextField.heightAnchor.constraint(equalToConstant: 60),
//
//            passwordTextField.topAnchor.constraint(equalTo: eventNameTextField.bottomAnchor, constant: 100),
//            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
//            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            passwordTextField.heightAnchor.constraint(equalToConstant: 60),
            passwordConfirmTextField.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    @objc final override func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 1:
                let alertVC = ActionSheetViewController()
                present(alertVC, animated: true)
                
//                let alertVC = UIAlertController(title: "Select An Image", message: nil, preferredStyle: .actionSheet)
//                alertVC.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
//                    print("camera")
//                }))
//                alertVC.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
////                    let pickerVC = UIImagePickerController()
////                    pickerVC.sourceType = .photoLibrary
////                    pickerVC.allowsEditing = true
////                    pickerVC.delegate = self
////                    present(pickerVC, animated: true)
//                }))
//                alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] (_) in
//                    self?.dismiss(animated: true, completion: nil)
//                }))
//                present(alertVC, animated: true, completion: nil)
            default:
                break
        }
    }
}

extension EventViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let url = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            return
        }
        
        print("url", url)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
