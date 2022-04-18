//
//  UIViewControllerExtension.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 3/18/22.
//  Copyright © 2022 Crux BPHC. All rights reserved.
//

import UIKit
import SVProgressHUD

extension UIViewController {
    func showLoadingIndicator(message: String?) {
        if message != nil {
            SVProgressHUD.show(withStatus: message)
        } else {
            SVProgressHUD.show()
        }
    }
    
    func dismissLoadingIndicator() {
        SVProgressHUD.dismiss()
    }
}

