//
//  CourseTableViewself.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 10/10/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import GradientLoadingBar
class CourseTableViewCell: UITableViewCell {
    
    @IBOutlet weak var courseName: UILabel!
    @IBOutlet weak var containView: UIView!
    var gradientProgressIndicatorView = GradientActivityIndicatorView()
    @IBOutlet weak var courseFullName: UILabel!
    @IBOutlet weak var unreadCounterLabel: UILabel!
    @IBOutlet weak var semesterLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.containView.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.containView.layer.cornerRadius = 15
        self.containView.clipsToBounds = true
        self.semesterLabel.isHidden = true
        if #available(iOS 13.0, *) {
//            self.contentView.layer.backgroundColor = UIColor.systemBackground.cgColor
            switch traitCollection.userInterfaceStyle {
            case .dark:
                //                self.courseProgress.tintColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
                break
            default:
                break
                //                self.courseProgress.tintColor = #colorLiteral(red: 0.9372549057, green: 0.5625251839, blue: 0.3577104232, alpha: 1)
            }
        } else {
//            self.contentView.layer.backgroundColor = UIColor.white.cgColor
            //            self.courseProgress.tintColor = #colorLiteral(red: 0.9372549057, green: 0.5625251839, blue: 0.3577104232, alpha: 1)
        }
        
        if #available(iOS 13.0, *) {
//            self.containView.layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
        } else {
//            self.containView.layer.backgroundColor = UIColor.white.cgColor
        }
        //        self.courseProgress.progress = 1.0
        //        self.activityIndicator.isHidden = true
        self.courseFullName.adjustsFontSizeToFitWidth = true
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
//            self.contentView.layer.backgroundColor = UIColor.systemBackground.cgColor
//            self.containView.layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
            switch traitCollection.userInterfaceStyle {
            case .dark:
                //                self.courseProgress.tintColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
                break
            default: break
                //                self.courseProgress.tintColor = #colorLiteral(red: 0.9372549057, green: 0.5625251839, blue: 0.3577104232, alpha: 1)
            }
        } else {
//            self.containView.layer.backgroundColor = UIColor.white.cgColor
//            self.containView.layer.backgroundColor = UIColor.white.cgColor
            //            self.courseProgress.tintColor = #colorLiteral(red: 0.9372549057, green: 0.5625251839, blue: 0.3577104232, alpha: 1)
        }
    }
    func showGradientLoadingBar() {
    
        gradientProgressIndicatorView.isHidden = false
        gradientProgressIndicatorView.fadeOut(duration: 0)
        
        gradientProgressIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        containView.addSubview(gradientProgressIndicatorView)
        
        NSLayoutConstraint.activate([
            gradientProgressIndicatorView.leadingAnchor.constraint(equalTo: containView.leadingAnchor),
            gradientProgressIndicatorView.trailingAnchor.constraint(equalTo: containView.trailingAnchor),
            
            gradientProgressIndicatorView.bottomAnchor.constraint(equalTo: containView.bottomAnchor),
            gradientProgressIndicatorView.heightAnchor.constraint(equalToConstant: 3.0)
        ])
        gradientProgressIndicatorView.fadeIn()
    }
    func hideGradientLoadingBar() {
        gradientProgressIndicatorView.fadeOut()
        gradientProgressIndicatorView.isHidden = true
        
    }
    
    func showSemesterLabel(text: String) {
        semesterLabel.isHidden = false
        semesterLabel.text = text
    }
    
    func hideSemesterLabel() {
        semesterLabel.isHidden = true
    }
    
}
