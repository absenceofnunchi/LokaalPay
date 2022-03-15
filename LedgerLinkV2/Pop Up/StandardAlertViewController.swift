//
//  StandardAlertViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-12.
//

/*
 Abstract:
 A single page view controller for AlertViewController which is the container page view controller
 Able to fine-grain control things like the height and the button availability
 Largely composed of three parts:
 1. Title
 2. Body
 3. Buttons
 
 The body consists of a subtitle and a text view which can either be used as a label or for a user input.
 The default values are geared towards displaying a general alert with a title (height: 50), a text view as a label (height: 150) and one button to dismiss (height: 50).
 The container alert view controller should be around height = 350 which is the default height. Anything under 300 will cover the title label. Needs to be fixed.
 When using the text view as an input source, use height = 50.
 The body's subtitles and the text views can be multiple.
 */

import UIKit


enum AlertStyle {
    case oneButton, withCancelButton, noButton
}

struct StandardAlertContent {
    var index: Int = 0
    let titleString: String
    var titleColor: UIColor = .lightGray
    let body: KeyValuePairs<String, String>
    var isEditable: Bool = false
    var fieldViewHeight: CGFloat = 150
    var buttonTitle: String = "OK"
    var titleAlignment: NSTextAlignment = .center
    var messageTextAlignment: NSTextAlignment = .center
    var alertStyle: AlertStyle = .oneButton
    var buttonAction: ((StandardAlertViewController)->Void)?
    var borderColor: CGColor? = UIColor.lightGray.cgColor
}

class StandardAlertViewController: UIViewController {
    var index: Int!
    private var titleString: String?
    private var titleColor: UIColor!
    // subtitle : the actual message
    private var body: KeyValuePairs<String, String>!
    private var titleLabel: UILabel!
    private var titleAlignment: NSTextAlignment!
    private var messageTextAlignment: NSTextAlignment!
    private var bodyStackView: UIStackView!
    private var isEditable: Bool!
    private var fieldViewHeight: CGFloat!
    var buttonAction: ((StandardAlertViewController)->Void)?
    private var buttonPanel: UIView!
    private var buttonTitle: String!
    private var okButton: UIView!
    private var cancelButton: UIView!
    private var alertStyle: AlertStyle!
    private var constraints: [NSLayoutConstraint]!
    private var bodyArrangedSubviews: [UIView]!
    weak var delegate: DataFetchDelegate?
    private var customNavView: BackgroundView!
    private var borderColor: CGColor?

    init(content: StandardAlertContent) {
        super.init(nibName: nil, bundle: nil)
        
        self.index = content.index
        self.titleString = content.titleString
        self.titleColor = content.titleColor
        self.body = content.body
        self.isEditable = content.isEditable
        self.fieldViewHeight = content.fieldViewHeight
        self.buttonTitle = content.buttonTitle
        self.alertStyle = content.alertStyle
        self.titleAlignment = content.titleAlignment
        self.messageTextAlignment = content.messageTextAlignment
        self.buttonAction = content.buttonAction
        self.borderColor = content.borderColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    final override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        setConstraints()
        loadingAnimation()
    }
}

