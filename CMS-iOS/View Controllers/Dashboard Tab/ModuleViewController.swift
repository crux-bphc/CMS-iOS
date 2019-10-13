//
//  ModuleViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 14/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import MobileCoreServices
import SVProgressHUD
import SwiftKeychainWrapper

class ModuleViewController : UIViewController, URLSessionDownloadDelegate{
    
    var selectedModule = Module()
    var destinationURL = URL(string: "")
    var locationToCopy = URL(string: "")
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var textConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(selectedModule.modname)
        if selectedModule.modname == "resource" || selectedModule.modname == "url" {
            attachmentButton.isHidden = false
        } else {
            attachmentButton.isHidden = true
        }
        
        setDescription()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    func setDescription(){
        if selectedModule.moduleDescription != "" {
            do {
                print(selectedModule.moduleDescription)
                
                let formattedString = try NSAttributedString(data: ("<font size=\"+2\">\(selectedModule.moduleDescription)</font>").data(using: String.Encoding.unicode, allowLossyConversion: true)!, options: [ .documentType : NSAttributedString.DocumentType.html], documentAttributes: nil)
                var attributedStringName = [NSAttributedString.Key : Any]()
                if #available(iOS 13.0, *) {
                    attributedStringName = [.foregroundColor: UIColor.label]
                }else{
                    attributedStringName = [.foregroundColor: UIColor.black]
                    
                }
                let string = NSMutableAttributedString(attributedString: formattedString)
                string.addAttributes(attributedStringName, range: NSRange(location: 0, length: formattedString.length))
                descriptionText.attributedText = string
            } catch let error {
                print("There was an error parsing HTML: \(error)")
            }
            
            descriptionText.isEditable = false
        } else {
            self.textConstraint.constant = 0
        }
    }
    
    func saveFileToStorage(mime: String, downloadUrl: String, module: Module) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print(String(describing: documentsDirectory))
        let dataPath = documentsDirectory.absoluteURL
        
        guard let url = URL(string: downloadUrl) else { return }
        let destination = dataPath.appendingPathComponent("\(String(module.id) + module.filename)")
        if FileManager().fileExists(atPath: destination.path) {
            let viewURL = destination as URL
            let data = try! Data(contentsOf: viewURL)
            let webView = UIWebView(frame: self.view.frame)
            webView.load(data, mimeType: self.selectedModule.mimetype, textEncodingName: "", baseURL: viewURL.deletingLastPathComponent())
            webView.scalesPageToFit = true
            let docVC = UIViewController()
            docVC.view.addSubview(webView)
            if selectedModule.name != ""{
                docVC.title = self.selectedModule.name
                
            } else{
                docVC.title = self.selectedModule.filename
            }
            self.navigationController?.pushViewController(docVC, animated: true)
        } else {
            if Reachability.isConnectedToNetwork() {
                destinationURL = destination
                download(url: url, to: destination)
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                let alert = UIAlertController(title: "Unable to download", message: "The file cannot be downloaded as the device is offline.", preferredStyle: .alert)
                let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func openFile(){
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        let data = try! Data(contentsOf: destinationURL!)
        let webView = UIWebView(frame: self.view.frame)
        webView.load(data, mimeType: self.selectedModule.mimetype, textEncodingName: "", baseURL: destinationURL!.deletingLastPathComponent())
        webView.scalesPageToFit = true
        let docVC = UIViewController()
        docVC.view.addSubview(webView)
        docVC.title = self.selectedModule.name
        self.navigationController?.pushViewController(docVC, animated: true)
    }
    func download(url: URL, to localUrl: URL) {
        locationToCopy = localUrl
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = session.downloadTask(with: request)
        SVProgressHUD.showProgress(0)
        task.resume()
    }
    
    @IBAction func openFileButtonPressed(_ sender: UIButton) {
        switch selectedModule.modname {
        case "url":
            print(self.selectedModule.fileurl)
            UIApplication.shared.open(URL(string: self.selectedModule.fileurl)!, options: [:], completionHandler: nil)
            break
        case "resource":
            saveFileToStorage(mime: self.selectedModule.mimetype, downloadUrl: selectedModule.fileurl, module: selectedModule)
            break
        default:
            let alert = UIAlertController(title: "Error", message: "Unable to open attachment", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        setDescription()
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.copyItem(at: location, to: locationToCopy!)
            print("Saved")
            openFile()
        } catch (let writeError){
            print("there was an error: \(writeError)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        SVProgressHUD.showProgress(Float((downloadProgress)))
    }    
}
