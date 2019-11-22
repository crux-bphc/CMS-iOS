//
//  AppDelegate.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 09/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import IQKeyboardManagerSwift
import UserNotifications
import SDDownloadManager
import SafariServices
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let notificationCenter = UNUserNotificationCenter.current()
    let realm = try! Realm()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.setMinimumBackgroundFetchInterval(900)
        let options : UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) { (didAllow, error) in
            guard didAllow else {return}
            BackgroundFetch().setCategories()
//            if !didAllow {
//                print("The user denied notification permission.")
//            } else if didAllow {
//                BackgroundFetch().setCategories()
//            }
        }
        
        IQKeyboardManager.shared.enable = true
        if let realmUser = realm.objects(User.self).first {
            if Reachability.isConnectedToNetwork() {
                try! realm.write {
                    realmUser.isConnected = true
                    print("successfully set connected = true")
                }
            } else {
                try! realm.write {
                    realmUser.isConnected = false
                }
            }
            print(realmUser.isConnected as Any)
        } else {
            
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        if let realmUser = realm.objects(User.self).first {
            if Reachability.isConnectedToNetwork() {
                try! realm.write {
                    realmUser.isConnected = true
                }
            } else {
                try! realm.write {
                    realmUser.isConnected = false
                }
            }
            print(realmUser.isConnected as Any)
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let message = url.host
        let loginViewController = self.window?.rootViewController as! LoginViewController
        loginViewController.loginWithGoogle(input: message!)
        loginViewController.safariVC.dismiss(animated: true)
        return true
    }
    
    //    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    //        <#code#>
    //    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        SDDownloadManager.shared.backgroundCompletionHandler = completionHandler
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Reachability.isConnectedToNetwork(){
            let bkgObj = BackgroundFetch()
            bkgObj.sendNotification(title: "Testing",body: "Attempting to fetch data in background", identifier: "awjt8329")
            bkgObj.updateCourseContents { (newDataFound) in
                if newDataFound{
                    completionHandler(.newData)
                    print("found new data")
                }else{
                    completionHandler(.noData)
                    print("no new data found")
                }
            }
        }else{
            completionHandler(.failed)
            print("failed to background fetch")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Print message ID.
        UNUserNotificationCenter.current().delegate = self
        // Print full message.
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "Mark as Read" {

            //Mark as read function
        } else if response.actionIdentifier == "Open" {
//            Open file
        }
    }
}
