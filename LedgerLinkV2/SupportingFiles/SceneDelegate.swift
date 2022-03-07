//
//  SceneDelegate.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-02-01.
//

import UIKit
import BackgroundTasks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        AuthSwitcher.updateRootVC()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        NetworkManager.shared.toggleBackgroundMode(false)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        NetworkManager.shared.toggleBackgroundMode(true)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        NetworkManager.shared.toggleBackgroundMode(false)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
//        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
        Node.shared.localStorage.coreDataStack.saveContext()
    }
    

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ledgerlink.refresh", using: nil) { [weak self] task in
            print("refresh task before", task)
            guard let task = task as? BGAppRefreshTask else { return }
            print("resfresh task", task)
            self?.handleAppRefresh(task: task)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ledgerlink.dataprocessing", using: nil) { [weak self] task in
            print("data processing task before", task)
            guard let task = task as? BGProcessingTask else { return }
            print("data processing task", task)
            self?.handleDataProcessing(task: task)
        }
    }
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var timer: DispatchSourceTimer?
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != .invalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

// MARK: - Refresh
extension SceneDelegate {
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ledgerlink.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10)
        
        do {
            print("request", request)
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule a new refresh task.
        scheduleAppRefresh()
        
        // Create an operation that performs the main part of the background task.
        //        let operation = RefreshAppContentsOperation()
        
        // Provide the background task with an expiration handler that cancels the operation.
        task.expirationHandler = {
            //            operation.cancel()
            print("refresh expired")
        }
        
        // Inform the system that the background task is complete
        // when the operation completes.
        //        operation.completionBlock = {
        //            task.setTaskCompleted(success: !operation.isCancelled)
        //        }
        
        task.setTaskCompleted(success: true)
        // Start the operation.
        //        operationQueue.addOperation(operation)
    }
}

// MARK: - Data Processing
extension SceneDelegate {
    func scheduleDataProcessing() {
        let request = BGProcessingTaskRequest(identifier: "com.ledgerlink.dataprocessing")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BG Data Proccessing error: \(error)")
        }
    }
    
    func handleDataProcessing(task: BGProcessingTask) {
        
        task.expirationHandler = {
        }
        
        task.setTaskCompleted(success: true)
    }
}


