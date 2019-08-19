//
//  DiscussionViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 20/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit

class DiscussionViewController: UIViewController {

    @IBOutlet weak var bodyTextView: UITextView!
    
    var selectedDiscussion = Discussion()
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedDiscussion.message != "" {
            do {
                let formattedString = try NSAttributedString(data: ("<font size=\"+1.7\">\(selectedDiscussion.message)</font>").data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ .documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
                bodyTextView.attributedText = formattedString
            } catch let error {
                print("There was an error parsing HTML: \(error)")
            }
            
            bodyTextView.isEditable = false
        }
        }
        // Do any additional setup after loading the view.
    @IBAction func openAttachmentPressed(_ sender: Any) {
        if let url = URL(string: selectedDiscussion.attachment) {
            let webView = UIWebView(frame: self.view.frame)
            webView.scalesPageToFit = true
            let urlRequest = URLRequest(url: url)
            webView.loadRequest(urlRequest as URLRequest)
            
            let fileVC = UIViewController()
            fileVC.view.addSubview(webView)
            fileVC.title = self.selectedDiscussion.name
            self.navigationController?.pushViewController(fileVC, animated: true)
        }
    }
}


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

