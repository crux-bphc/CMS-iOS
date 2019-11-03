//
//  UIColorExtension.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 11/3/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
public extension UIColor {

     class func StringFromUIColor(color: UIColor) -> String {
        let components = color.cgColor.components
        return "[\(components![0]), \(components![1]), \(components![2]), \(components![3])]"
     }
     
     class func UIColorFromString(string: String) -> UIColor {
        print("String = \(string)")
        let componentsString = string.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
         let components = componentsString.components(separatedBy: ", ")
         return UIColor(red: CGFloat((components[0] as NSString).floatValue),
                      green: CGFloat((components[1] as NSString).floatValue),
                       blue: CGFloat((components[2] as NSString).floatValue),
                      alpha: CGFloat((components[3] as NSString).floatValue))
     }
     
 }
