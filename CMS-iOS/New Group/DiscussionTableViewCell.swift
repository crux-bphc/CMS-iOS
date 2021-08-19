//
//  DiscussionTableViewCell.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 31/01/20.
//  Copyright © 2020 Crux BPHC. All rights reserved.
//

import UIKit

class DiscussionTableViewCell: UITableViewCell {

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentPreviewLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
//    var cellDiscussion = Discussion()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentPreviewLabel.lineBreakMode = .byTruncatingTail
//        timeLabel.text = setTimestamp(epochTime: "\(self.cellDiscussion.date)")
//        contentPreviewLabel.text = cellDiscussion.message
//        titleLabel.text = cellDiscussion.name
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
//    func setTimestamp(epochTime: String) -> String {
//        let currentDate = Date()
//        let epochDate = Date(timeIntervalSince1970: TimeInterval(epochTime) as! TimeInterval)
//
//        let calendar = Calendar.current
//
//        let currentDay = calendar.component(.day, from: currentDate)
//        let currentHour = calendar.component(.hour, from: currentDate)
//        let currentMinutes = calendar.component(.minute, from: currentDate)
//        let currentSeconds = calendar.component(.second, from: currentDate)
//
//        let epochDay = calendar.component(.day, from: epochDate)
//        let epochMonth = calendar.component(.month, from: epochDate)
//        let epochYear = calendar.component(.year, from: epochDate)
//        let epochHour = calendar.component(.hour, from: epochDate)
//        let epochMinutes = calendar.component(.minute, from: epochDate)
//        let epochSeconds = calendar.component(.second, from: epochDate)
//
//        if (currentDay - epochDay < 30) {
//            if (currentDay == epochDay) {
//                if (currentHour - epochHour == 0) {
//                    if (currentMinutes - epochMinutes == 0) {
//                        if (currentSeconds - epochSeconds <= 1) {
//                            return String(currentSeconds - epochSeconds) + " second ago"
//                        } else {
//                            return String(currentSeconds - epochSeconds) + " seconds ago"
//                        }
//
//                    } else if (currentMinutes - epochMinutes <= 1) {
//                        return String(currentMinutes - epochMinutes) + " minute ago"
//                    } else {
//                        return String(currentMinutes - epochMinutes) + " minutes ago"
//                    }
//                } else if (currentHour - epochHour <= 1) {
//                    return String(currentHour - epochHour) + " hour ago"
//                } else {
//                    return String(currentHour - epochHour) + " hours ago"
//                }
//            } else if (currentDay - epochDay <= 1) {
//                return String(currentDay - epochDay) + " day ago"
//            } else {
//                return String(currentDay - epochDay) + " days ago"
//            }
//        } else {
//            return String(epochDay) + " " + getMonthNameFromInt(month: epochMonth) + " " + String(epochYear)
//        }
//    }
//
//
//    func getMonthNameFromInt(month: Int) -> String {
//        switch month {
//        case 1:
//            return "Jan"
//        case 2:
//            return "Feb"
//        case 3:
//            return "Mar"
//        case 4:
//            return "Apr"
//        case 5:
//            return "May"
//        case 6:
//            return "Jun"
//        case 7:
//            return "Jul"
//        case 8:
//            return "Aug"
//        case 9:
//            return "Sept"
//        case 10:
//            return "Oct"
//        case 11:
//            return "Nov"
//        case 12:
//            return "Dec"
//        default:
//            return ""
//        }
//    }
    
}
