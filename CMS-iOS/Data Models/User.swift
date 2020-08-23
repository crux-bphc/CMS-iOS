//
//  UserData.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 11/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import RealmSwift

class User : Object{
    @objc dynamic var name : String = ""
    @objc dynamic var userid = 0
    @objc dynamic var email : String = ""
    @objc dynamic var token : String = ""
    @objc dynamic var loggedIn : Bool = false
    @objc dynamic var isConnected : Bool = false
}
