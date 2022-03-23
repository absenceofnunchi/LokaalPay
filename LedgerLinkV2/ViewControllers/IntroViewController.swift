//
//  IntroViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-05.
//

import UIKit

final class IntroViewController: UIViewController {
    private var imageView: UIImageView!
    private var containerView: UIView!
    private var titleContainerView: UIView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    private var createButton: UIButton!
    private var joinButton: UIButton!
    private let userDefaults = UserDefaults.standard
    private var selectedTag: Int! /// For passing the tag onto the custom transition animator
    
    final override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        setConstraints()
        
    }
    
//    override private func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        animateDial()
//    }
    
    private func configureUI() {
        view.backgroundColor = .black
        
        let bgImage = UIImage(named: "3")
        imageView = UIImageView(image: bgImage)
        imageView.contentMode = .scaleToFill
        imageView.tag = 200
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        containerView = UIView()
        containerView.backgroundColor = .black
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        titleLabel = UILabel()
        titleLabel.text = "Welcome!"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.rounded(ofSize: 30, weight: .heavy)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        subtitleLabel = UILabel()
        subtitleLabel.text = "Please select to enter."
        subtitleLabel.textColor = .white
        subtitleLabel.font = UIFont.rounded(ofSize: 15, weight: .heavy)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleContainerView = UIView()
        titleContainerView.translatesAutoresizingMaskIntoConstraints = false
        titleContainerView.addSubview(titleLabel)
        titleContainerView.addSubview(subtitleLabel)
        containerView.addSubview(titleContainerView)
        
        createButton = UIButton()
        createButton.tag = 2
        createButton.setTitle("Create Event", for: .normal)
        createButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        createButton.titleLabel?.font = .rounded(ofSize: 15, weight: .bold)
        createButton.layer.borderColor = UIColor.white.cgColor
        createButton.layer.borderWidth = 1
        createButton.layer.cornerRadius = 10
        createButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(createButton)
        createButton.titleLabel?.tag = 2 // The alpha of UILabel affects UIButton, tag the button's label with the same tag as the button to prevent the alpha change
        
        joinButton = UIButton()
        joinButton.tag = 1
        joinButton.setTitle("Join Event", for: .normal)
        joinButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        joinButton.titleLabel?.font = .rounded(ofSize: 15, weight: .bold)
        joinButton.layer.borderColor = UIColor.white.cgColor
        joinButton.layer.borderWidth = 1
        joinButton.layer.cornerRadius = 10
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(joinButton)
        joinButton.titleLabel?.tag = 1
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            
            containerView.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            createButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            createButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            createButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
            createButton.heightAnchor.constraint(equalToConstant: 60),
            
            titleContainerView.bottomAnchor.constraint(equalTo: createButton.topAnchor, constant: -50),
            titleContainerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleContainerView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
            titleContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: titleContainerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalTo: titleContainerView.heightAnchor, multiplier: 0.7),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),

            joinButton.topAnchor.constraint(equalTo: createButton.bottomAnchor, constant: 50),
            joinButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            joinButton.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.7),
            joinButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        selectedTag = sender.tag
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
        switch sender.tag {
            case 2:
                loginAsHost()
                break
            case 1:
                loginAsGuest()
                break
            default:
                break
        }
    }
    
    private func loginAsHost() {
        let vc = HostLoginViewController()
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
    private func loginAsGuest() {
        let vc = GuestLoginViewController()
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}

/// The transition delegate is located in the presenting VC instead of in a class of its own in order for the animation for dismiss delegate method to be called by it.
extension IntroViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let forwardAnimator = IsolateAnimator(selectedTag: selectedTag)
        return forwardAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BackwardAnimator(selectedTag: selectedTag)
    }
}
