//
//  SpotlightIndex.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 7/7/20.
//  Copyright © 2020 Crux BPHC. All rights reserved.
//

import CoreSpotlight
import MobileCoreServices

class SpotlightIndex {
    
    static let shared = SpotlightIndex()
    func indexItems(courses: [DashboardViewModel]) {
        var items = [CSSearchableItem]()
        
        for course in courses {
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
            attributeSet.title = course.courseName
            attributeSet.contentDescription = course.courseCode

            let item = CSSearchableItem(uniqueIdentifier: "course=\(course.courseId)", domainIdentifier: "com.crux-bphc", attributeSet: attributeSet)
            items.append(item)
        }
        
        CSSearchableIndex.default().indexSearchableItems(items) { error in
            if let error = error {
                print("Indexing error: \(error.localizedDescription)")
            } else {
                print("Search item successfully indexed!")
            }
        }
    }
    
    func deindexAllItems() {
        CSSearchableIndex.default().deleteAllSearchableItems { (error) in
            print(error ?? "Error")
        }
    }
    
    private init() { }
}