extension StandardAlertViewController: UITextFieldDelegate {
    private func configure() {
//        view.backgroundColor = .clear
        
        titleLabel = UILabel()
        titleLabel.text = titleString
        titleLabel.textColor = titleColor
        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.rounded(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = titleAlignment
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 30)
        titleLabel.alpha = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        customNavView = BackgroundView()
        customNavView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(customNavView, belowSubview: titleLabel)
        
        bodyArrangedSubviews = body.map { (key, value) in
            let v = UIView()
            v.translatesAutoresizingMaskIntoConstraints = false
            
            let subtitleLabel = UILabel()
            subtitleLabel.text = key
            subtitleLabel.textColor = .lightGray
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(subtitleLabel)
            
            let messageTextView = UITextView()
            
            if isEditable {
                messageTextView.isUserInteractionEnabled = true
                messageTextView.keyboardType = .decimalPad
                messageTextView.backgroundColor = .gray
                messageTextView.alpha = 4
                messageTextView.layer.cornerRadius = 10
                messageTextView.font = UIFont.preferredFont(forTextStyle: .body)
            }
            
            messageTextView.layer.borderWidth = 0.5
            messageTextView.layer.borderColor = borderColor
            messageTextView.isEditable = isEditable
            messageTextView.delegate = self
            messageTextView.text = value
            messageTextView.backgroundColor = .clear
            messageTextView.textColor = .lightGray
            messageTextView.textAlignment = messageTextAlignment
            messageTextView.contentInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
            messageTextView.clipsToBounds = true
            messageTextView.showsVerticalScrollIndicator = true
            messageTextView.isScrollEnabled = true
            messageTextView.font = UIFont.rounded(ofSize: 18, weight: .regular)
            messageTextView.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(messageTextView)
            
            NSLayoutConstraint.activate([
                //                v.heightAnchor.constraint(equalToConstant: fieldViewHeight + 20 + 5),
                
                subtitleLabel.topAnchor.constraint(equalTo: v.topAnchor),
                subtitleLabel.widthAnchor.constraint(equalTo: v.widthAnchor),
                // eliminate the height of the subtitle if no subtitle exists
                subtitleLabel.heightAnchor.constraint(equalToConstant: key == "" ? 0 : 20),
                
                messageTextView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 0),
                messageTextView.widthAnchor.constraint(equalTo: v.widthAnchor),
                messageTextView.heightAnchor.constraint(equalToConstant: fieldViewHeight)
            ])
            
            return v
        }
        
