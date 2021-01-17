//
//  BackgroundFetch.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 11/16/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftKeychainWrapper
import Alamofire
import SwiftyJSON
import UserNotifications

class BackgroundFetch {

    public func downloadModules(completion: @escaping (Bool) -> Void) {
        let realm = try! Realm()
        let constants = Constants.Global.self
        let subscribedCourses = realm.objects(Course.self)
        if subscribedCourses.count == 0 { return }
        var foundNewData = false
        let totalCount = subscribedCourses.count
        var currentCount = 0
        let password = realm.objects(User.self).first?.token
        let FINAL_URL = constants.BASE_URL + constants.GET_COURSE_CONTENT
        var params : [String:Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword") ?? password!]
        let existingModuleIds: Set<Int> = Set(realm.objects(Module.self).map({ $0.id }))
        for x in 0..<subscribedCourses.count {
            let currentCourse = subscribedCourses[x]
            params["courseid"] = currentCourse.courseid
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { response in
                
                if response.result.isSuccess {
                    let courseContent = JSON(response.value as Any)
                    for i in 0 ..< courseContent.count {
                        for j in 0 ..< courseContent[i]["modules"].array!.count {
                            var moduleJSONItemId = Int()
                            if courseContent[i]["modules"][j]["modname"].string! == "forum" {
                                moduleJSONItemId = courseContent[i]["modules"][j]["instance"].int!
                            } else {
                                moduleJSONItemId = courseContent[i]["modules"][j]["id"].int!
                            }
                            let moduleJSONItemName = courseContent[i]["modules"][j]["name"].string!
                            if !existingModuleIds.contains(moduleJSONItemId) {
                                self.sendNotification(title: "\(moduleJSONItemName)", body: "New content in \(currentCourse.displayname.removeSemester().cleanUp())", identifier: "\(currentCourse.displayname + String(moduleJSONItemId))")
                                foundNewData = true
                            }
                        }
                    }
                    currentCount += 1
                    if currentCount == totalCount {
                        completion(foundNewData)
                    }
                } else {
                    print("failed")
                }
            }
        }
        
    }
    
    public func downloadDiscussions(discussionModules : Results<Module>, completion : @escaping (Bool) -> Void) {
        var foundNewDiscussions = false
        for x in 0..<discussionModules.count {
            let discussionModule = discussionModules[x]
            let constants = Constants.Global.self
            let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "forumid" : String(discussionModule.id)]
            let FINAL_URL : String = constants.BASE_URL + constants.GET_FORUM_DISCUSSIONS

            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
                if response.result.isSuccess {
                    let discussionResponse = JSON(response.value as Any)
                    if discussionResponse["discussions"].count == 0 {

                    } else {
                        for i in 0 ..< discussionResponse["discussions"].count {
                            let discussion = Discussion()
                            discussion.name = discussionResponse["discussions"][i]["name"].string ?? "No Name"
                            discussion.author = discussionResponse["discussions"][i]["userfullname"].string?.capitalized ?? ""
                            discussion.date = discussionResponse["discussions"][i]["created"].int!
                            discussion.message = discussionResponse["discussions"][i]["message"].string ?? "No Content"
                            discussion.id = discussionResponse["discussions"][i]["id"].int!
                            discussion.moduleId = discussionModule.id
                            if discussionResponse["discussions"][i]["attachment"].string! != "0" {
                                if discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string?.contains("cms.bits-hyderabad.ac.in") ?? false {
                                    discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string! + "?&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                } else {
                                    discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string ?? ""
                                }
                                
                                discussion.filename = discussionResponse["discussions"][i]["attachments"][0]["filename"].string ?? ""
                                discussion.mimetype = discussionResponse["discussions"][i]["attachments"][0]["mimetype"].string ?? ""
                            }
                            
                            let realm = try! Realm()
                            if realm.objects(Discussion.self).filter("id = %@", discussion.id).count == 0 {
                                // new discussion
                                foundNewDiscussions = true
                                self.sendNotification(title: discussion.name, body: "New Announcement in \(discussionModule.coursename)", identifier: discussion.name + String(discussion.id))
                                try! realm.write {
                                    realm.add(discussion)
                                }
                            }
                            if i == discussionResponse["discussions"].count - 1 && x == discussionModules.count - 1 {
                                completion(foundNewDiscussions)
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    public func sendNotification(title: String, body: String, identifier: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
//        print("The identifier for the notification is: \(identifier)")
    }
    
    public func setCategories() {
        let notificationCenter = UNUserNotificationCenter.current()
        let userActions = "User Actions"
        let markRead = UNNotificationAction(identifier: "Mark as Read", title: "Mark as Read", options: [])
        let openAction = UNNotificationAction(identifier: "Open", title: "Open", options: [])
        let categories = UNNotificationCategory(identifier: userActions, actions: [markRead, openAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([categories])
    }
    
}
