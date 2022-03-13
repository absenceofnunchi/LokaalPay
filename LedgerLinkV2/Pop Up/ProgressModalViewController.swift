//
//  ProgressModalViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-12.
//

import UIKit

extension Notification.Name {
    static let didUpdateProgress = Notification.Name("didUpdateProgress")
    static let willDismiss = Notification.Name("willDismiss")
    static let progressViewUpdate = Notification.Name("progressViewUpdate")
}

enum ProgressType: Int, CaseIterable {
    case host
    case guest
    
    func asString() -> String {
        switch self {
            case .host:
                return "Initializing as a host"
            case .guest:
                return "Initializing as a guest"
        }
    }
    
    var phases: [ProgressLevel] {
        switch self {
            case .host:
                return [.startServer, .createAccount]
            case .guest:
                return [.startServer, .downloadBlockchain, .createAccount]
        }
    }
}

enum ProgressLevel: Int {
    case startServer
    case downloadBlockchain
    case createAccount
    
    var asString: String {
        switch self {
            case .startServer:
                return "Server started"
            case .downloadBlockchain:
                return "Blockchain downloaded"
            case .createAccount:
                return "New account created"
        }
    }
}

class ProgressModalViewController: UIViewController {
    private var titleLabel: UILabel!
    var titleString: String?
    var timerLabel: UILabel!
    var timer: Timer!
    private var height: CGFloat!
    private lazy var customTransitioningDelegate = PopupTransitioningDelegate(height: height)
    private var stackView: UIStackView!
    private var completionCount: Int = 0
    private var doneButton: UIView!
    var progressView: UIProgressView!
    let progress = Progress(totalUnitCount: 3)
    private var alert = AlertView()
    private var progressType: ProgressType!
    
    init(height: CGFloat = 350, progressType: ProgressType) {
        super.init(nibName: nil, bundle: nil)
        self.height = height
        self.progressType = progressType
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = customTransitioningDelegate
        self.modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .didUpdateProgress, object: nil)
        //        NotificationCenter.default.removeObserver(self, name: .progressViewUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: .willDismiss, object: nil)
        
        if let timer = timer {
            timer.invalidate()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingAnimation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateProgress), name: .didUpdateProgress, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateProgressView), name: .progressViewUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWillDismiss), name: .willDismiss, object: nil)
    }
    
    //    @objc func onDidUpdateProgress(_ notification: Notification) {
    //        if let update = notification.userInfo?["update"] as? PostProgress,
    //           let postProgress = PostProgress(rawValue: update.rawValue) {
    //            DispatchQueue.main.async { [weak self] in
    //                if let sv = self?.stackView.arrangedSubviews[postProgress.rawValue],
    //                   let containerView = sv.viewWithTag(100) {
    //                    for case let imageView as UIImageView in containerView.subviews {
    //                        guard let checkImage = UIImage(systemName: "checkmark") else { return }
    //                        let configuration = UIImage.SymbolConfiguration(pointSize: 9, weight: .bold, scale: .small)
    //                        let finalImage = checkImage.withConfiguration(configuration).withTintColor(UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1), renderingMode: .alwaysOriginal)
    //                        imageView.image = finalImage
    //
    //                        self?.completionCount += 1
    //                        if self?.completionCount == PostProgress.allCases.count {
    //                            self?.doneButton.isHidden = false
    //                            self?.doneButton.isEnabled = true
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    @objc func onDidUpdateProgress(_ notification: Notification) {
        if let update = notification.userInfo?["update"] as? ProgressLevel,
           let progressPhaseIndex = progressType.phases.firstIndex(of: update) {
            DispatchQueue.main.async { [weak self] in
                if let sv = self?.stackView.arrangedSubviews[progressPhaseIndex],
                   let containerView = sv.viewWithTag(100) {
                    for case let imageView as UIImageView in containerView.subviews {
                        guard let checkImage = UIImage(systemName: "checkmark") else { return }
                        let configuration = UIImage.SymbolConfiguration(pointSize: 8, weight: .light, scale: .small)
                        let finalImage = checkImage.withConfiguration(configuration).withTintColor(UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1), renderingMode: .alwaysOriginal)
                        imageView.image = finalImage
                        
                        self?.completionCount += 1
                        if self?.completionCount == self?.progressType.phases.count {
                            guard let doneButton = self?.doneButton,
                                  let v = self?.view else { return }
                            
                            // If the warning modal view on, that means the user prompted the force close modal
                            // Remove it first
                            for case let warningModalView as WarningModalView in v.subviews {
                                warningModalView.removeFromSuperview()
                            }
                            
                            for case let button as ButtonWithShadow in doneButton.subviews {
                                let totalCount = 2
                                let duration = 1.0 / Double(totalCount) + 0.2
                                
                                let animation = UIViewPropertyAnimator(duration: 1, timingParameters: UICubicTimingParameters())
                                animation.addAnimations {
                                    UIView.animateKeyframes(withDuration: 0, delay: 0, animations: {
                                        UIView.addKeyframe(withRelativeStartTime: 0 / Double(totalCount), relativeDuration: duration) {
                                            doneButton.alpha = 0
                                        }
                                        
                                        UIView.addKeyframe(withRelativeStartTime: 0 / Double(totalCount), relativeDuration: duration + 0.2) {
                                            doneButton.alpha = 1
                                            button.setTitle("Success!", for: .normal)
                                            button.setTitleColor(.white, for: .normal)
                                            button.backgroundColor = UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
                                            button.tag = 0
                                        }
                                    })
                                }
                                
                                animation.startAnimation()
                            }
                            
                            if let timer = self?.timer {
                                timer.invalidate()
                            }
                            
                            self?.timerLabel.text = ""
                        }
                    }
                }
            }
        }
    }
    
    @objc func onDidUpdateProgressView(_ notification: Notification) {
        //        print("onDidUpdateProgressView")
        //        guard let update = notification.userInfo?["update"] as? Int64 else { return }
        //        print("update", update)
        //        progress.completedUnitCount += update
        //        let progressFloat = Float(self.progress.fractionCompleted)
        //        progressView.setProgress(progressFloat, animated: true)
        //
        //        if progress.completedUnitCount >= progress.totalUnitCount {
        //            delay(0.3) { [weak self] in // delay to let progress bar to complete the animation
        //                self?.progressView.isHidden = true
        //            }
        //        }
    }
    
    @objc func onWillDismiss(_ notification: Notification) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadingAnimation() {
        // Stack view subviews + title label + timer label
        let totalCount = stackView.arrangedSubviews.count + 2
        let duration = 1.0 / Double(totalCount) + 0.2
        
        let animation = UIViewPropertyAnimator(duration: 0.7, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0 / Double(totalCount), relativeDuration: duration) {
                    self?.titleLabel.transform = .identity
                    self?.timerLabel.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 0 / Double(totalCount), relativeDuration: duration + 0.2) {
                    self?.titleLabel.alpha = 1
                    self?.timerLabel.alpha = 1
                }
                
                self?.stackView.arrangedSubviews.enumerated().forEach({ (index, v) in
                    UIView.addKeyframe(withRelativeStartTime: Double(index + 2) / Double(totalCount), relativeDuration: duration) {
                        v.alpha = 1
                        v.transform = .identity
                    }
                })
                
                guard let stackViewCount = self?.stackView.arrangedSubviews.count else { return }
                
                UIView.addKeyframe(withRelativeStartTime: Double(2 + stackViewCount) / Double(totalCount), relativeDuration: duration + 0.2) {
                    self?.doneButton.alpha = 1
                    self?.doneButton.transform = .identity
                }
            })
        }
        
        animation.startAnimation()
    }
}

