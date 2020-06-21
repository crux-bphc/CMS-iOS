//
//  StringCleanUpExtension.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 2/18/20.
//  Copyright © 2020 Hridik Punukollu. All rights reserved.
//

import Foundation

extension String {
    
    func cleanUp() -> String {
        var clean = self
        clean = clean.replacingOccurrences(of: "&amp;", with: "&")
        
        return clean
    }
    
}
