//
//  Authentication.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 2/11/22.
//  Copyright © 2022 Crux BPHC. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import RealmSwift
import Alamofire

class Authentication {
    
    static let shared = Authentication()
    private var realm: Realm
    
    public func signOut(completion: @escaping () -> Void) {
        Alamofire.SessionManager.default.session.getAllTasks { (tasks) in
            tasks.forEach{ $0.cancel() }
        }
        try! realm.write {
            realm.deleteAll()
        }
        SpotlightIndex.shared.deindexAllItems()
        let wstoken = KeychainWrapper.standard.string(forKey: "userPassword") ?? ""
        NotificationManager.shared.deregisterDevice(wstoken: wstoken) {
            
        }
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "MoodleSession")
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "privateToken")
        
        do {
            let fileManager = FileManager()
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            let imagePath = documentsPath!.appendingPathComponent("timetable.jpg")
            if fileManager.fileExists(atPath: imagePath.relativePath) {
                try fileManager.removeItem(at: imagePath)
            }
        } catch {
            print("Error asdfsdf")
        }
            
        
        UserDefaults.standard.removeObject(forKey: "timetableURL")
        UserDefaults.standard.removeObject(forKey: "sessionTimestamp")
        
        completion()
    }
    
    public func isSignedIn() -> Bool {
        return realm.objects(User.self).count > 0
    }
    
    private init() {
        self.realm = try! Realm()
    }
}