        bodyStackView = UIStackView(arrangedSubviews: bodyArrangedSubviews)
        bodyStackView.axis = .vertical
        bodyStackView.distribution = .fillEqually
        bodyStackView.spacing = 5
        bodyStackView.transform = CGAffineTransform(translationX: 0, y: 30)
        bodyStackView.alpha = 0
        bodyStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bodyStackView)
        
        buttonPanel = UIView()
        buttonPanel.transform = CGAffineTransform(translationX: 0, y: 30)
        buttonPanel.alpha = 0
        buttonPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonPanel)
        
        let okButtonInfo = ButtonInfo(
            title: "OK",
            tag: 1,
            backgroundColor: .black,
            titleColor: .lightGray
        )
        okButton = createButton(buttonInfo: okButtonInfo)
        buttonPanel.addSubview(okButton)
        
        let cancelButtonInfo = ButtonInfo(
            title: "Cancel",
            tag: 2,
            backgroundColor: .gray,
            titleColor: .darkGray
        )
        cancelButton = createButton(buttonInfo: cancelButtonInfo)
        buttonPanel.addSubview(cancelButton)
    }
    
    private func setConstraints() {
        // Set constraints of the buttons within the button panel
        var buttonConstraints = [NSLayoutConstraint]()
        
        switch alertStyle {
            case .withCancelButton:
                buttonConstraints.append(contentsOf: [
                    okButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
                    okButton.heightAnchor.constraint(equalToConstant: 50),
                    okButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
                    okButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
                    
                    cancelButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
                    cancelButton.heightAnchor.constraint(equalToConstant: 50),
                    cancelButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
                    cancelButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
                ])
            case .oneButton:
                cancelButton.alpha = 0
                cancelButton.isUserInteractionEnabled = false
                
                buttonConstraints.append(contentsOf: [
                    okButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
                    okButton.heightAnchor.constraint(equalToConstant: 50),
                    okButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    okButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                ])
            case .noButton:
                okButton.alpha = 0
                okButton.isUserInteractionEnabled = false
                
                cancelButton.alpha = 0
                cancelButton.isUserInteractionEnabled = false
                
                buttonConstraints.append(contentsOf: [
                    okButton.leadingAnchor.constraint(equalTo: buttonPanel.leadingAnchor),
                    okButton.heightAnchor.constraint(equalToConstant: 0),
                    okButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
                    okButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
                    
                    cancelButton.trailingAnchor.constraint(equalTo: buttonPanel.trailingAnchor),
                    cancelButton.heightAnchor.constraint(equalToConstant: 0),
                    cancelButton.topAnchor.constraint(equalTo: buttonPanel.topAnchor),
                    cancelButton.widthAnchor.constraint(equalTo: buttonPanel.widthAnchor, multiplier: 0.4),
                ])
                break
            default:
                break
        }
        
        // Set the constraints of the overall StandardAlerVC
        // Nested array only because the constraints that are contingent can be nested in here chronogically in one big block
        var constraints: [[NSLayoutConstraint]]!
        
        if alertStyle == .noButton {
            constraints = [
                [
                    titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
                    titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
                    titleLabel.heightAnchor.constraint(equalToConstant: 50),
                    
                    customNavView.topAnchor.constraint(equalTo: view.topAnchor, constant: -20),
                    customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    customNavView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 80),
                    
                    bodyStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                    bodyStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                    bodyStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                    bodyStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
                    
                    buttonPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
                    buttonPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    buttonPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    buttonPanel.heightAnchor.constraint(equalToConstant: 0)
                ],
                
                buttonConstraints
            ]
        } else {
            constraints = [
                [
                    titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
                    titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
                    titleLabel.heightAnchor.constraint(equalToConstant: 50),
                    
                    bodyStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                    bodyStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    bodyStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    bodyStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
                    
                    buttonPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
                    buttonPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    buttonPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                    buttonPanel.heightAnchor.constraint(equalToConstant: 50)
                ],
                
                buttonConstraints
            ]
        }
        
        let flattened = constraints.reduce ([], + )
        NSLayoutConstraint.activate(flattened)
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 1:
                if let buttonAction = self.buttonAction {
                    buttonAction(self)
                }
            case 2:
                self.dismiss(animated: true, completion: nil)
            default:
                break
        }
    }
    
    private func fetchInputFromTextFields() -> [String: String]? {
        var inputFromTextFields = [String: String]()
        for case let arrangedSubview in bodyArrangedSubviews {
            var key, value: String!
            for case let subSubview in arrangedSubview.subviews {
                switch subSubview {
                    case is UILabel:
                        guard let text = (subSubview as! UILabel).text else { return nil }
                        key = text
                    case is UITextView:
                        value = (subSubview as! UITextView).text ?? ""
                    default:
                        break
                }
            }
            
            inputFromTextFields.updateValue(value, forKey: key)
        }
        return inputFromTextFields
    }
    
    private func createButton(buttonInfo: ButtonInfo) -> UIView? {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let button = ButtonWithShadow()
        button.tag = buttonInfo.tag
        button.backgroundColor = buttonInfo.backgroundColor
        button.setTitle(buttonInfo.title, for: .normal)
        button.layer.cornerRadius = 10
        button.setTitleColor(buttonInfo.titleColor, for: .normal)
        guard let pointSize = button.titleLabel?.font.pointSize else { return nil }
        button.titleLabel?.font = .rounded(ofSize: pointSize, weight: .medium)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        containerView.addSubview(button)
        button.setFill()
        
        return containerView
    }
    
    private func loadingAnimation() {
        let totalCount = 3
        let duration = 1.0 / Double(totalCount) + 0.1
        
        let animation = UIViewPropertyAnimator(duration: 0.7, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0 / Double(totalCount), relativeDuration: duration) {
                    self?.titleLabel.alpha = 1
                    self?.titleLabel.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.bodyStackView.alpha = 1
                    self?.bodyStackView.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    self?.buttonPanel.alpha = 1
                    self?.buttonPanel.transform = .identity
                }
            })
        }
        
        animation.startAnimation()
    }
}

extension StandardAlertViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if let inputData = fetchInputFromTextFields() {
            delegate?.didGetData(inputData)
        }
    }
}
