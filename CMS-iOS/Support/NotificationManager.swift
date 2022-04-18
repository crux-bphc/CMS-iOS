//
//  NotificationManager.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 1/13/21.
//  Copyright © 2021 Hridik Punukollu. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper
import Alamofire
import SwiftyJSON

class NotificationManager {
    
    static let shared = NotificationManager()
    
    private init() { }
    
    private func getModelIdentifier() -> String {
            if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
            var sysinfo = utsname()
            uname(&sysinfo) // ignore return value
            return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        }
    
    func registerDevice(deviceToken: String, completion: @escaping () -> Void) {
        let constants = Constants.Global.self
        let url = constants.BASE_URL + constants.REGISTER_DEVICE
        guard let wstoken = KeychainWrapper.standard.string(forKey: "userPassword") else { return }
        let deviceModel = getModelIdentifier()
        let deviceName = UIDevice.current.name
        let params = [
            "wstoken": wstoken,
            "appid": "crux.bphc.cms",
            "name": deviceName,
            "model": deviceModel,
            "platform": "iOS",
            "version": UIDevice.current.systemVersion,
            "pushid": deviceToken,
            "uuid": UIDevice.current.identifierForVendor!.uuidString
        ] as [String : Any]
        Alamofire.request(url, method: .get, parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                completion()
            } else {
                print("Failed")
            }
        }
    }
    
    func deregisterDevice(wstoken: String, completion: @escaping () -> Void) {
        let constants = Constants.Global.self
        let url = constants.BASE_URL + constants.DEREGISTER_DEVICE
        let params = [
            "appid": "crux.bphc.cms",
            "uuid": UIDevice.current.identifierForVendor!.uuidString,
            "wstoken": wstoken
        ]
        print(params)
        Alamofire.request(url, method: .get, parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                let jsonResponse = JSON(response.data!)
                print(jsonResponse)
                print(response.response?.statusCode)
                
            }
        }
    }
    
}
