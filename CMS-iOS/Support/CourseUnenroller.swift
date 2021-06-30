//
//  CourseUnenroller.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 12/25/20.
//  Copyright © 2020 Hridik Punukollu. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper
import WebKit
import RealmSwift
import SwiftyJSON

class CourseUnenroller {
    
    static let shared = CourseUnenroller()
    
    // put this in dashboard
    func attemptUnenroll(courseId: Int, userId: Int, completion: @escaping (_ shouldAskToRelogin: Bool, _ completed: Bool) -> Void) {
        let sessionTimestamp = UserDefaults.standard.integer(forKey: "sessionTimestamp")
        if sessionTimestamp != 0 {
            let passedTime = Int(Date().timeIntervalSince1970) - sessionTimestamp
            if (passedTime > 360) {
                createAndStoreSessionDetails(userId: userId) { storedSuccessfully in
                    self.unenrollFlow(courseId: courseId) { completed in
                        completion(false, completed)
                    }
                }
            } else {
                self.unenrollFlow(courseId: courseId) { completed in
                    completion(false, completed)
                }
            }
        } else {
            if KeychainWrapper.standard.string(forKey: "privateToken") == nil {
                completion(true, false)
                return
            }
            createAndStoreSessionDetails(userId: userId) { storedSuccessfully in
                if storedSuccessfully {
                    // moodle session is stored and not expired for sure
                    self.unenrollFlow(courseId: courseId) { completed in
                        completion(false, completed)
                    }
                } else {
                    // not stored successfully
                    completion(false, false)
                }
            }
        }
    }
    
    func unenrollFlow(courseId: Int, completion: @escaping (Bool) -> Void) {
        CourseUnenroller.shared.fetchEnrollIdSessKey(courseId: courseId) { (enrollId, sessKey) in
            if enrollId == nil || sessKey == nil {
                completion(false)
                return
            }
            CourseUnenroller.shared.sendUnenrollRequest(enrollId: enrollId!, sessKey: sessKey!) {
                completion(true)
            }
            
        }
    }
    
    
    func createAndStoreSessionDetails(userId: Int, completion: @escaping (Bool) -> Void) {
        CourseUnenroller.shared.createMoodleSessionFromPrivateToken(userId: userId) { moodleSession, newSessionTimestamp in
            if moodleSession == nil || newSessionTimestamp == nil {
                completion(false)
                return
            }
            KeychainWrapper.standard.set(moodleSession!, forKey: "MoodleSession")
            UserDefaults.standard.set(newSessionTimestamp!, forKey: "sessionTimestamp")
            completion(true)
            
        }
    }
    
    
    func fetchEnrollIdSessKey(courseId: Int, completion: @escaping (String?, String?)  -> Void) {
        // completion(int?: returns enrolid in case it does work, string?: returns sesskey in case it does work)
        let cookie = KeychainWrapper.standard.string(forKey: "MoodleSession")
        if cookie == nil { completion(nil, nil); return }
        let headers: HTTPHeaders = ["Cookie": "MoodleSession=\(cookie!)"]
        Alamofire.request("https://cms.bits-hyderabad.ac.in/course/view.php?id=\(courseId)", method: .get, headers: headers).responseData { (response) in
            if !response.result.isSuccess || response.data == nil {
                completion(nil, nil)
                return
            }
            let rawHTMLResponse =  String(data: response.data!, encoding: .utf8)!
            if !rawHTMLResponse.contains("enrolid=") { completion(nil, nil); return }
            let enrollId = Regex.match(pattern: "enrolid=[0-9]+", text: rawHTMLResponse).first?.replacingOccurrences(of: "enrolid=", with: "")
            let sessKey = Regex.match(pattern: "sesskey=[0-9A-Za-z]+", text: rawHTMLResponse).first?.replacingOccurrences(of: "sesskey=", with: "")
            completion(enrollId, sessKey)
        }
    }
    
    func createMoodleSessionFromPrivateToken(userId: Int, completion: @escaping (_ moodleSessionCookie: String?, _ cookieCreatedTimestamp: Int?) -> Void) {
        let url = Constants.Global.self.BASE_URL + Constants.Global.self.AUTOLOGIN
        guard let privateToken = KeychainWrapper.standard.string(forKey: "privateToken") else {
            completion(nil, nil)
            return
        }
        guard let wstoken = KeychainWrapper.standard.string(forKey: "userPassword") else {
            completion(nil, nil)
            return
        }
        let params = ["wstoken": wstoken, "privatetoken": privateToken]
        Alamofire.request(url, method: .post, parameters: params, headers: ["User-Agent": "MoodleMobile"]).responseJSON { response in
            if !response.result.isSuccess || response.data == nil {
                completion(nil, nil)
                return
            }
            let jsonData = JSON(response.data!)
            print(jsonData)
            guard let key = jsonData["key"].string else { return }
            guard let autoLoginURL = jsonData["autologinurl"].string else { return }
            let paramsAutoLogin: [String: Any] = ["userid": userId, "key": key]
            Alamofire.request(autoLoginURL, method: .get, parameters: paramsAutoLogin)
                .responseData { response in
                    if !response.result.isSuccess || response.data == nil { return }
                    for cookie in HTTPCookieStorage.shared.cookies! {
                        if cookie.name == "MoodleSession" {
                            let moodleSession = cookie.value
                            let ts = Int(Date().timeIntervalSince1970)
                            completion(moodleSession, ts)
                            return
                        }
                    }
                }
        }
    }
    
    
    func sendUnenrollRequest(enrollId: String, sessKey: String, completion: @escaping () -> Void) {
        let cookie = KeychainWrapper.standard.string(forKey: "MoodleSession")
        if cookie == nil { completion(); return }
        let url = "https://cms.bits-hyderabad.ac.in/enrol/self/unenrolself.php?enrolid=\(enrollId)&sesskey=\(sessKey)&confirm=1"
        let headers: HTTPHeaders = ["Cookie": "MoodleSession=\(cookie!)"]
        Alamofire.request(url, method: .post, headers: headers).responseData { (response) in
            completion()
        }
    }
    
    func clearLocalStorage(forCourseWith courseId: Int) {
        // delete modules
        let realm = try! Realm()
        guard let course = realm.objects(Course.self).filter("courseid = %@", courseId).first else { return }
        let courseName = course.displayname
        if let discussionModuleId = realm.objects(Module.self).filter("coursename = %@ AND modname contains 'forum'", courseName).first?.id {
            let discussions = realm.objects(Discussion.self).filter("moduleId = %@", discussionModuleId)
            print("Deleting \(discussions.count) discussions")
            try! realm.write {
                realm.delete(discussions)
            }
        }
        let modules = realm.objects(Module.self).filter("coursename = %@", courseName)
        let sections = realm.objects(CourseSection.self).filter("courseId = %@", courseId)
        
        
        print("Deleting \(modules.count) modules")
        print("Deleting \(sections.count) sections")
        try! realm.write {
            realm.delete(modules)
            realm.delete(sections)
            // finally delete the course
            realm.delete(course)
        }
        
    }
    
    func removeAllCookies() {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            dataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) { }
        }
    }
    
    private init() { }
    
}
