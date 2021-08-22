//
//  CourseViewModel.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 10/21/20.
//  Copyright © 2020 Crux BPHC. All rights reserved.
//

import UIKit

class DashboardViewModel {
    
    var courseCode: String
    var courseName: String
    var courseId: Int
    var courseColor: UIColor
    var unreadCount: Int = 0
    var shouldShowUnreadCounter: Bool = false
    
    init(courseCode: String, courseName: String, courseId: Int, courseColor: UIColor) {
        self.courseCode = courseCode
        self.courseName = courseName
        self.courseColor = courseColor
        self.courseId = courseId
    }
}
