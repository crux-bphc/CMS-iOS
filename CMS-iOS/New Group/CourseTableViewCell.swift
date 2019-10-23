//
//  CourseTableViewCell.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 10/10/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit

class CourseTableViewCell: UITableViewCell {

    @IBOutlet weak var courseName: UILabel!
    @IBOutlet weak var courseProgress: UIProgressView!
    @IBOutlet weak var containView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var downloadIndicatorLabel: UILabel!
    @IBOutlet weak var courseFullName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
