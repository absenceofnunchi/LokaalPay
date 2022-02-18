//
//  StatusViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-04.
//

import UIKit

class StatusViewController: UIViewController {
    var serverStatusLabel: UILabel!
    var peerNumberLabel: UILabel!
    var connectButton: UIButton!
    var isHosting: Bool! {
        didSet {
            serverStatusLabel?.text = isHosting ? "Server On" : "Server Off"
            connectButton?.setTitle(isHosting ? "Disconnect" : "Connect", for: .normal)
            connectButton?.tag = isHosting ? 1 : 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isHosting = NetworkManager.shared.getServerStatus()
        serverStatusLabel?.text = isHosting ? "Server On" : "Server Off"
        
        let number = NetworkManager.shared.getConnectedPeerNumbers() // not real time
        peerNumberLabel?.text = "\(number)"
    }
    
    func configureUI() {        
        view.backgroundColor = .white
        
        serverStatusLabel = UILabel()
        isHosting = NetworkManager.shared.getServerStatus()
        serverStatusLabel?.text = isHosting ? "Server On" : "Server Off"
        serverStatusLabel.textColor = .orange
        serverStatusLabel.layer.borderColor = UIColor.black.cgColor
        serverStatusLabel.layer.borderWidth = 1
        serverStatusLabel.textAlignment = .center
        serverStatusLabel.layer.cornerRadius = 10
        serverStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(serverStatusLabel)
        
        peerNumberLabel = UILabel()
        let number = NetworkManager.shared.getConnectedPeerNumbers() // not real time
        peerNumberLabel?.text = "\(number)"
        peerNumberLabel.textColor = .orange
        peerNumberLabel.layer.borderColor = UIColor.black.cgColor
        peerNumberLabel.layer.borderWidth = 1
        peerNumberLabel.textAlignment = .center
        peerNumberLabel.layer.cornerRadius = 10
        peerNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(peerNumberLabel)
        
        connectButton = UIButton()
        connectButton.backgroundColor = .black
        connectButton.layer.cornerRadius = 10
        connectButton.tag = 0
        connectButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(connectButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            serverStatusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            serverStatusLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            serverStatusLabel.heightAnchor.constraint(equalToConstant: 50),
            serverStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            peerNumberLabel.topAnchor.constraint(equalTo:serverStatusLabel.bottomAnchor, constant: 20),
            peerNumberLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
            peerNumberLabel.heightAnchor.constraint(equalToConstant: 50),
            peerNumberLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            connectButton.topAnchor.constraint(equalTo: peerNumberLabel.bottomAnchor, constant: 50),
            connectButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            connectButton.heightAnchor.constraint(equalToConstant: 50),
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    /// Create a listener (a server) that advertises its channel for the browsers to detect and connect.
    func startHosting() {
        NetworkManager.shared.start()
        isHosting = NetworkManager.shared.getServerStatus()
    }
    
    func pause() {
        NetworkManager.shared.suspend()
        isHosting = NetworkManager.shared.getServerStatus()
    }
    
    func disconnect() {
        NetworkManager.shared.disconnect()
        isHosting = NetworkManager.shared.getServerStatus()
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                startHosting()
                break
            case 1:
                pause()
            case 3:
                disconnect()
            default:
                break
        }
    }
}
