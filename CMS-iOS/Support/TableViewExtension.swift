//
//  TableViewExtension.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 1/11/22.
//  Copyright © 2022 Crux BPHC. All rights reserved.
//

import UIKit

extension UITableView {
    
    func setEmptyView(title: String, message: String, refreshAction: @escaping () -> Void) {
        let emptyView = UIView(frame: CGRect(x: self.center.x, y: self.center.y, width: self.bounds.size.width, height: self.bounds.size.height))
        let titleLabel = UILabel()
        let messageLabel = UILabel()
        let refreshButton = UIButton()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 24)
        if #available(iOS 13.0, *) {
            messageLabel.textColor = .secondaryLabel
        } else {
            // Fallback on earlier versions
            messageLabel.textColor = .lightGray
        }
        refreshButton.setTitleColor(.systemBlue, for: .normal)
        refreshButton.actionHandler(controlEvents: .touchUpInside) {
            refreshAction()
        }
        messageLabel.font = UIFont(name: "HelveticaNeue-Regular", size: 17)
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        emptyView.addSubview(refreshButton)
        titleLabel.centerYAnchor.constraint(equalTo: emptyView.centerYAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor).isActive = true
        messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5).isActive = true
        messageLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 20).isActive = true
        messageLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -20).isActive = true
        refreshButton.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 20).isActive = true
        refreshButton.rightAnchor.constraint(equalTo: emptyView.rightAnchor, constant: -20).isActive = true
        refreshButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 5).isActive = true
        titleLabel.text = title
        messageLabel.text = message
        refreshButton.setTitle("Refresh", for: .normal)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        // The only tricky part is here:
        self.backgroundView = emptyView
        self.separatorStyle = .none
    }
    
    
    func restore() {
        self.backgroundView = nil
    }
}
