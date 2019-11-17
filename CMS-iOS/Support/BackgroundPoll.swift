//
//  BackgroundPoll.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 12/11/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import RealmSwift
import SwiftKeychainWrapper

public class BackgroundPoll {
    
    private var database : Realm
    static let sharedInstance = BackgroundPoll()
    private init() {
        database = try! Realm()
    }
    
    func retrieveData() -> [Course] {
        let userCourses = database.objects(Course.self)
        var courseArray = [Course]()
        for i in userCourses {
            courseArray.append(i)
        }
        return courseArray
    }
    
    func MakeCourseRequest(course: Course) {
        var moduleCount : Int = 0
//        let modulesInRealmCourese : Int = course.module
        let headers = Constants.Global.self.headers
        let params : [String:String] = ["courseid": String(course.courseid), "wstoken": KeychainWrapper.standard.string(forKey: "userPassword")!]
        let url = Constants.Global.self.BASE_URL + Constants.Global.self.GET_COURSE_CONTENT
        Alamofire.request(url, method: .get
            , parameters: params, headers: headers).responseJSON { (response) in
                if response.result.isSuccess {
                    let courseData = JSON(response.value as Any)
                    for i in 0 ..< courseData.count {
                        moduleCount += i
//                        remove the above line, it's absolute shit
                    }
                }
        }
    }
    
    func pollMoodle(completion: @escaping() -> Void) {
        let courseList = retrieveData()
        var currentUser = User()
        if let user = database.objects(User.self).first {
            currentUser = user
        }
        if currentUser.userid != 0 {
            for course in courseList {
                MakeCourseRequest(course: course)
            }
        }
        completion()
    }
    
}
