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
    
    public func updateCourseContents(completion: @escaping ((Bool) -> Void)) {
        let realm = try! Realm()
        let constants = Constants.Global.self
        let subscribedCourses = realm.objects(Course.self)
        var foundNewData = false
        let password = realm.objects(User.self).first?.token
        for x in 0..<subscribedCourses.count{
            let currentCourse = subscribedCourses[x]
            
            let FINAL_URL = constants.BASE_URL + constants.GET_COURSE_CONTENT
            let params : [String:Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword") ?? password!, "courseid" : currentCourse.courseid]
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
                let realm = try! Realm()
                if response.result.isSuccess {
                    let courseContent = JSON(response.value as Any)
                    for i in 0 ..< courseContent.count {
                        if courseContent[i]["modules"].count > 0 {
                            let section = CourseSection()
                            section.courseId = currentCourse.courseid
                            section.name = courseContent[i]["name"].string!
                            for j in 0 ..< courseContent[i]["modules"].array!.count {
                                let moduleData = Module()
                                moduleData.modname = courseContent[i]["modules"][j]["modname"].string!
                                moduleData.id = courseContent[i]["modules"][j]["id"].int!
                                if moduleData.modname == "resource" {
                                    if (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!).contains("td.bits-hyderabad.ac.in") {
                                        moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string! +
                                            "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)")
                                        moduleData.mimetype = courseContent[i]["modules"][j]["contents"][0]["mimetype"].string!
                                        moduleData.filename = courseContent[i]["modules"][j]["contents"][0]["filename"].string!
                                    }
                                    else {
                                        moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!)
                                    }
                                } else if moduleData.modname == "forum" {
                                    moduleData.id = courseContent[i]["modules"][j]["instance"].int!
//                                    self.downloadDiscussions(currentModule: moduleData) { (foundNewDiscussions) in
//                                        if foundNewDiscussions {
//                                            foundNewData = true
//                                        }
//                                    }
                                }else if moduleData.modname == "folder"{
                                    
                                    let itemCount = courseContent[i]["modules"][j]["contents"].count
                                    for a in 0..<itemCount{
                                        let newModule = Module()
                                        newModule.coursename = currentCourse.displayname
                                        newModule.filename = courseContent[i]["modules"][j]["contents"][a]["filename"].string!
                                        newModule.read = true
                                        
                                        if courseContent[i]["modules"][j]["contents"][a]["fileurl"].string!.contains("td.bits-hyderabad.ac.in") {
                                            newModule.fileurl = courseContent[i]["modules"][j]["contents"][a]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                        }
                                        newModule.mimetype = courseContent[i]["modules"][j]["contents"][a]["mimetype"].string!
                                        moduleData.fileModules.append(newModule)
                                    }
                                } else if moduleData.modname == "url" {
                                    moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!)
                                }
                                
                                moduleData.name = courseContent[i]["modules"][j]["name"].string!
                                
                                if courseContent[i]["modules"][j]["description"].string != nil {
                                    moduleData.moduleDescription = courseContent[i]["modules"][j]["description"].string!
                                }
                                moduleData.coursename = currentCourse.displayname
                                section.modules.append(moduleData)
                                // check module here
                                if (realm.objects(Module.self).filter("coursename = %@", currentCourse.displayname).filter("id = \(moduleData.id)").count == 0) {
                                    // this is a new module
                                    self.sendNotification(title: "\(moduleData.name)", body: "New content in \(currentCourse.displayname)", identifier: "\(currentCourse.displayname + String(moduleData.id))")
                                    foundNewData = true
                                }
                            }
                        }
                    }
                }
                if x == subscribedCourses.count - 1{
                    completion(foundNewData)
                    
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
        print("The identifier for the notification is: \(identifier)")
    }
    
    public func setCategories() {
        let notificationCenter = UNUserNotificationCenter.current()
        let userActions = "User Actions"
        let markRead = UNNotificationAction(identifier: "Mark as Read", title: "Mark as Read", options: [])
        let openAction = UNNotificationAction(identifier: "Open", title: "Open", options: [])
        let categories = UNNotificationCategory(identifier: userActions, actions: [markRead, openAction], intentIdentifiers: [], options: [])
        notificationCenter.setNotificationCategories([categories])
    }
//    func downloadDiscussions(currentModule : Module, completion : @escaping (Bool) -> Void) {
//        let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "forumid" : String(currentModule.id)]
//        let constants = Constants.Global.self
//        let FINAL_URL : String = constants.BASE_URL + constants.GET_FORUM_DISCUSSIONS
//        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
//            if response.result.isSuccess {
//                let discussionResponse = JSON(response.value as Any)
//                if discussionResponse["discussions"].count == 0 {
//                    completion(false)
//                } else {
//                    let realm = try! Realm()
////                    var readDiscussionIds = [Int]()
////                    let readDiscussions = realm.objects(Discussion.self).filter("read = YES")
////                    for i in 0..<readDiscussions.count {
////                        readDiscussionIds.append(readDiscussions[i].id)
////                    }
////                    try! realm.write {
////                        realm.delete(realm.objects(Discussion.self).filter("moduleId = %@", currentModule.id))
////                    }
//                    for i in 0 ..< discussionResponse["discussions"].count {
//                        let discussion = Discussion()
//                        discussion.name = discussionResponse["discussions"][i]["name"].string ?? "No Name"
//                        discussion.author = discussionResponse["discussions"][i]["userfullname"].string?.capitalized ?? ""
//                        discussion.date = discussionResponse["discussions"][i]["created"].int!
//                        discussion.message = discussionResponse["discussions"][i]["message"].string ?? "No Content"
//                        discussion.id = discussionResponse["discussions"][i]["id"].int!
//                        discussion.moduleId = currentModule.id
//                        if discussionResponse["discussions"][i]["attachment"].string! != "0" {
//                            if discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string?.contains("td.bits-hyderabad.ac.in") ?? false {
//                                discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string! + "?&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
//                            } else {
//                                discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string ?? ""
//                            }
//
//                            discussion.filename = discussionResponse["discussions"][i]["attachments"][0]["filename"].string ?? ""
//                            discussion.mimetype = discussionResponse["discussions"][i]["attachments"][0]["mimetype"].string ?? ""
//                        }
//                        if realm.objects(Discussion.self).filter("id = %@", discussion.id).count == 0 {
//                            // new discussion
//                            self.sendNotification(title: discussion.name, body: "New announcement in \(currentModule.coursename)", identifier: String(discussion.id))
//                            completion(true)
//                        }
//
//                    }
//                }
//            }
//        }
//    }
}
