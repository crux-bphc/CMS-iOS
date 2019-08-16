////
////  APIRequests.swift
////  CMS-iOS
////
////  Created by Hridik Punukollu on 12/08/19.
////  Copyright © 2019 Hridik Punukollu. All rights reserved.
////
//
//import UIKit
//import Alamofire
//import SwiftyJSON
//
//let constant = Constants.Global.self
//
//public func logIn(secret: String, completion: @escaping (JSON) -> JSON){
//    let headers : HTTPHeaders = ["Accept" : "application/json"]
//    let params : [String:String] = ["wstoken" : secret]
//    let FINAL_URL = constant.BASE_URL + constant.LOGIN
//    Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: headers).responseJSON { (response) in
//        if response.result.isSuccess {
//            completion(JSON(response.result))
//        }
//    }
//}
//
