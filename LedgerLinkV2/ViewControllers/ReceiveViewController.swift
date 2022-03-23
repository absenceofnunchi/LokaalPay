//
//  ReceiveViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-09.
//

import UIKit

final class ReceiveViewController: WalletModalViewController {
    private var copyButton: WalletButtonView!
    private var shareButton: WalletButtonView!
    private var stackView: UIStackView!
    private var qrCodeImageView: UIImageView!
    private var qrCodeImage: UIImage!
    private var addressLabel: EdgeInsetLabel!
    private let alert = AlertView()
    private var infoType: InfoType!
    private var password: String?
    private var address: String!
    
    enum InfoType {
        case address
        case privateKey
    }
    
    init(infoType: InfoType, password: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        self.infoType = infoType
        self.password = password
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch infoType {
            case .address:
                getAddress()
            case .privateKey:
                getPrivateKey()
            default:
                break
        }
        
    }
    
    /// Get the user's own address to display as QR
    /// The wallet fetch doesn't take time, but the QR generation takes an indeterminate time so execute it asynchronously.
    func getAddress() {
        Node.shared.getMyAccount { [weak self] (acct, error) in
            if let error = error {
                self?.alert.show(error, for: self)
                return
            }
            
            if let acct = acct {
                let addressString = acct.address.address
                self?.address = addressString /// Retain it for the copy and the share feature
                self?.generateQRCode(from: addressString, completion: { image in
                    if let image = image {
                        DispatchQueue.main.async {
                            self?.qrCodeImage = image /// Retain it for sharing
                            self?.qrCodeImageView.image = image
                            self?.addressLabel.text = addressString /// Display the address on the label
                        }
                    }
                })
            }
        }
    }
    
    private func getPrivateKey() {
        guard let password = password,
              let privateKey = try? KeysService().getWalletPrivateKey(password: password) else { return }
        
        self.address = privateKey /// Retain it for the copy and the share feature
        generateQRCode(from: privateKey, completion: { [weak self] (image) in
            if let image = image {
                DispatchQueue.main.async {
                    self?.qrCodeImage = image /// Retain it for sharing
                    self?.qrCodeImageView.image = image
                    self?.addressLabel.text = privateKey /// Display the address on the label
                }
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadAnimation()
    }
    
    override func configureUI() {
        super.configureUI()
        titleLabel.text = "Receive Currency"

        qrCodeImageView = UIImageView(image: nil)
        qrCodeImageView.transform = CGAffineTransform(translationX: 0, y: 40)
        qrCodeImageView.alpha = 0
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = 10
        qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrCodeImageView)
        
        addressLabel = EdgeInsetLabel()
        addressLabel.textInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        addressLabel.numberOfLines = 0
        addressLabel.alpha = 0
        addressLabel.transform = CGAffineTransform(translationX: 0, y: 40)
        addressLabel.text = address
        addressLabel.textColor = .white
        addressLabel.layer.borderColor = UIColor.darkGray.cgColor
        addressLabel.layer.borderWidth = 0.5
        addressLabel.layer.cornerRadius = 10
        addressLabel.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addressLabel)
        
        copyButton = WalletButtonView(imageName: "square.on.square", labelName: "Copy")
        copyButton.buttonAction = { [weak self] in
            //            let pasteboard = UIPasteboard.general
            //            pasteboard.string = self?.address ?? ""
            DispatchQueue.main.async {
                self?.alert.fading(controller: self!, toBePasted: self?.address ?? "")
            }
        }
        
        shareButton = WalletButtonView(imageName: "square.and.arrow.up", labelName: "Share")
        shareButton.buttonAction = { [weak self] in
            let shareSheetVC = UIActivityViewController(activityItems: [self?.address ?? "", self?.qrCodeImage as Any], applicationActivities: nil)
            self?.present(shareSheetVC, animated: true, completion: nil)
            if let pop = shareSheetVC.popoverPresentationController {
                pop.sourceView = self?.view
                //                pop.sourceRect = CGRect(x: self?.view.bounds.midX, y: self?.view.bounds.height, width: 0, height: 0)
                pop.permittedArrowDirections = []
            }
        }
        
        stackView = UIStackView(arrangedSubviews: [copyButton, shareButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.transform = CGAffineTransform(translationX: 0, y: 40)
        stackView.alpha = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
    }
    
    override func setConstraints() {
        super.setConstraints()
        
        NSLayoutConstraint.activate([
            // qr
            qrCodeImageView.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 0),
            qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qrCodeImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            qrCodeImageView.heightAnchor.constraint(equalTo: qrCodeImageView.widthAnchor, multiplier: 1.05),
            
            // address label
            addressLabel.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 40),
            addressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addressLabel.heightAnchor.constraint(equalToConstant: 90),
            addressLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            
            // copy button
            copyButton.heightAnchor.constraint(equalToConstant: 100),
            
            // share button
            shareButton.heightAnchor.constraint(equalToConstant: 100),
            
            // stack view
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: addressLabel.bottomAnchor, constant: 40),
            stackView.heightAnchor.constraint(equalToConstant: 100),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
        ])
    }
    
    func generateQRCode(from string: String, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            let data = string.data(using: String.Encoding.ascii)
            
            if let filter = CIFilter(name: "CIQRCodeGenerator") {
                filter.setValue(data, forKey: "inputMessage")
                let transform = CGAffineTransform(scaleX: 5.5, y: 5.5)
                
                if let output = filter.outputImage?.transformed(by: transform) {
                    completion(UIImage(ciImage: output))
                }
            }
            
            completion(nil)
        }
    }
    
    /// Cascasding animation upon loading
    func loadAnimation() {
        let totalCount = 5
        let duration = 1.0 / Double(totalCount)
        
        let animation = UIViewPropertyAnimator(duration: 0.8, timingParameters: UICubicTimingParameters())
        animation.addAnimations {
            
            UIView.animateKeyframes(withDuration: 0, delay: 0, animations: { [weak self] in
                /// titleLabel and lineView inherited from the parent VC
                UIView.addKeyframe(withRelativeStartTime: 1 / Double(totalCount), relativeDuration: duration) {
//                    self?.titleLabel.alpha = 1
//                    self?.titleLabel.transform = .identity
//                    
//                    self?.lineView.alpha = 1
//                    self?.lineView.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 2 / Double(totalCount), relativeDuration: duration) {
                    self?.qrCodeImageView.alpha = 1
                    self?.qrCodeImageView.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 3 / Double(totalCount), relativeDuration: duration) {
                    self?.addressLabel.alpha = 1
                    self?.addressLabel.transform = .identity
                }
                
                UIView.addKeyframe(withRelativeStartTime: 4 / Double(totalCount), relativeDuration: duration) {
                    self?.stackView.alpha = 1
                    self?.stackView.transform = .identity
                }
                
//                UIView.addKeyframe(withRelativeStartTime: 4 / Double(totalCount), relativeDuration: duration) {
//                    self?.backgroundView.alpha = 1
//                    self?.backgroundView.transform = .identity
//                }
            })
        }
        
        animation.startAnimation()
    }
}


class EdgeInsetLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return textRect.inset(by: invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}
