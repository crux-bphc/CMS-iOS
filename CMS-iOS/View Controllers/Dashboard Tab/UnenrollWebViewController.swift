//
//  UnenrollWebViewController.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 12/25/20.
//  Copyright © 2020 Hridik Punukollu. All rights reserved.
//

import UIKit
import WebKit
import SwiftKeychainWrapper

class UnenrollWebViewController: UIViewController {

    let webView = WKWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        self.view = webView
        webView.load(URLRequest(url: URL(string: "https://cms.bits-hyderabad.ac.in/login/index.php")!))
        webView.allowsBackForwardNavigationGestures = false
        
        // Add observer
        webView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
    }
    
    // Observe value
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let key = change?[NSKeyValueChangeKey.newKey] {
            let newURL = "\(key)"
            if newURL != "https://cms.bits-hyderabad.ac.in/my/#" { return }
            self.webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                for cookie in cookies {
                    if cookie.name == "MoodleSession" {
                        let cookieVal = cookie.value
                        print("MoodleSession: \(cookieVal)")
                        KeychainWrapper.standard.set(cookieVal, forKey: "MoodleSession")
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }

}
