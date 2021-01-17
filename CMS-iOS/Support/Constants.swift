//
//  Constants.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 12/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SDDownloadManager

class Constants: NSObject {
    
    struct Global {
        static let downloadManager = SDDownloadManager.shared
        static let BASE_URL : String = "https://cms.bits-hyderabad.ac.in/"
        static let LOGIN : String = "webservice/rest/server.php?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json"
        static let GET_COURSES : String = "webservice/rest/server.php?wsfunction=core_enrol_get_users_courses&moodlewsrestformat=json"
        static let GET_COURSE_CONTENT : String = "webservice/rest/server.php?wsfunction=core_course_get_contents&moodlewsrestformat=json"
        static let SEARCH_COURSES : String = "webservice/rest/server.php?wsfunction=core_course_search_courses&moodlewsrestformat=json&criterianame=search"
        static let SELF_ENROL_USER : String = "webservice/rest/server.php?wsfunction=enrol_self_enrol_user&moodlewsrestformat=json"
        static let GET_SITE_NEWS : String = "webservice/rest/server.php?wsfunction=mod_forum_get_forum_discussions_paginated&moodlewsrestformat=json&forumid=1&sortby=timemodified&sortdirection=DESC"
        static let GET_FORUM_DISCUSSIONS : String = "webservice/rest/server.php?wsfunction=mod_forum_get_forum_discussions_paginated&moodlewsrestformat=json&sortby=timemodified&sortdirection=DESC"
        static let CAN_ADD_DISCUSSIONS : String = "webservice/rest/server.php?moodlewsrestformat=json&wsfunction=mod_forum_can_add_discussion"
        static let ADD_DISCUSSION : String = "webservice/rest/server.php?moodlewsrestformat=json&wsfunction=mod_forum_add_discussion"
        static let REGISTER_DEVICE: String = "webservice/rest/server.php?wsfunction=core_user_add_user_device&moodlewsrestformat=json"
        static let DEREGISTER_DEVICE: String = "webservice/rest/server.php?wsfunction=core_user_remove_user_device&moodlewsrestformat=json"
        
        static let headers : HTTPHeaders = ["Accept" : "application/json"]
        static let GITHUB_URL = "https://github.com/crux-bphc/CMS-iOS"
        static let APP_ID = "id1489946522" // app store app id
//        static let DashboardCellColorsAlternate = [UIColor(displayP3Red: 190/255, green: 13/255, blue: 13/255, alpha: 1), UIColor(displayP3Red: 187/255, green: 81/255, blue: 0/255, alpha: 1), UIColor(displayP3Red: 153/255, green: 120/255, blue: 28/255, alpha: 1), UIColor(displayP3Red: 0/255, green: 117/255, blue: 127/255, alpha: 1), UIColor(displayP3Red: 0/255, green: 99/255, blue: 180/255, alpha: 1), UIColor(displayP3Red: 31/255, green: 63/255, blue: 137/255, alpha: 1), UIColor(displayP3Red: 109/255, green: 37/255, blue: 150/255, alpha: 1)]
//        static let DashboardCellColors = [UIColor.systemTeal, UIColor.systemBlue, UIColor.systemPurple, UIColor.systemOrange, UIColor.systemRed]
}
}
