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

class CourseUnenroller {
    
    static let shared = CourseUnenroller()
    
    // put this in dashboard
    func attemptUnenroll(courseId: Int, completion: @escaping (_ shouldShowLoginView: Bool, _ completed: Bool) -> Void) {
        CourseUnenroller.shared.fetchEnrollIdSessKey(courseId: courseId) { (enrollId, sessKey) in
            if enrollId == nil || sessKey == nil {
                // show web view and set the cookie in keychain
                // ....
                completion(true, false)
                return
            }
            CourseUnenroller.shared.sendUnenrollRequest(enrollId: enrollId!, sessKey: sessKey!) {
                completion(false, true)
            }
            
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
    
    func sendUnenrollRequest(enrollId: String, sessKey: String, completion: @escaping () -> Void) {
        let cookie = KeychainWrapper.standard.string(forKey: "MoodleSession")
        if cookie == nil { completion(); return }
        let url = "https://cms.bits-hyderabad.ac.in/enrol/self/unenrolself.php?enrolid=\(enrollId)&sesskey=\(sessKey)&confirm=1"
        let headers: HTTPHeaders = ["Cookie": "MoodleSession=\(cookie!)"]
        Alamofire.request(url, method: .post, headers: headers).responseData { (response) in
            completion()
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
