//
//  AuthSwitcher.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-06.
//

/*
 Abstract:
 The controller to determine the state of authorization (logged in/logged out)
 */

import Foundation
import UIKit

class AuthSwitcher {
    static let userDefaults = UserDefaults.standard
    
    struct AuthUserDefaultsKey {
        static let onBoarded = "onBoarded" /// show the instructionVC if this is user's first time
        static let isHost = "isHost"
        static let isloggedIn = "isLoggedIn"
    }
    
    static func updateRootVC() {
        let isLoggedIn = userDefaults.bool(forKey: AuthUserDefaultsKey.isloggedIn)
        let isHost = userDefaults.bool(forKey: AuthUserDefaultsKey.isHost)
        let onBoarded = userDefaults.bool(forKey: AuthUserDefaultsKey.onBoarded)
        var rootViewController: UIViewController!

        if onBoarded {
            if isLoggedIn {
                rootViewController = loadMain(isHost: isHost)
            } else {
                rootViewController = IntroViewController()
            }
        } else {
            rootViewController = InstructionViewController()
        }

        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDelegate = scene.delegate as? SceneDelegate,
              let windowScene = scene as? UIWindowScene else { return }

        sceneDelegate.window = UIWindow(windowScene: windowScene)
        sceneDelegate.window?.rootViewController = rootViewController
        sceneDelegate.window?.makeKeyAndVisible()
        
        
//        guard let scene = UIApplication.shared.connectedScenes.first,
//              let sceneDelegate = scene.delegate as? SceneDelegate,
//              let windowScene = scene as? UIWindowScene else { return }
//
//        let rootViewController = loadMain(isHost: false)
//        sceneDelegate.window = UIWindow(windowScene: windowScene)
//        sceneDelegate.window?.rootViewController = rootViewController
//        sceneDelegate.window?.makeKeyAndVisible()
    }
    
    static func loadMain(isHost: Bool) -> UIViewController {
        
        let walletVC = WalletViewController()
        let walletNav = UINavigationController(rootViewController: walletVC)
        walletNav.tabBarItem = UITabBarItem(title: "Wallet", image: UIImage(systemName: "folder"), selectedImage: UIImage(systemName: "folder"))
    
        let serverVC = ServerViewController()
        let serverNav = UINavigationController(rootViewController: serverVC)
        serverNav.tabBarItem = UITabBarItem(title: "Connect", image: UIImage(systemName: "network"), selectedImage: UIImage(systemName: "network"))
        
        let explorerVC = ExplorerViewController()
        let explorerNav = UINavigationController(rootViewController: explorerVC)
        explorerNav.tabBarItem = UITabBarItem(title: "Explorer", image: UIImage(systemName: "magnifyingglass"), selectedImage: UIImage(systemName: "magnifyingglass"))
        
        let tabBar = CustomTabBarController()
        tabBar.setViewControllers([walletNav, serverNav, explorerNav], animated: true)
        return tabBar
    }
    
    static func logout() {
        userDefaults.set(false, forKey: AuthUserDefaultsKey.isloggedIn)
        userDefaults.set(false, forKey: AuthUserDefaultsKey.isHost)
        updateRootVC()
    }
    
    static func loginAsHost() {
        userDefaults.set(true, forKey: AuthUserDefaultsKey.isloggedIn)
        userDefaults.set(true, forKey: AuthUserDefaultsKey.isHost)
        updateRootVC()
    }
    
    static func loginAsGuest() {
        userDefaults.set(true, forKey: AuthUserDefaultsKey.isloggedIn)
        userDefaults.set(false, forKey: AuthUserDefaultsKey.isHost)
        updateRootVC()
    }
    
    static func enter() {
        userDefaults.set(false, forKey: AuthUserDefaultsKey.isloggedIn)
        userDefaults.set(true, forKey: AuthUserDefaultsKey.onBoarded)
        updateRootVC()
    }
}
