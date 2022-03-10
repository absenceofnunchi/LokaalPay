//
//  SendViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-09.
//

import UIKit

final class SendViewController: UIViewController {
    private var dismissButton: DownArrow!
    private var destinationTextField: UITextField!
    private var amountTextField: UITextField!
    private var scanButton: UIButton!
    private var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadAnimation()
    }
    
    func configureUI() {
        view.backgroundColor = .black
        
        self.dismissButton = DownArrow(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        self.dismissButton.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.dismissButton)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.view.addGestureRecognizer(tap)
        
        destinationTextField = createTextField(placeHolderText: " Recipient Address", placeHolderImageString: "magnifyingglass")
        destinationTextField.alpha = 0
        destinationTextField.transform = CGAffineTransform(translationX: 0, y: 40)
        destinationTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(destinationTextField)
        
        guard let scanButtonImage = UIImage(systemName: "qrcode.viewfinder") else { return }
        scanButton = UIButton.systemButton(with: scanButtonImage.withTintColor(.white, renderingMode: .alwaysOriginal), target: self, action: #selector(buttonHandler(_:)))
        scanButton.backgroundColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        scanButton.transform = CGAffineTransform(translationX: 0, y: 40)
        scanButton.layer.cornerRadius = 7
        scanButton.alpha = 0
        scanButton.tag = 0
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanButton)
        
        amountTextField = createTextField(placeHolderText: " Amount to send", placeHolderImageString: "creditcard")
        amountTextField.alpha = 0
        amountTextField.transform = CGAffineTransform(translationX: 0, y: 40)
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(amountTextField)
        
        sendButton = UIButton()
        sendButton.transform = CGAffineTransform(translationX: 0, y: 40)
        sendButton.alpha = 0
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(buttonHandler(_:)), for: .touchUpInside)
        sendButton.tag = 4
        sendButton.backgroundColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1)
        sendButton.layer.cornerRadius = 7
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sendButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            destinationTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            destinationTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            destinationTextField.trailingAnchor.constraint(equalTo: scanButton.leadingAnchor, constant: -10),
            destinationTextField.heightAnchor.constraint(equalToConstant: 50),
            
            scanButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            scanButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.widthAnchor.constraint(equalToConstant: 50),
            
            amountTextField.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 50),
            amountTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            amountTextField.heightAnchor.constraint(equalToConstant: 50),
            
            sendButton.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 50),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    func loadAnimation() {
        let totalCount = 3
        let duration = 1.0 / Double(totalCount)
        
        let animation = UIViewPropertyAnimator(duration: 0.5, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.destinationTextField.alpha = 1
                    self?.destinationTextField.transform = .identity
                    
                    self?.scanButton.alpha = 1
                    self?.scanButton.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    
                    self?.amountTextField.alpha = 1
                    self?.amountTextField.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 3 / Double(totalCount) - 0.1, relativeDuration: duration) {
                    self?.sendButton.alpha = 1
                    self?.sendButton.transform = .identity
                }
                
            })
        }
        
        animation.startAnimation()
    }
    
    @objc func buttonHandler(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                let scannerVC = ScannerViewController()
                scannerVC.delegate = self
                scannerVC.modalPresentationStyle = .fullScreen
                self.present(scannerVC, animated: true, completion: nil)
                break
            default:
                break
        }
    }
    
    @objc func tapped(_ sender: UIGestureRecognizer) {
        dismiss(animated: true)
    }
}

extension SendViewController: ScannerDelegate {
    
    // MARK: - scannerDidOutput
    func scannerDidOutput(code: String) {
        destinationTextField.text = code
    }
}

class DownArrow: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.createArrow()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createArrow() {
        let arrowPath = UIBezierPath()
        arrowPath.move(to: .zero)
        arrowPath.addLine(to: CGPoint(x: self.bounds.width/2, y: self.bounds.width/2))
        arrowPath.addLine(to: CGPoint(x: self.bounds.width, y: 0))
        
        let arrowLayer = CAShapeLayer()
        arrowLayer.path = arrowPath.cgPath
        arrowLayer.fillColor = UIColor.clear.cgColor
        arrowLayer.strokeColor = UIColor.lightGray.cgColor
        arrowLayer.lineWidth = 2
        arrowLayer.opacity = 0.5
        arrowLayer.lineCap = .round
        arrowLayer.bounds = self.frame
        
        let arrowLayer2 = CAShapeLayer()
        arrowLayer2.path = arrowPath.cgPath
        arrowLayer2.fillColor = UIColor.clear.cgColor
        arrowLayer2.strokeColor = UIColor.lightGray.cgColor
        arrowLayer2.lineWidth = 2
        arrowLayer2.opacity = 0.4
        arrowLayer2.lineCap = .round
        arrowLayer2.bounds = self.frame
        
        self.layer.addSublayer(arrowLayer)
//        self.layer.addSublayer(arrowLayer2)
        
//        arrowLayer2.transform = CATransform3DMakeTranslation(0, 20, 0)
//        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.transform))
//        animation.toValue = 20
//        animation.fromValue = 0
//        animation.duration = 0.4
//        animation.autoreverses = true
//        animation.repeatCount = .infinity
//        animation.timingFunction = CAMediaTimingFunction(name: .linear)
//        animation.valueFunction = CAValueFunction(name: .translateY)
//        animation.isRemovedOnCompletion = false
//        arrowLayer2.add(animation, forKey: nil)
    }
    
}
