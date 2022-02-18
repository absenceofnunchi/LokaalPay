//
//  PasscodeViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-02.
//

/*
 See LICENSE folder for this sample’s licensing information.
 Abstract:
 Implement the passcode entry view controller.
 */

//import UIKit
//import Network
//
//class PasscodeViewController: UIViewController {
//    var passcodeField: UITextField!
//    var titleLabel: UILabel!
//    var joinButton: UIButton!
//    var sendButton: UIButton!
//    var browseResult: NWBrowser.Result?
//    var peerListViewController: PeerListViewController?
//    var hasPlayedGame = false
//    var timer: DispatchSourceTimer?
//    var audioButton: UIButton!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        configure()
//        setConstraints()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        if hasPlayedGame {
//            navigationController?.popToRootViewController(animated: false)
//            hasPlayedGame = false
//        }
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        stopTimer()
//    }
//
//    func configure() {
//        view.backgroundColor = .white
//
//        passcodeField = UITextField()
//        passcodeField.layer.cornerRadius = 10
//        passcodeField.layer.borderWidth = 1
//        passcodeField.layer.borderColor = UIColor.black.cgColor
//        passcodeField.text = "111111"
//        passcodeField.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(passcodeField)
//
//        titleLabel = UILabel()
//        titleLabel.layer.cornerRadius = 10
//        titleLabel.layer.borderWidth = 1
//        titleLabel.layer.borderColor = UIColor.black.cgColor
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(titleLabel)
//
//        joinButton = UIButton()
//        joinButton.backgroundColor = .black
//        joinButton.layer.cornerRadius = 10
//        joinButton.tag = 0
//        joinButton.setTitle("Join", for: .normal)
//        joinButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
//        joinButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(joinButton)
//
//        sendButton = UIButton()
//        sendButton.backgroundColor = .blue
//        sendButton.layer.cornerRadius = 10
//        sendButton.tag = 1
//        sendButton.setTitle("send", for: .normal)
//        sendButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
//        sendButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(sendButton)
//
//        audioButton = UIButton()
//        audioButton.backgroundColor = .blue
//        audioButton.layer.cornerRadius = 10
//        audioButton.tag = 2
//        audioButton.setTitle("Audio", for: .normal)
//        audioButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
//        audioButton.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(audioButton)
//
//        if let browseResult = browseResult,
//           case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = browseResult.endpoint {
//            titleLabel.text = "Join \(name)"
//        }
//    }
//
//    func setConstraints() {
//        NSLayoutConstraint.activate([
//            passcodeField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
//            passcodeField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
//            passcodeField.heightAnchor.constraint(equalToConstant: 50),
//            passcodeField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            titleLabel.topAnchor.constraint(equalTo: passcodeField.bottomAnchor, constant: 30),
//            titleLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
//            titleLabel.heightAnchor.constraint(equalToConstant: 50),
//            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            joinButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
//            joinButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
//            joinButton.heightAnchor.constraint(equalToConstant: 50),
//            joinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            sendButton.topAnchor.constraint(equalTo: joinButton.bottomAnchor, constant: 30),
//            sendButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
//            sendButton.heightAnchor.constraint(equalToConstant: 50),
//            sendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//
//            audioButton.topAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: 30),
//            audioButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
//            audioButton.heightAnchor.constraint(equalToConstant: 50),
//            audioButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//        ])
//    }
//
//    @objc func buttonPressed(_ sender: UIButton) {
//        switch sender.tag {
//            case 0:
//                hasPlayedGame = true
//
//                if let passcode = passcodeField.text,
//                   let browseResult = browseResult,
//                   let peerListViewController = peerListViewController {
//                    sharedConnection = PeerConnection(endpoint: browseResult.endpoint,
//                                                      interface: browseResult.interfaces.first,
//                                                      passcode: passcode,
//                                                      delegate: peerListViewController)
//                }
//                break
//            case 1:
////                startTimer()
//                print("send move")
//                sharedConnection?.sendMove("Hello!")
//                break
//            case 2:
//                let audioVC = AudioViewController()
//                navigationController?.pushViewController(audioVC, animated: true)
//                break
//            default:
//                break
//        }
//    }
//
//    func startTimer() {
//        let queue = DispatchQueue(label: "com.domain.app.timer")  // you can also use `DispatchQueue.main`, if you want
//        timer = DispatchSource.makeTimerSource(queue: queue)
//        timer!.schedule(deadline: .now(), repeating: .seconds(5))
//        timer!.setEventHandler {
//            print("send move")
//            sharedConnection?.sendMove("Hello!")
//        }
//        timer!.resume()
//    }
//
//    func stopTimer() {
//        timer = nil
//    }
//}
