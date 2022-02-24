//
//  ExplorerViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-23.
//

import UIKit

class ExplorerViewController: UIViewController {
    private var blockButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
        setConstraints()
    }
    
    func configure() {
        view.backgroundColor = .white
        
        blockButton = UIButton()
        blockButton.setTitle("Blocks", for: .normal)
        blockButton.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        blockButton.tag = 0
        blockButton.backgroundColor = .black
        blockButton.layer.cornerRadius = 10
        blockButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blockButton)
    }
    
    func setConstraints() {
        NSLayoutConstraint.activate([
            blockButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            blockButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            blockButton.heightAnchor.constraint(equalToConstant: 50),
            blockButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                Node.shared.fetch { [weak self](blocks: [LightBlock]?, error: NodeError?) in
                    if let error = error {
                        print(error)
                    }
                        
                    if let blocks = blocks {
                        let detailVC = DetailTableViewController<LightBlock>()
                        detailVC.data = blocks
                        self?.navigationController?.pushViewController(detailVC, animated: true)
                    }
                }
                break
            default:
                break
        }
    }
}
