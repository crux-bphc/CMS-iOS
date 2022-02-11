//
//  AppDelegate.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 09/08/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import UIKit
import Realm
import RealmSwift
import IQKeyboardManagerSwift
import UserNotifications
import SDDownloadManager
import SafariServices
import CoreSpotlight
import SwiftKeychainWrapper
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    let notificationCenter = UNUserNotificationCenter.current()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        UIApplication.shared.registerForRemoteNotifications()
//        application.setMinimumBackgroundFetchInterval(900)
        
        let options : UNAuthorizationOptions = [.alert, .sound, .badge]
        notificationCenter.requestAuthorization(options: options) { (didAllow, error) in
            guard didAllow else {return}
//            BackgroundFetch().setCategories()
//            if !didAllow {
//                print("The user denied notification permission.")
//            } else if didAllow {
//                BackgroundFetch().setCategories()
//            }
        }
        // Code for realm migration, update this when realm schema is changed

        let config = Realm.Configuration(
            schemaVersion: 1, // version to change schema to
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {
                    // change properties based on new schema
                }
            })
        Alamofire.SessionManager.default.delegate.taskWillPerformHTTPRedirection = nil
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        UIApplication.shared.registerForRemoteNotifications()
        IQKeyboardManager.shared.enable = true
        
//        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
////            manageNotificationPayload(userInfo: userInfo)
//        }
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
    
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        guard let message = url.host else { return true }
        guard let tabVC = self.window?.rootViewController as? BubbleTabBarController else { return false }
        tabVC.selectedIndex = 0
        guard let navVC = tabVC.viewControllers?.first as? UINavigationController else { return false }
        guard let dashboardVC = (navVC.viewControllers.first as? DashboardViewController) else { return false }
        guard let loginVC = dashboardVC.loginViewController else { return false }
        loginVC.loginWithGoogle(input: message)
        loginVC.safariVC.dismiss(animated: true)
        
        return true
    }
    
    //    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    //        <#code#>
    //    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        SDDownloadManager.shared.backgroundCompletionHandler = completionHandler
    }
    
//    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        if Reachability.isConnectedToNetwork() {
//            let bkgObj = BackgroundFetch()
//            bkgObj.downloadModules { newModulesFound in
//                let realm = try! Realm()
//                let discussionModules = realm.objects(Module.self).filter("modname = %@", "forum")
//                bkgObj.downloadDiscussions(discussionModules: discussionModules) { (newDiscussionsFound) in
//                    completionHandler(newDiscussionsFound || newModulesFound ? .newData : .noData)
//                    NSLog(newDiscussionsFound || newModulesFound ? "found new data" : "no new data found")
//                }
//            }
//        } else {
//            completionHandler(.failed)
//            print("failed to background fetch")
//        }
//    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("device token = \(token)")
        KeychainWrapper.standard.set(token, forKey: "deviceToken")
//        NotificationManager.shared.registerDevice(deviceToken: token) {
            
//        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            if response.actionIdentifier == "Mark as Read" {

                //Mark as read function
            } else if response.actionIdentifier == "Open" {
    //            Open file
            }
        }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Print message ID.
        UNUserNotificationCenter.current().delegate = self
        // Print full message.
    }
    // handle opening with spotlight search
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == CSSearchableItemActionType {
            if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                guard let typeId = getTypeAndId(string: uniqueIdentifier) else { return true }
                self.manageRedirection(redirectType: typeId.keys.first!, id: typeId.values.first!)
                
            }
        }
        
        return true
    }
    
    private func getTypeAndId(string: String) -> [String: Int]? {
        let comps = string.components(separatedBy: "=")
        let first = comps.first
        let last = Int(comps.last!)
        if first != nil && last != nil {
            return [first!: last!]
        }
        return nil
    }
    
}

// Managing Notifications
extension AppDelegate {
    
