//
//  StringExtension.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 4/25/20.
//  Copyright © 2020 Crux BPHC. All rights reserved.
//

import Foundation

extension String {
    
    func cleanUp() -> String {
        let clean = self.replacingOccurrences(of: "&amp;", with: "&")
//        clean = clean.replacingOccurrences(of: "FIRST SEMESTER 2020-21", with: "")
        return clean
    }
    
    func removeSemester() -> String {
        let clean = self.replacingOccurrences(of: " Sem 2 2021-22", with: "")
        return clean
    }
    
}
