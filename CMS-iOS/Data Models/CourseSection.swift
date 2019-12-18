//
//  CourseElement.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 13/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import RealmSwift
class CourseSection : Object{
    
    @objc dynamic var name : String = ""
    @objc dynamic var courseId : Int = 0
    @objc dynamic var key : String = ""
    var modules = RealmSwift.List<Module>()
    override class func primaryKey() -> String? {
        return "key"
    }
}
