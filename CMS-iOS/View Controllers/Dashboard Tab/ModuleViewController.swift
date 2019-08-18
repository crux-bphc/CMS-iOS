//
//  ModuleViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 14/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit

class ModuleViewController : UIViewController {
    
    var selectedModule = Module()
//    static let html: NSAttributedString.DocumentType
    
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var textConstraint: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        if selectedModule.description != "" {
        do {
            let formattedString = try NSAttributedString(data: ("<font size=\"+1.7\">\(selectedModule.description)</font>").data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ .documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
            descriptionText.attributedText = formattedString
        } catch let error {
            print("There was an error parsing HTML: \(error)")
        }
        
        descriptionText.isEditable = false
        } else {
            self.textConstraint.constant = 0
        }
    }
    
    @IBAction func openFileButtonPressed(_ sender: UIButton) {
        switch selectedModule.modname {
        case "url":
            UIApplication.shared.open(URL(string: self.selectedModule.fileurl)!, options: [:], completionHandler: nil)
            break
        case "resource":
            if let url = URL(string: selectedModule.fileurl) {
                let webView = UIWebView(frame: self.view.frame)
                webView.scalesPageToFit = true
                let urlRequest = URLRequest(url: url)
                webView.loadRequest(urlRequest as URLRequest)
                
                let fileVC = UIViewController()
                fileVC.view.addSubview(webView)
                fileVC.title = self.selectedModule.name
                self.navigationController?.pushViewController(fileVC, animated: true)
            }
            break
        default:
            let alert = UIAlertController(title: "Error", message: "Unable to open attachment", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
