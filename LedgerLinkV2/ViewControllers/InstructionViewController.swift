//
//  InstructionViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-19.
//

import UIKit
import CoreBluetooth

enum InitialSettings: String {
    case bluetooth = "Turn on bluetooth"
    case wifi = "Turn on WiFi"
    case powerMode = "Disable low power mode"
    
    var imageString: String {
        switch self {
            case .bluetooth:
                return "bluetooth"
            case .wifi:
                return "wifi"
            case .powerMode:
                return "battery.100"
        }
    }
}

class InstructionViewController: UIViewController {
    var titleLabel: UILabel!
    var bluetoothView: BluetoothView!
    var stackView: UIStackView!
    var manager: CBCentralManager!
    var bluetoothContainer: UIView!
    var wifiContainer: UIView!
    var batteryContainer: UIView!
    var buttonContainer: UIView! /// ButtonWithShadow needs a container
    var button: ButtonWithShadow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        setConstraints()
        loadingAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureSettings()
    }
    
    private func configureUI() {
        titleLabel = UILabel()
        let text = UIScreen.main.bounds.size.width > 500 ? "Please ensure the following:" : "Please ensure \nthe following:"
        let attText = createAttributedString(imageString: nil, imageColor: nil, text: text, fontSize: 30)
        titleLabel.attributedText = attText
        titleLabel.textColor = .lightGray
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        bluetoothView = BluetoothView(withColor: .white, andFrame: CGRect(origin: .zero, size: .zero))
        bluetoothView.translatesAutoresizingMaskIntoConstraints = false
        bluetoothView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        bluetoothContainer = createContainerView(setting: .bluetooth)
        wifiContainer = createContainerView(setting: .wifi)
        batteryContainer = createContainerView(setting: .powerMode)

        stackView = UIStackView(arrangedSubviews: [bluetoothContainer, wifiContainer, batteryContainer])
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonContainer)
        
        button = ButtonWithShadow()
        button.backgroundColor = .gray
        button.layer.cornerRadius = 10
        let buttonTitle = createAttributedString(imageString: nil, imageColor: nil, text: "Enter", textColor: .white, fontSize: 19)
        button.setAttributedTitle(buttonTitle, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        buttonContainer.addSubview(button)
        button.setFill()
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 100),
            titleLabel.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -50),
            
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            buttonContainer.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 60),
            buttonContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonContainer.heightAnchor.constraint(equalToConstant: 50),
            buttonContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
        ])
    }
    
    @objc func buttonPressed() {
        AuthSwitcher.enter()
    }
    
    /// Create a single arranged view for a stack view
    private func createContainerView(setting: InitialSettings) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.transform = CGAffineTransform(translationX: 0, y: 50)
        containerView.alpha = 0
        
        var imageView: UIView!
        if setting == .bluetooth {
            /// Bluetooth is drawn manually since the SF Symbol doesn't have one
            imageView = BluetoothView(withColor: .white, andFrame: CGRect(origin: .zero, size: .zero))
            imageView.tag = 10
        } else {
            imageView = createSFSymbol(setting: setting, color: .white)
            imageView.tag = 20
        }
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        containerView.addSubview(imageView)
        
        let label = UILabel()
        label.text = setting.rawValue
        label.textColor = .white
        label.font = UIFont.rounded(ofSize: 16, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(label)
            
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.2),
            
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 22),
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        
        return containerView
    }
    
    /// Locates label and image to update the color
    private func updateColor(setting: InitialSettings, color: UIColor) {
        for subview in stackView.arrangedSubviews {
            /// Using the label text here since tag doesn't work for some reason
            if let label = subview.allSubviews.filter({ ($0 as? UILabel)?.text == setting.rawValue }).first as? UILabel {
                label.textColor = color
            }

            /// Update the SF Symbol for wifi and power mode
//            if var imageView = subview.allSubviews.filter({ $0 is UIImageView }).first as? UIImageView {
//                print("imageView", imageView)
//                print("setting", setting)
//                imageView.image = nil
//                imageView = createSFSymbol(setting: setting, color: color)
//            }
            
//            if var imageView = subview.allSubviews.filter({ $0.tag == 20 }).first as? UIImageView {
//                imageView = createSFSymbol(setting: setting, color: color)
//                return
//            } else if let bluetoothView = subview.allSubviews.filter({ $0.tag == 10 }).first as? BluetoothView {
//                bluetoothView.color = color
//            }
        }
    }
    
    private func createSFSymbol(setting: InitialSettings, color: UIColor) -> UIImageView {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let image = UIImage(systemName: setting.imageString, withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        return imageView
    }
    
    /// Cascade animation
    private func loadingAnimation() {
        let totalCount = 3
        let duration = 1.0 / Double(totalCount) + 0.1
        
        let animation = UIViewPropertyAnimator(duration: 1, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                UIView.addKeyframe(withRelativeStartTime: 0 / Double(totalCount), relativeDuration: duration) {
                    self?.bluetoothContainer.alpha = 1
                    self?.bluetoothContainer.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
                    self?.wifiContainer.alpha = 1
                    self?.wifiContainer.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    self?.batteryContainer.alpha = 1
                    self?.batteryContainer.transform = .identity
                }
            })
        }
        
        animation.startAnimation()
    }
    
    private func configureSettings() {
        /// Monitors the bluetooth status
        manager = CBCentralManager()
        manager.delegate = self
    }
}

extension InstructionViewController: CBCentralManagerDelegate {
    // Monitor bluetooth
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOn:
                print("Bluetooth is on.")
                break
            case .poweredOff:
                break
            case .resetting:
                print("resetting")
                break
            case .unauthorized:
                break
            case .unsupported:
                break
            case .unknown:
                break
            default:
                break
        }
    }
}

class BluetoothView: UIView {
    var color: UIColor! {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    convenience init(withColor color: UIColor, andFrame frame: CGRect) {
        self.init(frame: frame)
        self.backgroundColor = .clear
        self.color = color
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let h = self.frame.height
        let y1 = h * 0.05
        let y2 = h * 0.25
        context?.move(to: CGPoint(x: y2, y: y2))
        context?.addLine(to: CGPoint(x: h - y2, y: h - y2))
        context?.addLine(to: CGPoint(x: h/2, y: h - y1))
        context?.addLine(to: CGPoint(x: h/2, y: y1))
        context?.addLine(to: CGPoint(x: h - y2, y: y2))
        context?.addLine(to: CGPoint(x: y2, y: h - y2))
        context?.setStrokeColor(color.cgColor)
        context?.setLineCap(.round)
        context?.setLineWidth(4)
        context?.strokePath()
    }
}
