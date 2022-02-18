//
//  MainViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-01.
//

import UIKit

class MainViewController: UIViewController {
    var hostButton: UIButton!
    var guestButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setConstraints()
    }
    
    func configureUI() {
        view.backgroundColor = .white
        
        hostButton = UIButton()
        hostButton.backgroundColor = .orange
        hostButton.tag = 0
        hostButton.setTitle("Host", for: .normal)
        hostButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        hostButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostButton)
        
        guestButton = UIButton()
        guestButton.backgroundColor = .red
        guestButton.tag = 1
        guestButton.setTitle("Guest", for: .normal)
        guestButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        guestButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(guestButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            hostButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            hostButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            hostButton.heightAnchor.constraint(equalToConstant: 50),
            hostButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            guestButton.bottomAnchor.constraint(equalTo: hostButton.bottomAnchor, constant: 100),
            guestButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            guestButton.heightAnchor.constraint(equalToConstant: 50),
            guestButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                let hostVC = HostViewController()
                navigationController?.pushViewController(hostVC, animated: true)
                break
            case 1:
                let guestVC = GuestViewController()
                navigationController?.pushViewController(guestVC, animated: true)
                break
            default:
                break
        }
    }
}
