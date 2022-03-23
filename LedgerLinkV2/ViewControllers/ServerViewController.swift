//
//  ServerViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-17.
//

/*
 Abstract:
 Shows the status of whether the advertiser and the browser in the network manager are running and how many peers are connected.
 It also privdes the ability to start, suspend, and disconnect the server.
 */

import UIKit
import MultipeerConnectivity

class ServerViewController: UIViewController {
    var statusButton: PulsatingButton!
    var stackView: UIStackView!
    var peerContainerView: UIView!
    var peerTitleLabel: UILabel!
    var peerLabel: UILabel!
    var underLineView: UIView!
    var logButton: UIButton!
    var isServerOn: Bool = false {
        didSet {
            /// Display the status button according to the status of the server
            setStatusButton()
        }
    } /// Shows the status of the server according to isServerOn. It's toggled at the time of the loading of VC or when the toggle button is tapped.
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        setConstraints()
        NetworkManager.shared.peerConnectedHandler = peerConnectedHandler
        NetworkManager.shared.peerDisconnectedHandler = peerDisconnectedHandler
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /// Provides the initial status of how many peers are connected upon loading
        let number = NetworkManager.shared.getConnectedPeerNumbers()
        peerLabel.text = "\(number) \(number == 1 ? "peer" : "peers")"
                
        /// Delay until the initial circle animation is finished
        /// Only start pulsing if the server is on
        guard self.isServerOn else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.statusButton.pulse()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// Stops the pulsating animation when away from the VC
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
        
        peerContainerView = UIView()
        peerContainerView.alpha = 0
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
        
        /// Translating animation upwards upon loading
        let yDelta = view.center.y - 200
        UIView.animate(withDuration: 0.8, delay: 2, options: .curveEaseIn) { [weak self] in
            self?.statusButton.transform = CGAffineTransform(translationX: 0, y: -yDelta)
        } completion: { [weak self] _ in
            ///  Display the server status after the completion of the animation
            self?.isServerOn = NetworkManager.shared.getServerStatus()
        }
        
        UIView.animate(withDuration: 1, delay: 3) { [weak self] in
            self?.peerContainerView.alpha = 1
        }
        
//        loadingAnimation()
    }
    
    private func setStatusButton() {
        let attTitle = self.createAttributedString(imageString: "circlebadge.fill", imageColor: isServerOn ? UIColor.green : UIColor.red, text: isServerOn ? " Server is on" : " Server is off", textColor: .lightGray)
        self.statusButton.setAttributedTitle(attTitle, for: .normal)
    }
    
    private func loadingAnimation() {
        let totalCount = 2
        let duration = 1.0 / Double(totalCount) + 0.1
        let yDelta = view.center.y - 200

        let animation = UIViewPropertyAnimator(duration: 2, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 2, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0 / Double(totalCount), relativeDuration: duration) {
                    self?.statusButton.transform = CGAffineTransform(translationX: 0, y: -yDelta)
                }
                
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.peerContainerView.alpha = 1
                }
            })
        }
        
        animation.startAnimation()
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
    
    /// Toggles the server on and off (adveriser, browser , and the player in the network manager). Turning off has two options: suspension and stop.
    /// Also toggles the title display of the statusButton
    private func toggleServer() {
        let isServerOn = NetworkManager.shared.getServerStatus()
        if isServerOn {
            stopServer()
        } else {
            startServer()
        }
    }
    
    private func startServer() {
        isServerOn = true
        NetworkManager.shared.start()
        statusButton.pulse()
    }
    
    private func stopServer() {
        
        /// Prompt user for suspension or diconnection of the server
        let buttonInfoArr = [
            ButtonInfo(title: "Refresh Server", tag: 2, backgroundColor: .black),
            ButtonInfo(title: "Stop Server", tag: 3, backgroundColor: .black)
        ]

        let alertVC = ActionSheetViewController(content: .button(buttonInfoArr))
        alertVC.buttonAction = { [weak self] tag in
            self?.dismiss(animated: true, completion: {
                switch tag {
                    case 2:
                        let attTitle = self?.createAttributedString(imageString: "circlebadge.fill", imageColor: UIColor.green, text: " Refreshed", textColor: .lightGray)
                        self?.statusButton.setAttributedTitle(attTitle, for: .normal)
                        
                        self?.statusButton.refreshAnimation()
                        
                        NetworkManager.shared.suspend()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            guard let self = self else { return }
                            let attTitle = self.createAttributedString(imageString: "circlebadge.fill", imageColor: self.isServerOn ? UIColor.green : UIColor.red, text: self.isServerOn ? " Server is on" : " Server is off", textColor: .lightGray)
                            self.statusButton.setAttributedTitle(attTitle, for: .normal)
                            NetworkManager.shared.start()
                        }
                        break
                    case 3:
                        NetworkManager.shared.disconnect()
                        self?.isServerOn = false
                        self?.statusButton.stopAnimation()
                        
                    default:
                        break
                }
            })
        }
        present(alertVC, animated: true)
    }
    
    /// Called whenever a new peer is connected
    func peerConnectedHandler(_ peerID: MCPeerID) {
        let number = NetworkManager.shared.getConnectedPeerNumbers()
        peerLabel.text = "\(number) \(number == 1 ? "peer" : "peers")"
    }
    
    /// Called whenever a peer is disconnected. This method and peerConnectedHandler provides a real time status of how many peers are connnected without having to create a constant listener.
    func peerDisconnectedHandler(_ peerID: MCPeerID) {
        let number = NetworkManager.shared.getConnectedPeerNumbers()
        
        DispatchQueue.main.async { [weak self] in
            self?.peerLabel.text = "\(number) \(number == 1 ? "peer" : "peers")"
        }
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
    var gradient: CAGradientLayer!
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
        
        gradient = CAGradientLayer()
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
    
    func animateCircle(duration: TimeInterval) {
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

    func refreshAnimation() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.toValue = 1.5
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
        animationGroup.repeatCount = 1
        animationGroup.isRemovedOnCompletion = true
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        
        pulseLayer.add(animationGroup, forKey: "pulse")
    }
    
    func stopAnimation() {
        self.layer.sublayers?.forEach { $0.removeAllAnimations() }
    }
}