    func manageRedirection(redirectType: String, id: Int) {
        let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            // topController should now be your topmost view controller
            if let bubbleTabVC = topController as? BubbleTabBarController {
                // app is already open
                bubbleTabVC.selectedIndex = 0
                guard let navigationVC = bubbleTabVC.viewControllers?.first as? UINavigationController else { return }
                let realm = try! Realm()
                switch redirectType {
                case "course":
                    guard let course = realm.objects(Course.self).filter("courseid = %@", id).first else { return }
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let courseContentsVC = storyboard.instantiateViewController(withIdentifier: "Course Contents") as! CourseDetailsViewController
                    courseContentsVC.currentCourse = course
                    navigationVC.pushViewController(courseContentsVC, animated: true)
                    break
                case "module":
                    // get the module and push it
                    guard let module = realm.objects(Module.self).filter("id = %@", id).first else { return }
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let moduleVC = storyboard.instantiateViewController(withIdentifier: "Module View Controller") as! ModuleViewController
                    moduleVC.selectedModule = module
                    navigationVC.pushViewController(moduleVC, animated: true)
                    break
                case "discussion":
                    // get the discussion object
                    guard let discussion = realm.objects(Discussion.self).filter("id = %@", id).first else { return }
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let discussionVC = storyboard.instantiateViewController(withIdentifier: "Discussions") as! DiscussionViewController
                    discussionVC.selectedDiscussion = discussion
                    navigationVC.pushViewController(discussionVC, animated: true)
                    break
                case "section":
                    break
                default:
                    break
                }
                return
                
            } else {
                // app is not open, proceed with login vc
                guard let loginVC = topController as? LoginViewController else { return }
                loginVC.redirectTo = [redirectType: id]
                
            }
            
        }
    }
    
    func manageNotificationPayload(userInfo: [AnyHashable: Any]) {
        guard let respDict = userInfo["aps"] as? NSDictionary else { return }
        if let courseIdString = (respDict["data"] as? NSDictionary)?["courseid"] as? String {
            guard let courseId = Int(courseIdString) else { return }
            print("Received notification with  course id:", courseId)
            guard let contextURL = (respDict["data"] as? NSDictionary)?["contexturl"] as? String else { return }
            var notificationType = "" // incomplete! deletect the type here
            if contextURL.contains("discuss.php") {
                notificationType = "discussion"
            } else if contextURL.contains("/mod/") {
                notificationType = "module"
            }
            switch notificationType {
            case "discussion":
                guard let discussionIdString = Regex.match(pattern: "#p[0-9]+", text: contextURL).first?.replacingOccurrences(of: "#p", with: "") else { return }
                guard let discussionId = Int(discussionIdString) else { return }
                DashboardDataManager.shared.getAndStoreDiscussions(forCourse: courseId) {
                    Alamofire.SessionManager.default.session.getAllTasks { (tasks) in
                        tasks.forEach{ $0.cancel() }
                    }
                    DispatchQueue.main.async {
                        self.manageRedirection(redirectType: notificationType, id: discussionId)
                    }
                }
                break
            case "module":
                guard let moduleIdString = Regex.match(pattern: "id=[0-9]+", text: contextURL).first?.replacingOccurrences(of: "id=", with: "") else { return }
                guard let moduleId = Int(moduleIdString) else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    DashboardDataManager.shared.getAndStoreModules(forCourse: courseId) {
                        DispatchQueue.main.async {
                            self.manageRedirection(redirectType: notificationType, id: moduleId)
                        }
                    }
                }
                break
            default:
                break
            }
        }
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print(userInfo)
        
        if application.applicationState == .active {
            
            // app is currently active
            
        } else if application.applicationState == .background {
            
            //app is in background, if content-available key of your notification is set to 1, poll to your backend to retrieve data and update your interface here
            
        } else if application.applicationState == .inactive {
            // user tapped on the notification, do all the stuff here
            manageNotificationPayload(userInfo: userInfo)
            
        }
        
        
    }
        
}
