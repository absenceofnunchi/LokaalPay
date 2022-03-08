//
//  ActionSheetViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-07.
//

import UIKit

final class ActionSheetViewController: UIViewController {
//    private var gradientView: GradientView!
    private var scrollView: UIScrollView!
    private var bgBlurView: BlurEffectContainerView!
    private var buttonInfoArr: [ButtonInfo]!
    private var miscInfoArr: [MiscInfo]!
    private var stackView: UIStackView!
    final var buttonAction: ((Int)->Void)?

    init(content: AlertContent) {
        super.init(nibName: nil, bundle: nil)
        
        self.transitioningDelegate = self
        if self.traitCollection.userInterfaceIdiom == .phone {
            self.modalPresentationStyle = .custom
        }
        
        switch content {
            case .button(let array):
                self.buttonInfoArr = array
            case .misc(let array):
                self.miscInfoArr = array
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        bgBlurView = BlurEffectContainerView(blurStyle: .light)
        view = bgBlurView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        configureContent()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        loadAnimation()
    }
    
    final override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentHeight: CGFloat = stackView.bounds.size.height + 100
        let contentSize = CGSize(width: view.bounds.width, height: contentHeight)
        scrollView.contentSize = contentSize
    }

    func configure() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        swipe.direction = .down
        view.addGestureRecognizer(swipe)
        
        scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.setFill()
        
//        gradientView = GradientView(colors: [UIColor.cyan.cgColor, UIColor.blue.cgColor, UIColor.red.cgColor])
//        gradientView.layer.cornerRadius = 10
//        gradientView.clipsToBounds = true
//        gradientView.backgroundColor = .black
//        view.addSubview(gradientView)
//        gradientView.setFill()
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            
        ])
    }

    private func configureContent() {
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alpha = 1
//        stackView.transform = CGAffineTransform(translationX: 0, y: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        if let buttonInfoArr = buttonInfoArr {
            buttonInfoArr.forEach ({
                guard let button = createButton(buttonInfo: $0) else { return }
                stackView.addArrangedSubview(button)
                
                NSLayoutConstraint.activate([
                    button.heightAnchor.constraint(equalToConstant: 50)
                ])
            })
            
            NSLayoutConstraint.activate([
                stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
                stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
                stackView.heightAnchor.constraint(equalToConstant: CGFloat(stackView.arrangedSubviews.count * 50 + 50))
            ])
        } else if let miscInfoArr = miscInfoArr {
            miscInfoArr.forEach {
                stackView.addArrangedSubview(MiscInfoView(MiscInfo: $0))
            }
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
                stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 20),
                stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -20),
                stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
            ])
        }
    }
    
    private func createButton(buttonInfo: ButtonInfo) -> UIView? {
        let containerView = UIView()
//        containerView.translatesAutoresizingMaskIntoConstraints = false
        let button = ButtonWithShadow()
        button.tag = buttonInfo.tag
        button.backgroundColor = buttonInfo.backgroundColor
        button.setTitle(buttonInfo.title, for: .normal)
        button.layer.cornerRadius = 10
        guard let pointSize = button.titleLabel?.font.pointSize else { return nil }
        button.titleLabel?.font = .rounded(ofSize: pointSize, weight: .medium)
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
        containerView.addSubview(button)
        button.setFill()

        return containerView
    }
    
    private func loadAnimation() {
        let totalCount = stackView.arrangedSubviews.count
        // If there is only one item
        let duration = stackView.allSubviews.count == 1 ? 0.5 : 1.0 / Double(totalCount) + 0.3
        
        let animation = UIViewPropertyAnimator(duration: 0.9, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                self?.stackView.arrangedSubviews.enumerated().forEach({ (index, element) in
                    UIView.addKeyframe(withRelativeStartTime: Double(index) / Double(totalCount), relativeDuration: duration) {
                        element.alpha = 1
                        element.transform = .identity
                    }
                })
            })
        }
        
        animation.startAnimation()
    }
    
    @objc final func swiped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc final func buttonPressed(_ sender: UIButton) {
        if let buttonAction = buttonAction {
            buttonAction(sender.tag)
        }
    }
}

extension ActionSheetViewController: UIViewControllerTransitioningDelegate {
    final func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let pc = PartialPresentationController(presentedViewController: presented, presenting: presenting)
        return pc
    }
    
    final func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

struct ButtonInfo {
    let title: String
    let tag: Int
    let backgroundColor: UIColor
    var titleColor: UIColor = .white
}

struct MiscInfo {
    let title: String
    let detail: String
}

enum AlertContent {
    case button([ButtonInfo])
    case misc([MiscInfo])
}

private class MiscInfoView: UIView {
    private var title: String!
    private var detail: String!
    private var titleLabel: UILabel!
    private var detailTextView: UITextView!
    
    init(MiscInfo: MiscInfo) {
        self.title = MiscInfo.title
        self.detail = MiscInfo.detail
        super.init(frame: .zero)
        
        configure()
        setConstraint()
        detailTextView.layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .rounded(ofSize: titleLabel.font.pointSize, weight: .bold)
        titleLabel.textColor = .lightGray
        titleLabel.sizeToFit()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(titleLabel)
        
        detailTextView = UITextView()
        detailTextView.sizeToFit()
        detailTextView.text = detail
        //        detailTextView.font = UIFont.systemFont(ofSize: 19)
        detailTextView.font = .rounded(ofSize: 19, weight: .regular)
        detailTextView.isEditable = false
        detailTextView.textColor = .lightGray
        detailTextView.isUserInteractionEnabled = false
        detailTextView.isScrollEnabled = false
        detailTextView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(detailTextView)
    }
    
    private func setConstraint() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5),
            
            detailTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            detailTextView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            detailTextView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            detailTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
