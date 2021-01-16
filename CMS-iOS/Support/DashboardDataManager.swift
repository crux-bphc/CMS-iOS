//
//  DashboardDataManager.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 10/21/20.
//  Copyright © 2020 Hridik Punukollu. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import SwiftKeychainWrapper
import RealmSwift

class DashboardDataManager {
    
    static let shared = DashboardDataManager()
    private init() { }
    
    let constant = Constants.Global.self
    
    func getAndStoreCourses(userId: Int, completion: @escaping (_ courseViewModels: [DashboardViewModel]?, _ toLogOut: Bool) -> Void) {
        let params = ["wstoken": KeychainWrapper.standard.string(forKey: "userPassword")!, "userid": userId] as [String: Any]
        let FINAL_URL : String = constant.BASE_URL + constant.GET_COURSES
        let queue = DispatchQueue.global(qos: .userInteractive)
        var courseViewModels = [DashboardViewModel]()
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: Constants.Global.headers).responseJSON(queue: queue) { courseData in
            if !courseData.result.isSuccess {
                completion([], false)
                return
            }
            // delete the previous courses
            let realm = try! Realm()
            let previousCourses = realm.objects(Course.self)
            try! realm.write {
                realm.delete(previousCourses)
            }
            
            let courses = JSON(courseData.value as Any)
            if let _ = courses[0]["id"].int {
                var currentColorsCourseCode = String()
                var currentColorsIndex = 0
                let colors = DashboardCellColours().light
                for i in 0 ..< courses.count {
                    let currentCourse = Course()
                    currentCourse.courseid = courses[i]["id"].int!
                    currentCourse.displayname = courses[i]["displayname"].string!
                    currentCourse.courseCode = Regex.match(pattern: "^[A-Z\\/]*[ ][A-Z][0-9][0-9][0-9]", text: currentCourse.displayname).first ?? ""
                    currentCourse.courseName = currentCourse.displayname.replacingOccurrences(of: "\(currentCourse.courseCode) ", with: "")
                    currentCourse.enrolled = true
                    // color allotment
                    if i == 0 {
                        currentColorsIndex = 0
                        currentColorsCourseCode = currentCourse.courseCode
                    }
                    if currentCourse.courseCode == currentColorsCourseCode {
                        currentCourse.allotedColor = UIColor.StringFromUIColor(color: colors[currentColorsIndex])
                    } else {
                        currentColorsIndex += 1
                        if currentColorsIndex == colors.count {
                            currentColorsIndex = 0
                        }
                        currentColorsCourseCode = currentCourse.courseCode
                        currentCourse.allotedColor = UIColor.StringFromUIColor(color: colors[currentColorsIndex])
                    }
                    
                    try! realm.write {
                        realm.add(currentCourse, update: .modified)
                    }
                    let currentCourseViewModel = DashboardViewModel(courseCode: currentCourse.courseCode, courseName: currentCourse.courseName, courseId: currentCourse.courseid, courseColor: UIColor.UIColorFromString(string: currentCourse.allotedColor))
                    courseViewModels.append(currentCourseViewModel)
                }
                completion(courseViewModels, false)
            } else {
                completion(nil, true)
            }
        }
    }
    
    func getAndStoreModules(completion: @escaping () -> Void) {
        
        let FINAL_URL = constant.BASE_URL + constant.GET_COURSE_CONTENT
        let realmOuter = try! Realm()
        let courses = realmOuter.objects(Course.self)
        let totalCourseCount = courses.count
        var current = 0
        for course in courses {
            let courseId = course.courseid
            let courseName = course.displayname
//            let readModuleIdSet: Set<Int> = Set(realmOuter.objects(Module.self).filter("coursename == %@ AND read == YES", courseName).map({ $0.id }))
            let params : [String:Any] = ["wstoken": KeychainWrapper.standard.string(forKey: "userPassword")!, "courseid": courseId]
            let queue = DispatchQueue.global(qos: .userInteractive)
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON (queue: queue) { (response) in
                let realm = try! Realm()
                if !response.result.isSuccess {
                    completion()
                }
                
//                let readModuleIdSet: Set<Int> = Set(realm.objects(Module.self).filter("coursename == %@ AND read == YES", courseName).map({ $0.id }))
                
                let courseContent = JSON(response.value as Any)
//                try! realm.write {
//                    realm.delete(realm.objects(Module.self).filter("coursename = %@", courseName))
//                    realm.delete(realm.objects(CourseSection.self).filter("courseId = %@", courseId))
//
//                }
                
                for i in 0 ..< courseContent.count {
                    if courseContent[i]["modules"].count > 0 || courseContent[i]["summary"] != "" {
                        let section = CourseSection()
                        section.name = courseContent[i]["name"].string!
                        if courseContent[i]["summary"] != "" {
                            // create a summary module and load it in a discussion cell
                            let summaryModule = Module()
                            summaryModule.name = "Summary"
                            summaryModule.coursename = courseName
                            summaryModule.moduleDescription = courseContent[i]["summary"].string!
                            summaryModule.modname = "summary"
                            summaryModule.id = courseContent[i]["id"].int!
                            summaryModule.read = true
                            section.modules.append(summaryModule)
                        } // add summary module
                        for j in 0 ..< courseContent[i]["modules"].array!.count {
                            let moduleData = Module()
                            moduleData.modname = courseContent[i]["modules"][j]["modname"].string!
                            moduleData.id = courseContent[i]["modules"][j]["id"].int!
                            moduleData.read = realm.objects(Module.self).filter("id = %@", moduleData.id).first?.read ?? false
                            if moduleData.modname == "resource" {
                                if (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!).contains("cms.bits-hyderabad.ac.in") {
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
                                moduleData.read = true
                            } else if moduleData.modname == "folder" {
                                
                                let itemCount = courseContent[i]["modules"][j]["contents"].count
                                for a in 0..<itemCount{
                                    let newModule = Module()
                                    newModule.coursename = courseName
                                    newModule.filename = courseContent[i]["modules"][j]["contents"][a]["filename"].string!
                                    newModule.read = true
                                    
                                    if courseContent[i]["modules"][j]["contents"][a]["fileurl"].string!.contains("cms.bits-hyderabad.ac.in") {
                                        newModule.fileurl = courseContent[i]["modules"][j]["contents"][a]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                    }
                                    newModule.mimetype = courseContent[i]["modules"][j]["contents"][a]["mimetype"].string!
                                    newModule.id = (moduleData.id * 1000) + a + 1
                                    moduleData.fileModules.append(newModule)
                                }
                            } else if moduleData.modname == "url" {
                                moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!)
                            }
                            
                            moduleData.name = courseContent[i]["modules"][j]["name"].string!
//                            if readModuleIdSet.contains(moduleData.id) {
//                                moduleData.read = true
//                            }
                            if courseContent[i]["modules"][j]["description"].string != nil {
                                moduleData.moduleDescription = courseContent[i]["modules"][j]["description"].string!
                            }
                            moduleData.coursename = courseName
                            section.modules.append(moduleData)
                        }
                        section.courseId = courseId
                        section.key = String(courseId) + section.name
                        section.dateCreated = Date().timeIntervalSince1970
                        
                        try! realm.write {
//                            realm.delete(realm.objects(CourseSection.self).filter("key = %@", section.key))
                            if let prevSection = realm.objects(CourseSection.self).filter("key = %@", section.key).first {
                                realm.delete(prevSection.modules)
                                realm.delete(prevSection)
                            }
                        }

                        try! realm.write {
                            realm.add(section, update: .modified)
                            
                        }
                    }
                }
                current += 1
//                print("Done course \(courseName)")
                if current == totalCourseCount {
                    print("Done")
                    completion()
                }
            }
        }
    }
    
    func getAndStoreDiscussions(completion: @escaping () -> Void) {
        let realm = try! Realm()
        let discussionModules = realm.objects(Module.self).filter("modname = %@", "forum")
        let totalCount = discussionModules.count
        var current = 0
        for x in 0..<discussionModules.count {
            let discussionModule = discussionModules[x]
//            let readDiscussionIdSet: Set<Int> = Set(realm.objects(Discussion.self).filter("moduleId = %@ AND read == YES", discussionModule.id).map({ $0.id }))
            let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "forumid" : String(discussionModule.id)]
            let FINAL_URL : String = constant.BASE_URL + constant.GET_FORUM_DISCUSSIONS
            let queue = DispatchQueue.global(qos: .userInteractive)
            let moduleId = discussionModule.id
//            let coursename = discussionModule.coursename
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON(queue: queue) { (response) in
                if response.result.isSuccess {
                    let realmNew = try! Realm()
//                    let readDiscussionIdSet: Set<Int> = Set(realmNew.objects(Discussion.self).filter("moduleId = %@ AND read == YES", moduleId).map({ $0.id }))
//                    let readDiscussionIdSet: [Int] = Array(realmNew.objects(Discussion.self).filter("moduleId = %@ AND read == YES", moduleId).map({ $0.id }))
//                    if (coursename == "CS/ECE/EEE/INSTR F215 DIGITAL DESIGN FIRST SEMESTER 2020-21 L") {
//                        print(readDiscussionIdSet)
//                    }
//                    try! realmNew.write {
//                        realmNew.delete(realmNew.objects(Discussion.self).filter("moduleId = %@", moduleId))
//                    }
                    let discussionResponse = JSON(response.value as Any)
                    for i in 0 ..< discussionResponse["discussions"].count {
                        let discussion = Discussion()
                        discussion.name = discussionResponse["discussions"][i]["name"].string ?? "No Name"
                        discussion.author = discussionResponse["discussions"][i]["userfullname"].string?.capitalized ?? ""
                        discussion.date = discussionResponse["discussions"][i]["created"].int!
                        discussion.message = discussionResponse["discussions"][i]["message"].string ?? "No Content"
                        discussion.id = discussionResponse["discussions"][i]["id"].int!
//                        discussion.read = readDiscussionIdSet.contains(discussionResponse["discussions"][i]["id"].int!)
                        let oldDiscussion = realmNew.objects(Discussion.self).filter("id = %@", discussion.id).first
                        discussion.read = oldDiscussion?.read ?? false
//                        print(readDiscussionIdSet.count)
//                        if !readDiscussionIdSet.contains(discussionResponse["discussions"][i]["id"].int!) {
//                            print(discussionResponse["discussions"][i])
//
//                        }
                        discussion.moduleId = moduleId
                        if discussionResponse["discussions"][i]["attachment"].string! != "0" {
                            if discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string?.contains("cms.bits-hyderabad.ac.in") ?? false {
                                discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string! + "?&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                            } else {
                                discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string ?? ""
                            }
                            
                            discussion.filename = discussionResponse["discussions"][i]["attachments"][0]["filename"].string ?? ""
                            discussion.mimetype = discussionResponse["discussions"][i]["attachments"][0]["mimetype"].string ?? ""
                        }
                        try! realmNew.write {
                            if oldDiscussion != nil {
                                realmNew.delete(oldDiscussion!)
                            }
                            realmNew.add(discussion, update: .modified)
                        }
                    }
                }
                current += 1
                if current == totalCount {
                    print("Done with discussions")
                    completion()
                }
            }
        }
        
    }
    
    func calculateUnreadCounts(courseViewModels: [DashboardViewModel], completion: @escaping ([DashboardViewModel]) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            var newCourseViewModels = [DashboardViewModel]()
            let realm = try! Realm()
            for vm in courseViewModels {
                let courseId = vm.courseId
                let courseDisplayName = realm.objects(Course.self).filter("courseid = %@", courseId).first?.displayname ?? "DISPLAYNAME"
                let unreadModulesCount = realm.objects(Module.self).filter("read == NO").filter("coursename = %@", courseDisplayName).count
                let currentDiscussionModule = realm.objects(Module.self).filter("coursename = %@", courseDisplayName).filter("modname = %@", "forum").first
                let unreadDiscussionCount = realm.objects(Discussion.self).filter("read == NO").filter("moduleId = %@", currentDiscussionModule?.id ?? 1010101).count
                let totalCount = unreadModulesCount + unreadDiscussionCount
                vm.unreadCount = totalCount
                vm.shouldShowUnreadCounter = totalCount > 0
                newCourseViewModels.append(vm)
            }
            completion(newCourseViewModels)
        }
    }
    
}
