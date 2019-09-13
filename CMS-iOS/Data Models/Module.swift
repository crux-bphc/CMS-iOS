//
//  ModuleElement.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 13/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
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
    var fileModules = RealmSwift.List<Module>();
    
}
