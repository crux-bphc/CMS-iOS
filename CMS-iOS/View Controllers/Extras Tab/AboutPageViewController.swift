//
//  AboutPageViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 16/08/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import UIKit

class AboutPageViewController : UIViewController {
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cruxButtonPressed(_ sender: UIButton) {
         UIApplication.shared.open(URL(string: "https://crux-bphc.com")!, options: [:], completionHandler: nil)
    }
    
}
