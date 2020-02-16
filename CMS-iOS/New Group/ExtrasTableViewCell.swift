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

    @IBOutlet weak var iconImage: UIImageView!
    
    @IBOutlet weak var colorView: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        let layer = containerView.layer
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.cornerRadius = 15
        containerView.clipsToBounds = true
        if #available(iOS 13.0, *) {
            layer.backgroundColor = UIColor.secondarySystemBackground.cgColor
            self.contentView.layer.backgroundColor = UIColor.systemBackground.cgColor
            
            
        } else {
            layer.backgroundColor = UIColor.white.cgColor
            self.contentView.layer.backgroundColor = UIColor.white.cgColor
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
                
            
            } else {
                self.containerView.layer.backgroundColor = UIColor.white.cgColor
                self.containerView.layer.backgroundColor = UIColor.white.cgColor
            }
    }
    
}
