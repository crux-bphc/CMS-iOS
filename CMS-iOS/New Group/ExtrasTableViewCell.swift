//
//  ExtrasTableViewCell.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 24/10/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit

class ExtrasTableViewCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var progressTint: UIProgressView!
    override func awakeFromNib() {
        super.awakeFromNib()
        let layer = containerView.layer
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.cornerRadius = 15
        progressTint.layer.masksToBounds = true
        containerView.clipsToBounds = true
        if #available(iOS 13.0, *) {
            layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
            self.contentView.layer.backgroundColor = UIColor.systemBackground.cgColor
            if traitCollection.userInterfaceStyle == .dark {
                self.progressTint.tintColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
            } else {
                self.progressTint.tintColor = #colorLiteral(red: 0.9372549057, green: 0.5625251839, blue: 0.3577104232, alpha: 1)
            }
        } else {
            layer.backgroundColor = UIColor.white.cgColor
            self.contentView.layer.backgroundColor = UIColor.white.cgColor
            self.progressTint.tintColor = #colorLiteral(red: 0.9372549057, green: 0.5625251839, blue: 0.3577104232, alpha: 1)
        }
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
                self.contentView.layer.backgroundColor = UIColor.systemBackground.cgColor
                self.containerView.layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    self.progressTint.tintColor = #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1)
                    break
                default:
                    self.progressTint.tintColor = #colorLiteral(red: 0.9372549057, green: 0.5625251839, blue: 0.3577104232, alpha: 1)
                }
            } else {
                self.containerView.layer.backgroundColor = UIColor.white.cgColor
                self.containerView.layer.backgroundColor = UIColor.white.cgColor
                self.progressTint.tintColor = #colorLiteral(red: 0.9372549057, green: 0.5625251839, blue: 0.3577104232, alpha: 1)
            }
    }
    
}
