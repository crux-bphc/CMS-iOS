//
//  Course.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 13/08/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import UIKit
import RealmSwift

class Course : Object {
    
    @objc dynamic var displayname : String = ""
    @objc dynamic var courseid : Int = 0
    @objc dynamic var enrolled : Bool = false
    @objc dynamic var faculty : String = ""
    @objc dynamic var canMakeDiscussion : Bool = false
    @objc dynamic var progress : Float = 0
    @objc dynamic var courseCode : String = ""
    @objc dynamic var courseName : String = ""
    @objc dynamic var allotedColor : String = ""
    
    /*
     MIGRATION 2: Added property update Flag
     The update flag is initially set to 0
     When the new courses are parsed from JSON, it is updated to 1 for that course
     Then the courses are added (updated with primary key instead of deleting them and readding)
     Then we delete all the courses with flag = 0, these are courses that may have been unenrolled from
     Next, we set all course flags back to 0
     */
    
    @objc dynamic var updateFlag: Int = 0
    
    override class func primaryKey() -> String? {
        return "courseid"
    }
}
