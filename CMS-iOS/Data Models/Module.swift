//
//  ModuleElement.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 13/08/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import UIKit
import RealmSwift

class Module : Object {
    
    @objc dynamic var name : String = ""
    @objc dynamic var modname : String = ""
    @objc dynamic var filename : String = ""
    @objc dynamic var fileurl : String = ""
    @objc dynamic var moduleDescription : String = ""
    @objc dynamic var mimetype : String = ""
    @objc dynamic var id : Int = 0
    @objc dynamic var read : Bool = false
    @objc dynamic var coursename : String = ""
    var fileModules = RealmSwift.List<Module>();
    override class func primaryKey() -> String? {
        return "id"
    }
}

class FilterModule {
    var name = ""
    var coursename = ""
    var id = 0
    
    init(name: String, coursename: String, id: Int) {
        self.name = name
        self.coursename = coursename
        self.id = id
    }
}
