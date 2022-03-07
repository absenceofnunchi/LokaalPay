//
//  EventViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

import UIKit

final class EventViewController: RegisterViewController {
    private var gradientView: GradientView!
    private var gradientView2: GradientView!
    private var textFieldBlurView: BlurEffectContainerView!
    private var imageBlurView: BlurEffectContainerView!
    private var eventNameTextField: UITextField!
    private var passwordTextField: UITextField!
    private var stackView: UIStackView!
    private var imageSymbolView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
    }
    
    override func configureUI() {
        super.configureUI()
        
        gradientView = GradientView()
        gradientView.layer.cornerRadius = 10
        gradientView.clipsToBounds = true
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gradientView)
        
        imageBlurView = BlurEffectContainerView(blurStyle: .regular)
        gradientView.addSubview(imageBlurView)
        imageBlurView.setFill()
        
        guard let imageSymbol = UIImage(systemName: "photo")?.withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
        imageSymbolView = UIImageView(image: imageSymbol)
        imageSymbolView.contentMode = .scaleAspectFill
        imageSymbolView.translatesAutoresizingMaskIntoConstraints = false
        imageBlurView.addSubview(imageSymbolView)
        
        gradientView2 = GradientView(colors: [UIColor.white.cgColor, UIColor.gray.cgColor, UIColor.darkGray.cgColor])
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
        eventNameTextField.layer.borderColor = UIColor.lightGray.cgColor
        eventNameTextField.layer.borderWidth = 1
        eventNameTextField.layer.cornerRadius = 10
//        eventNameTextField.attributedPlaceholder = NSAttributedString(string: "Event Name", attributes: [
//            .foregroundColor: UIColor.lightGray,
//            .font: UIFont.boldSystemFont(ofSize: 15)
//        ])
//        eventNameTextField.attributedPlaceholder = mas
        eventNameTextField.translatesAutoresizingMaskIntoConstraints = false
        textFieldBlurView.addSubview(eventNameTextField)
        
        passwordTextField = UITextField()
        passwordTextField.leftPadding()
        passwordTextField.isSecureTextEntry = true
        passwordTextField.layer.borderColor = UIColor.lightGray.cgColor
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.cornerRadius = 10
        passwordTextField.attributedPlaceholder = NSAttributedString(string: "Passsword", attributes: [
            .foregroundColor: UIColor.lightGray,
            .font: UIFont.boldSystemFont(ofSize: 15)
        ])
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        textFieldBlurView.addSubview(passwordTextField)
        
        stackView = UIStackView(arrangedSubviews: [eventNameTextField, passwordTextField])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        textFieldBlurView.addSubview(stackView)
    }
    
    /// "square.stack.3d.down.forward"
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
    
    override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            gradientView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
            
            gradientView2.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100),
            gradientView2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            gradientView2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            gradientView2.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),
            
            imageSymbolView.centerXAnchor.constraint(equalTo: gradientView.centerXAnchor),
            imageSymbolView.centerYAnchor.constraint(equalTo: gradientView.centerYAnchor),
            imageSymbolView.heightAnchor.constraint(equalToConstant: 50),
            imageSymbolView.widthAnchor.constraint(equalToConstant: 50),
            
//            textFieldBlurView.topAnchor.constraint(equalTo: gradientView.bottomAnchor, constant: 100),
//            textFieldBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
//            textFieldBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
//            textFieldBlurView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),

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
        ])
    }
}
