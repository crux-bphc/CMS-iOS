//
//  UnenrollWebViewController.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 12/25/20.
//  Copyright © 2020 Crux BPHC. All rights reserved.
//

import UIKit
import WebKit
import SwiftKeychainWrapper

class UnenrollWebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.view = webView
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 14_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.2 Mobile/15E148 Safari/604.1"
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
                        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: "com.crux-bphc.CMS-iOS.unenroll")))
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
