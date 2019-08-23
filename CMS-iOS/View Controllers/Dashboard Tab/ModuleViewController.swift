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
    
//    func getFileExtension(path: String) -> String {
//        let mimeType: CFString = path as CFString
//        guard
//            let mimeUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, nil)?.takeUnretainedValue()
//            else { return "" }
//
//        guard
//            let extUTI = UTTypeCopyPreferredTagWithClass(mimeUTI, kUTTagClassFilenameExtension)?.takeRetainedValue()
//            else { return "" }
//        //print(extUTI)
//        return extUTI as String
//    }
    
    func saveFileToStorage(mime: String, downloadUrl: String, module: Module) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print(String(describing: documentsDirectory))
        let dataPath = documentsDirectory.absoluteURL
//        let fileExists = FileManager().fileExists(atPath: dataPath.path)
//        let extn = getFileExtension(path: mime)
        guard let url = URL(string: downloadUrl) else { return }
        let destination = dataPath.appendingPathComponent("\(module.filename)")
        if FileManager().fileExists(atPath: destination.path) {
            let viewURL = destination as URL
            let data = try! Data(contentsOf: viewURL)
            let webView = UIWebView(frame: self.view.frame)
            webView.load(data, mimeType: self.selectedModule.mimetype, textEncodingName: "", baseURL: viewURL.deletingLastPathComponent())
            webView.scalesPageToFit = true
            let docVC = UIViewController()
            docVC.view.addSubview(webView)
            docVC.title = self.selectedModule.name
            self.navigationController?.pushViewController(docVC, animated: true)
        } else {
            download(url: url, to: destination) {
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    let viewURL = destination as URL
                    let data = try! Data(contentsOf: viewURL)
                    let webView = UIWebView(frame: self.view.frame)
                    webView.load(data, mimeType: self.selectedModule.mimetype, textEncodingName: "", baseURL: viewURL.deletingLastPathComponent())
                    webView.scalesPageToFit = true
                    let docVC = UIViewController()
                    docVC.view.addSubview(webView)
                    docVC.title = self.selectedModule.name
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
    
    
//    @IBAction func openFileButtonPressed(_ sender: UIButton) {
//        switch selectedModule.modname {
//        case "url":
//            UIApplication.shared.open(URL(string: self.selectedModule.fileurl)!, options: [:], completionHandler: nil)
//            break
//        case "resource":
//            if let url = URL(string: selectedModule.fileurl) {
//                let webView = UIWebView(frame: self.view.frame)
//                webView.scalesPageToFit = true
//                let urlRequest = URLRequest(url: url)
//                webView.loadRequest(urlRequest as URLRequest)
//
//                let fileVC = UIViewController()
//                fileVC.view.addSubview(webView)
//                fileVC.title = self.selectedModule.name
//                self.navigationController?.pushViewController(fileVC, animated: true)
//            }
//            break
//        default:
//            let alert = UIAlertController(title: "Error", message: "Unable to open attachment", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
//            self.present(alert, animated: true, completion: nil)
//        }
//    }
    
    @IBAction func openFileButtonPressed(_ sender: UIButton) {
        switch selectedModule.modname {
        case "url":
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
}
