//
//  Regex.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 23/10/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import Foundation

public class Regex {
    class func match(pattern: String, text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let results = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error{
            print("The regex pattern was incorrect: \(error.localizedDescription)")
            return []
        }
    }
}
