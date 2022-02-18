//
//  QRCodeViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-15.
//

import UIKit

class QRCodeViewController: UIViewController {
    private var qrCodeImageView: UIImageView!
    private let alert = AlertView()
    var addressString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setConstraints()
    }
    
    func configureUI() {
        view.backgroundColor = .white
        
        if let address = addressString {
            let qrCodeImage = generateQRCode(from: address)
            qrCodeImageView = UIImageView(image: qrCodeImage)
        }  else {
            qrCodeImageView = UIImageView(image: nil)
        }
        qrCodeImageView.transform = CGAffineTransform(translationX: 0, y: 40)
        qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(qrCodeImageView)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            qrCodeImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            qrCodeImageView.widthAnchor.constraint(equalToConstant: 400),
            qrCodeImageView.heightAnchor.constraint(equalToConstant: 400),
            qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 5.5, y: 5.5)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
}