private extension ProgressModalViewController {
    private func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        
        titleLabel = UILabel()
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 5)
        titleLabel.text = titleString
        //        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.font = UIFont.rounded(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let oneDotImage = createProgressImage(dotCount: .one)
        let twoDotImage = createProgressImage(dotCount: .two)
        let threeDotImage = createProgressImage(dotCount: .three)
        let images = [oneDotImage, twoDotImage, threeDotImage]
        let animation = UIImage.animatedImage(with: images, duration: 1.5)
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        for i in 0..<progressType.phases.count {
            let containerView = UIView()
            containerView.alpha = 0
            containerView.transform = CGAffineTransform(translationX: 0, y: 5)
            containerView.tag = 100
            
            let dotsImageView = UIImageView()
            dotsImageView.contentMode = .scaleAspectFit
            dotsImageView.animationRepeatCount = .max
            dotsImageView.image = animation
            dotsImageView.startAnimating()
            dotsImageView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(dotsImageView)
            
            let progressLabel = UILabel()
            guard let progressLevel = ProgressLevel(rawValue: i) else { return }
            progressLabel.text = progressLevel.asString
            progressLabel.font = UIFont.rounded(ofSize: 13, weight: .medium)
            progressLabel.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(progressLabel)
            
            NSLayoutConstraint.activate([
                progressLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                progressLabel.heightAnchor.constraint(equalTo: containerView.heightAnchor),
                progressLabel.trailingAnchor.constraint(equalTo: dotsImageView.leadingAnchor),
                
                dotsImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                dotsImageView.heightAnchor.constraint(equalTo: containerView.heightAnchor),
                dotsImageView.widthAnchor.constraint(equalToConstant: 35)
            ])
            
            stackView.addArrangedSubview(containerView)
        }
        view.addSubview(stackView)
        
        let cancelButtonInfo = ButtonInfo(
            title: "Cancel",
            tag: 1,
            backgroundColor: UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1),
            titleColor: UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
        )
        doneButton = createButton(buttonInfo: cancelButtonInfo)
        doneButton.alpha = 0
        doneButton.transform = CGAffineTransform(translationX: 0, y: 5)
        view.addSubview(doneButton)
        
        progressView = UIProgressView()
        progressView.isHidden = true
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        //        switch paymentMethod {
        //            case .auctionBeneficiary, .escrow:
        //                progressView.isHidden = false
        //            default:
        //                progressView.isHidden = true
        //        }
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            timerLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.heightAnchor.constraint(equalToConstant: 50),
            
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.50),
            
            progressView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -10),
            progressView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            doneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            doneButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            doneButton.heightAnchor.constraint(equalToConstant: 40),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setTimer () {
        var estimatedDuration = 120
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (Timer) in
            if let converted = self?.secondsToHoursMinutesSeconds(seconds: estimatedDuration) {
                if estimatedDuration >= 0 {
                    var min, sec: String!
                    
                    if converted.1 < 10 {
                        min = "0\(converted.1)"
                    } else {
                        min = "\(converted.1)"
                    }
                    
                    if converted.2 < 10 {
                        sec = "0\(converted.2)"
                    } else {
                        sec = "\(converted.2)"
                    }
                    
                    let countdown = "Estimated Duration: \(min ?? "00"):\(sec ?? "00")"
                    self?.timerLabel.text = countdown
                    
                    estimatedDuration -= 1
                } else {
                    Timer.invalidate()
                    self?.timerLabel.text = "Estimated Duration: 00:00"
                }
            }
        }
    }
    
    enum DotCount {
        case one, two, three
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
    
    private func createProgressImage(dotCount: DotCount) -> UIImage {
        let imageBounds = CGRect(origin: .zero, size: CGSize(width: 35, height: 25))
        let renderer = UIGraphicsImageRenderer(bounds: imageBounds)
        var image: UIImage!
        let radius = (min(imageBounds.width, imageBounds.height)) / 20
        
        switch dotCount {
            case .one:
                image = renderer.image { (_) in
                    let center = CGPoint(x: imageBounds.minX + radius, y: imageBounds.midY)
                    let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.gray.setFill()
                    path.fill()
                }
            case .two:
                image = renderer.image { (_) in
                    let center = CGPoint(x: imageBounds.minX + radius, y: imageBounds.midY)
                    let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path.fill()
                    
                    let center2 = CGPoint(x: imageBounds.midX, y: imageBounds.midY)
                    let path2 = UIBezierPath(arcCenter: center2, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path2.fill()
                }
            case .three:
                image = renderer.image { (_) in
                    let center = CGPoint(x: imageBounds.minX + radius, y: imageBounds.midY)
                    let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path.fill()
                    
                    let center2 = CGPoint(x: imageBounds.midX, y: imageBounds.midY)
                    let path2 = UIBezierPath(arcCenter: center2, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path2.fill()
                    
                    let center3 = CGPoint(x: imageBounds.maxX - radius, y: imageBounds.midY)
                    let path3 = UIBezierPath(arcCenter: center3, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    UIColor.lightGray.setFill()
                    path3.fill()
                }
        }
        
        return image
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                dismiss(animated: true, completion: nil)
            case 1:
                let warningModalView = WarningModalView()
                warningModalView.alpha = 0
                warningModalView.backgroundColor = .white
                view.addSubview(warningModalView)
                warningModalView.setFill()
                
                UIView.animate(withDuration: 0.2) {
                    warningModalView.alpha = 1
                }
                
            default:
                break
        }
    }
}

class WarningModalView: UIView {
    var titleLabel: UILabel!
    var messageLabel: UILabel!
    var stopButton: UIView!
    var cancelButton: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configure()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension WarningModalView {
    private func configure() {
        titleLabel = UILabel()
        titleLabel.text = "Force Close"
        titleLabel.sizeToFit()
        titleLabel.font = UIFont.rounded(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
        
        messageLabel = UILabel()
        messageLabel.text = "Are you sure you want to stop the process? The cost that have already incurred will not be recoverable."
        messageLabel.font = UIFont.rounded(ofSize: messageLabel.font.pointSize, weight: .light)
        messageLabel.numberOfLines = 0
        messageLabel.sizeToFit()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(messageLabel)
        
        let stopButtonInfo = ButtonInfo(
            title: "Stop",
            tag: 0,
            backgroundColor: .red,
            titleColor: .white
        )
        
        stopButton = createButton(buttonInfo: stopButtonInfo)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stopButton)
        
        let cancelButtonInfo = ButtonInfo(
            title: "Continue",
            tag: 1,
            backgroundColor: UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1),
            titleColor: UIColor(red: 25/255, green: 69/255, blue: 107/255, alpha: 1)
        )
        
        cancelButton = createButton(buttonInfo: cancelButtonInfo)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(cancelButton)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 20),
            
            messageLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            
            stopButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            stopButton.heightAnchor.constraint(equalToConstant: 40),
            stopButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.4),
            stopButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),
            
            cancelButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.4),
            cancelButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -20),
        ])
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
    
    @objc func buttonPressed(_ sender: UIButton) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        
        switch sender.tag {
            case 0:
                //  NotificationCenter.default.post(name: .didUpdateProgress, object: nil, userInfo: update0)
                guard let vc = self.superview?.next as? ProgressModalViewController else { return }
                vc.dismiss(animated: true, completion: nil)
                break
            case 1:
                self.removeFromSuperview()
                break
            default:
                break
        }
    }
}
