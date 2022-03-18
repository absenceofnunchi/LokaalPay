//
//  ServerViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-17.
//

import UIKit

class ServerViewController: UIViewController {
    var statusButton: PulsatingButton!
    var stackView: UIStackView!
    var peerContainerView: UIView!
    var peerTitleLabel: UILabel!
    var peerLabel: UILabel!
    var underLineView: UIView!
    var logButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /// Delay until the initial circle animation is finished
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.statusButton.pulse()
        }
        
        let number = NetworkManager.shared.getConnectedPeerNumbers()
        peerLabel.text = "\(number) \(number == 1 ? "peer" : "peers")"
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.statusButton.stopAnimation()
    }
    
    private func configureUI() {
        title = "Connect"
        view.backgroundColor = .black
        navigationController?.setNavigationBarHidden(true, animated: false)

        statusButton = PulsatingButton(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        statusButton.center = self.view.center
        statusButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        statusButton.tag = 0
        view.addSubview(statusButton)

        let yDelta = view.center.y - 200
        UIView.animate(withDuration: 0.8, delay: 2, options: .curveEaseIn) { [weak self] in
            self?.statusButton.transform = CGAffineTransform(translationX: 0, y: -yDelta)
        } completion: { [weak self] _ in
            
//            let isServerOn = NetworkManager.shared.getServerStatus()
            let isServerOn = true
            let attTitle = self?.createAttributedString(imageString: "circlebadge.fill", imageColor: isServerOn ? UIColor.green : UIColor.red, text: isServerOn ? " Server is on" : " Server is off", textColor: .lightGray)
            self?.statusButton.setAttributedTitle(attTitle, for: .normal)
        }
        
        peerContainerView = UIView()
        peerContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(peerContainerView)
        
        peerTitleLabel = UILabel()
        peerTitleLabel.textAlignment = .center
        peerTitleLabel.attributedText = createAttributedString(imageString: "iphone", imageColor: UIColor.gray, text: " Connected Peers:", textColor: .lightGray)
        peerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        peerContainerView.addSubview(peerTitleLabel)
        
        peerLabel = UILabel()
        peerLabel.attributedText = createAttributedString(imageString: nil, imageColor: nil, text: " 0 Peers", textColor: .lightGray)
        peerLabel.textAlignment = .center
        peerLabel.translatesAutoresizingMaskIntoConstraints = false
        peerContainerView.addSubview(peerLabel)
        
        underLineView = UIView()
        underLineView.layer.borderWidth = 0.5
        underLineView.layer.borderColor = UIColor.gray.cgColor
        underLineView.translatesAutoresizingMaskIntoConstraints = false
        peerContainerView.addSubview(underLineView)
                
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            peerContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            peerContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            peerContainerView.heightAnchor.constraint(equalToConstant: 50),
            peerContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            peerTitleLabel.leadingAnchor.constraint(equalTo: peerContainerView.leadingAnchor),
            peerTitleLabel.topAnchor.constraint(equalTo: peerContainerView.topAnchor),
            peerTitleLabel.bottomAnchor.constraint(equalTo: peerContainerView.bottomAnchor),
            peerTitleLabel.widthAnchor.constraint(equalTo: peerContainerView.widthAnchor, multiplier: 0.5),
            
            peerLabel.trailingAnchor.constraint(equalTo: peerContainerView.trailingAnchor),
            peerLabel.topAnchor.constraint(equalTo: peerContainerView.topAnchor),
            peerLabel.bottomAnchor.constraint(equalTo: peerContainerView.bottomAnchor),
            peerLabel.widthAnchor.constraint(equalTo: peerContainerView.widthAnchor, multiplier: 0.5),
            
            underLineView.topAnchor.constraint(equalTo: peerLabel.bottomAnchor),
            underLineView.widthAnchor.constraint(equalTo: peerContainerView.widthAnchor),
            underLineView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            toggleServer()
            break
        default:
            break
        }
    }
    
    private func toggleServer() {
        let isServerOn = NetworkManager.shared.getServerStatus()
        if isServerOn {
            stopServer()
        } else {
            startServer()
        }
    }
    
    private func startServer() {
        NetworkManager.shared.start()
    }
    
    private func stopServer() {
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
    }
}

class PulsatingButton: UIButton {
    let pulseLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.strokeColor = UIColor.blue.withAlphaComponent(0.9).cgColor
        shape.lineWidth = 5
        shape.fillColor = UIColor.clear.cgColor
        shape.lineCap = .round
        shape.opacity = 0
        return shape
    }()
    
    var backgroundLayer: CAShapeLayer!
    
    init() {
        super.init(frame: .zero)
        setupShapes()
        animateCircle(duration: 2)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShapes()
        animateCircle(duration: 2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError()
    }
    
    fileprivate func setupShapes() {
        setNeedsLayout()
        layoutIfNeeded()
                
        let circularPath = UIBezierPath(arcCenter: self.center, radius: bounds.size.height/2 - 10, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        pulseLayer.frame = bounds
        pulseLayer.path = circularPath.cgPath
        pulseLayer.position = self.center
        self.layer.addSublayer(pulseLayer)
        
        backgroundLayer = CAShapeLayer()
        backgroundLayer.path = circularPath.cgPath
        backgroundLayer.lineWidth = 15
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = UIColor.black.cgColor
        backgroundLayer.lineCap = .round
//        backgroundLayer.strokeEnd = 0
        
        let gradient = CAGradientLayer()
        gradient.frame =  self.bounds
        gradient.colors = [UIColor.blue.cgColor, UIColor.red.cgColor]
        gradient.mask = backgroundLayer
        self.layer.addSublayer(gradient)
    }
    
    func pulse() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.toValue = 1.3
        scaleAnimation.duration = 1.0
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleAnimation.autoreverses = false
        scaleAnimation.isAdditive = false

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1
        opacityAnimation.autoreverses = false
        opacityAnimation.toValue = 0
        opacityAnimation.duration = 1
        opacityAnimation.isAdditive = false
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 5
        animationGroup.repeatCount = .infinity
        animationGroup.isRemovedOnCompletion = true
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        
        pulseLayer.add(animationGroup, forKey: "pulse")
    }
    
    private func animateCircle(duration: TimeInterval) {
        // We want to animate the strokeEnd property of the circleLayer
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        
        // Set the animation duration appropriately
        animation.duration = duration
        
        // Animate from 0 (no circle) to 1 (full circle)
        animation.fromValue = 0
        animation.toValue = 1
        
        // Do a linear animation (i.e The speed of the animation stays the same)
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        // Set the circleLayer's strokeEnd property to 1.0 now so that it's the
        // Right value when the animation ends
        backgroundLayer.strokeEnd = 1.0
        
        // Do the actual animation
        backgroundLayer.add(animation, forKey: "animateCircle")
    }
    
    func stopAnimation() {
        self.layer.sublayers?.forEach { $0.removeAllAnimations() }
    }
}
