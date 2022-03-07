//
//  AuthSwitcher.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

/*
 Three stages to enter the app:
 1. IntroVC: User determines whether they are a host or a guest. IntroVC is reached when "isEntered" is false.  As one picks one's own status from this VC, "isHost" is determined.
 2. EventVC/JoinVC: User creates their account. This is determined when "isLoggedIn" is false
 3. tabVC(or loadMain()): This is the main part of the app. This is determined when "isLoggedIn" is set to true.
 */

import Foundation
import UIKit

class AuthSwitcher {
    static let userDefaults = UserDefaults.standard
    
    struct UserDefaultsKey {
        static let isEntered = "isEntered"
        static let isHost = "isHost"
        static let isloggedIn = "isLoggedIn"
    }
    
    static func updateRootVC() {
        let isLoggedIn = userDefaults.bool(forKey: UserDefaultsKey.isloggedIn)
        let isHost = userDefaults.bool(forKey: UserDefaultsKey.isHost)
        let isEntered = userDefaults.bool(forKey: UserDefaultsKey.isEntered)
        var rootViewController: UIViewController!

        if isEntered {
            if isHost {
                if isLoggedIn {
                    rootViewController = loadMain()
                } else {
                    rootViewController = EventViewController()
                }
            } else {
                if isLoggedIn {
                    rootViewController = loadMain()
                } else {
                    rootViewController = JoinViewController()
                }
            }
        } else {
            rootViewController = IntroViewController()
        }
        
        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDelegate = scene.delegate as? SceneDelegate,
              let windowScene = scene as? UIWindowScene else { return }
        
        sceneDelegate.window = UIWindow(windowScene: windowScene)
        sceneDelegate.window?.rootViewController = rootViewController
        sceneDelegate.window?.makeKeyAndVisible()
    }
    
    static func loadMain() -> UIViewController {
        let signupVC = SignupViewController()
        signupVC.tabBarItem = UITabBarItem(title: "Signup", image: UIImage(named: "lock"), selectedImage: UIImage(named: "lock"))
        
        let mainVC = MainViewController()
        let mainNav = UINavigationController(rootViewController: mainVC)
        mainNav.tabBarItem = UITabBarItem(title: "Connect", image: UIImage(named: "network"), selectedImage: UIImage(named: "network"))
        
        let walletVC = WalletViewController()
        walletVC.tabBarItem = UITabBarItem(title: "Wallet", image: UIImage(named: "folder"), selectedImage: UIImage(named: "folder"))
        
        let explorerVC = ExplorerViewController()
        let explorerNav = UINavigationController(rootViewController: explorerVC)
        explorerNav.tabBarItem = UITabBarItem(title: "Explorer", image: UIImage(named: "magnifyingglass"), selectedImage: UIImage(named: "magnifyingglass"))
        
        let tabBar = CustomTabBarController()
        tabBar.setViewControllers([signupVC, mainNav, walletVC, explorerNav], animated: true)
        return tabBar
    }
    
    static func logout() {
        userDefaults.set(false, forKey: UserDefaultsKey.isloggedIn)
        updateRootVC()
    }
    
    static func loginAsHost() {
        userDefaults.set(true, forKey: UserDefaultsKey.isloggedIn)
        userDefaults.set(true, forKey: UserDefaultsKey.isHost)
        updateRootVC()
    }
    
    static func loginAsGuest() {
        userDefaults.set(true, forKey: UserDefaultsKey.isloggedIn)
        userDefaults.set(false, forKey: UserDefaultsKey.isHost)
        updateRootVC()
    }
}
