//
//  DiscussionViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 20/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import SVProgressHUD

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
    
    func saveFileToStorage(mime: String, downloadUrl: String, discussion: Discussion) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print(String(describing: documentsDirectory))
        let dataPath = documentsDirectory.absoluteURL
        
        guard let url = URL(string: downloadUrl) else { return }
        let destination = dataPath.appendingPathComponent("\(discussion.filename)")
        if FileManager().fileExists(atPath: destination.path) {
            let viewURL = destination as URL
            let data = try! Data(contentsOf: viewURL)
            let webView = UIWebView(frame: self.view.frame)
            webView.load(data, mimeType: self.selectedDiscussion.mimetype, textEncodingName: "", baseURL: viewURL.deletingLastPathComponent())
            webView.scalesPageToFit = true
            let docVC = UIViewController()
            docVC.view.addSubview(webView)
            docVC.title = self.selectedDiscussion.name
            self.navigationController?.pushViewController(docVC, animated: true)
        } else {
            download(url: url, to: destination) {
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    let viewURL = destination as URL
                    let data = try! Data(contentsOf: viewURL)
                    let webView = UIWebView(frame: self.view.frame)
                    webView.load(data, mimeType: self.selectedDiscussion.mimetype, textEncodingName: "", baseURL: viewURL.deletingLastPathComponent())
                    webView.scalesPageToFit = true
                    let docVC = UIViewController()
                    docVC.view.addSubview(webView)
                    docVC.title = self.selectedDiscussion.name
                    self.navigationController?.pushViewController(docVC, animated: true)
                }
            }
        }
    }
    
    func download(url: URL, to localUrl: URL, completion: @escaping () -> Void) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        SVProgressHUD.show()
        
        let task = session.downloadTask(with: request) {(tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print(statusCode)
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: localUrl)
                    print("Saved")
                    completion()
                } catch (let writeError){
                    print("there was an error: \(writeError)")
                }
            } else {
                print("failure")
            }
        }
        task.resume()
    }
    
    // Do any additional setup after loading the view.
    @IBAction func openAttachmentPressed(_ sender: Any) {
        print(selectedDiscussion.filename)
        if selectedDiscussion.attachment != "" {
            if selectedDiscussion.attachment.contains("td.bits-hyderabad.ac.in") {
                saveFileToStorage(mime: self.selectedDiscussion.mimetype, downloadUrl: selectedDiscussion.attachment, discussion: selectedDiscussion)
            } else {
                UIApplication.shared.open(URL(string: self.selectedDiscussion.attachment)!, options: [:], completionHandler: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "Unable to open attachment", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
