//
//  Discussion.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 16/08/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import UIKit
import RealmSwift

class Discussion : Object {
    
    @objc dynamic var name : String = ""
    @objc dynamic var date : Int = 0
    @objc dynamic var author : String = ""
    @objc dynamic var message : String = ""
    @objc dynamic var filename : String = ""
    @objc dynamic var mimetype : String = ""
    @objc dynamic var modname : String = ""
    @objc dynamic var attachment : String = ""
    @objc dynamic var id : Int = 0
    @objc dynamic var moduleId : Int = 0
    @objc dynamic var read : Bool = false
    override class func primaryKey() -> String? {
        return "id"
    }
}

class FilterDiscussion {
    var name = ""
    var coursename = ""
    var id = 0
    
    init(name: String, coursename: String, id: Int) {
        self.name = name
        self.coursename = coursename
        self.id = id
    }
}
