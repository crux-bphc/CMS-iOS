//
//  Course.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 13/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
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
//    var sections =  RealmSwift.List<CourseSection>()
}
