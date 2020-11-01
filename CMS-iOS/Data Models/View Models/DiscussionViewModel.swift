//
//  DiscussionViewModel.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 10/1/20.
//  Copyright © 2020 Hridik Punukollu. All rights reserved.
//

import UIKit

class DiscussionViewModel {
    
    var name: String
    var description: String
    var date: String
    var id: Int
    var titleFont: UIFont
    var desciptionFont: UIFont
    var dateFont: UIFont
    
    init(name: String, id: Int, description: String, date: String, read: Bool) {
        self.name = name
        self.description = description
        self.id = id
        self.date = date
        if !read {
            titleFont = UIFont.systemFont(ofSize: 17.0, weight: .bold)
            dateFont = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
            desciptionFont = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
        } else {
            titleFont = UIFont.systemFont(ofSize: 17.0, weight: .medium)
            dateFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            desciptionFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
        }
    }
    
    func markRead() {
        titleFont = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        dateFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        desciptionFont = UIFont.systemFont(ofSize: 14.0, weight: .regular)
    }
}
