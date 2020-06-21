//
//  StringExtension.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 4/25/20.
//  Copyright © 2020 Hridik Punukollu. All rights reserved.
//

import Foundation

extension String {
    
    func cleanUp() -> String {
        let clean = self.replacingOccurrences(of: "&amp;", with: "&")
        return clean
    }
    
}
