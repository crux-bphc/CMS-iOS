//
//  DiscussionViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 20/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import SVProgressHUD
import QuickLook

class DiscussionViewController: UIViewController, QLPreviewControllerDataSource{
    
    @IBOutlet weak var bodyTextView: UITextView!
    @IBOutlet weak var openButton: UIButton!
    
    var quickLookController = QLPreviewController()
    var selectedDiscussion = Discussion()
    var qlLocation = URL(string: "")
    var discussionName : String = "Site_News"
    let constant = Constants.Global.self
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        quickLookController.dataSource = self
        openButton.layer.cornerRadius = 10
        bodyTextView.layer.cornerRadius = 10
        self.title = selectedDiscussion.name.replacingOccurrences(of: "📌 ", with: "")
        if UIApplication.shared.applicationState == .active {
            setMessage()
        }
        self.navigationItem.largeTitleDisplayMode = .never
        if selectedDiscussion.attachment == "" {
            self.openButton.isHidden = true
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    func setMessage() {
        if selectedDiscussion.message != "" {
            do {
                let formattedString = try NSAttributedString(data: ("<font size=\"+1.7\">\(selectedDiscussion.message)</font>").data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ .documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
                var attributedStringName = [NSAttributedString.Key : Any]()
                if #available(iOS 13.0, *) {
                    attributedStringName = [.foregroundColor: UIColor.label]
                }else{
                    attributedStringName = [.foregroundColor: UIColor.black]

                }
                let string = NSMutableAttributedString(attributedString: formattedString)
                string.setFontFace(font: UIFont.systemFont(ofSize: 15))
                string.addAttributes(attributedStringName, range: NSRange(location: 0, length: formattedString.length))
                bodyTextView.attributedText = string
            } catch let error {
                print("There was an error parsing HTML: \(error)")
            }
            
            bodyTextView.isEditable = false
        }
    }
    
    func saveFileToStorage(mime: String, downloadUrl: String, discussion: Discussion) {
        clearTempDirectory()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.absoluteURL
        
        guard let url = URL(string: downloadUrl) else { return }
        let folderDestination = dataPath.appendingPathComponent("\(self.discussionName)")
        var destination : URL = dataPath
        var isDir : ObjCBool = false
        if FileManager().fileExists(atPath: folderDestination.path, isDirectory: &isDir) {
            if isDir.boolValue {
                destination = folderDestination.appendingPathComponent("\(String(selectedDiscussion.id) + discussion.filename)")
            } else {
                do {
                    try FileManager.default.createDirectory(at: folderDestination, withIntermediateDirectories: true, attributes: nil)
                    destination = folderDestination.appendingPathComponent("\(String(selectedDiscussion.id) + discussion.filename)")
                } catch {
                    print("There was an error in making the directory: \(error)")
                }
            }
        } else {
            do {
                try FileManager.default.createDirectory(at: folderDestination, withIntermediateDirectories: true, attributes: nil)
                destination = folderDestination.appendingPathComponent("\(String(selectedDiscussion.id) + discussion.filename)")
            } catch {
                print("There was an error in making the directory: \(error)")
            }
        }
        if FileManager().fileExists(atPath: destination.path) {
            qlLocation = destination
            openWithQL()
        } else {
            downloadFile(from: url, to: destination) {
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    self.qlLocation = destination
                    self.openWithQL()
                }
            }
        }
    }
    
    func downloadFile(from : URL, to: URL, completionHanadler: @escaping () -> Void ) {
        SVProgressHUD.show()
        let request = URLRequest(url: from)
        let _ = constant.downloadManager.downloadFile(withRequest: request, shouldDownloadInBackground: true) { (error, url) in
            if error != nil {
                print("There was an error in downloading the file: \(error!)")
            } else {
                print("The file was downloaded to: \(String(describing: url))")
                do {
                    try FileManager.default.copyItem(at: url!, to: to)
                    try FileManager.default.removeItem(at: url!)
                    completionHanadler()
                } catch {
                    print("There was an error in copying/removing the file from/to the location.")
                }
            }
        }
    }
    
    func clearTempDirectory() {
        let fileManager = FileManager.default
        let cachesDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        do {
            try fileManager.removeItem(atPath: cachesDirectory)
        } catch let error {
            print("There was an error in deleting the caches directory: \(error)")
        }
    }
    
    // Do any additional setup after loading the view.
    @IBAction func openAttachmentPressed(_ sender: Any) {
        if selectedDiscussion.attachment != "" {
            if selectedDiscussion.attachment.contains("cms.bits-hyderabad.ac.in") {
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
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if UIApplication.shared.applicationState == .active {
            setMessage()
        }
    }
    func openWithQL() {
        self.present(quickLookController, animated: true) {
            // completion
        }
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let item = PreviewItem()
        item.previewItemURL = qlLocation!
        item.previewItemTitle = selectedDiscussion.filename
        return item
    }
}
