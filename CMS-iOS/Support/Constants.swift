//
//  Constants.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 12/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire

class Constants: NSObject {
    
    struct Global {
        static let BASE_URL : String = "https://td.bits-hyderabad.ac.in/moodle/"
        static let LOGIN : String = "webservice/rest/server.php?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json"
        static let GET_COURSES : String = "webservice/rest/server.php?wsfunction=core_enrol_get_users_courses&moodlewsrestformat=json"
        static let GET_COURSE_CONTENT : String = "webservice/rest/server.php?wsfunction=core_course_get_contents&moodlewsrestformat=json"
        static let SEARCH_COURSES : String = "webservice/rest/server.php?wsfunction=core_course_search_courses&moodlewsrestformat=json&criterianame=search"
        static let SELF_ENROL_USER : String = "webservice/rest/server.php?wsfunction=enrol_self_enrol_user&moodlewsrestformat=json"
        static let GET_SITE_NEWS : String = "webservice/rest/server.php?wsfunction=mod_forum_get_forum_discussions_paginated&moodlewsrestformat=json&forumid=1&sortby=timemodified&sortdirection=DESC"
        static let headers : HTTPHeaders = ["Accept" : "application/json"]
        static let secret : String = ""
    }
}
