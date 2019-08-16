//
//  HelpViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 15/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import WebKit

class HelpVievController : UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewWillAppear(_ animated: Bool) {
        let url = URL(string: "https://docs.google.com/document/d/1FUMAdVXCWhrnFT18LpYdeIMwlWPAnOezRweKOE-CRtA/edit")
        let request = URLRequest(url: url!)
        self.navigationController?.navigationBar.isHidden = true
        webView.load(request)
    }
}
