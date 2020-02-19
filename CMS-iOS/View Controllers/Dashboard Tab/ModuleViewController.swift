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
import QuickLook
import RealmSwift
import NotificationBannerSwift


class ModuleViewController : UIViewController, QLPreviewControllerDataSource{
    
    var quickLookController = QLPreviewController()
    var selectedModule = Module()
    var destinationURL = URL(string: "")
    var locationToCopy = URL(string: "")
    let constants = Constants.Global.self
    
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var textConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var downloadProgressLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionText.layer.cornerRadius = 10
        openButton.layer.cornerRadius = 10
        quickLookController.dataSource = self
        openButton.isEnabled = true
        if selectedModule.name != "" {
            self.title = selectedModule.name
        } else {
            self.title = selectedModule.filename
        }
        print(selectedModule.modname)
        if selectedModule.modname == "resource" || selectedModule.modname == "url" {
            attachmentButton.isHidden = false
        } else {
            attachmentButton.isHidden = true
        }
        if UIApplication.shared.applicationState == .active {
            setDescription()
        }
        progressBar.isHidden = true
        downloadProgressLabel.isHidden = true
        cancelButton.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        constants.downloadManager.cancelAllDownloads()
        self.progressBar.isHidden = true
        self.downloadProgressLabel.isHidden = true
        self.cancelButton.isHidden = true
    }
    override func viewWillAppear(_ animated: Bool) {
        openButton.isEnabled = true
        let realm = try! Realm()
        try! realm.write {
            selectedModule.read = true
        }
        print(selectedModule.read)
    }
    
    func setDescription() {
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
                string.setFontFace(font: UIFont.systemFont(ofSize: 15))
                string.addAttributes(attributedStringName, range: NSRange(location: 0, length: formattedString.length))
                descriptionText.attributedText = string
            } catch let error {
                print("There was an error parsing HTML: \(error)")
            }
            
            descriptionText.isEditable = false
        } else {
            self.textConstraint.constant = self.view.frame.height - 16
        }
    }
    
    func saveFileToStorage(mime: String, downloadUrl: String, module: Module) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print(String(describing: documentsDirectory))
        let dataPath = documentsDirectory.absoluteURL
        
        guard let url = URL(string: downloadUrl) else { return }
        var destination1 : URL = dataPath
        var isDir : ObjCBool = false
        if FileManager.default.fileExists(atPath: dataPath.appendingPathComponent(module.coursename).path, isDirectory: &isDir) {
            if isDir.boolValue  {
                //                Directory exists
                destination1 = dataPath.appendingPathComponent(module.coursename)
                print(module.coursename)
                print("Changed destination1 to \(destination1)")
                
            } else {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath.appendingPathComponent(module.coursename).path, withIntermediateDirectories: true, attributes: nil)
                    destination1 = dataPath.appendingPathComponent(module.coursename)
                    print("Changed destination1 to \(destination1)")
                } catch {
                    print("There was an error in making the directory at path: \(dataPath.appendingPathComponent(module.coursename))")
                }
            }
        } else {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.appendingPathComponent(module.coursename).path, withIntermediateDirectories: true, attributes: nil)
                destination1 = dataPath.appendingPathComponent(module.coursename)
                print("Changed destination1 to \(destination1)")
            } catch {
                print("There was an error in making the directory at path: \(dataPath.appendingPathComponent(module.coursename))")
            }
        }
        
        let destination = destination1.appendingPathComponent("\(String(module.id) + module.filename)")
        if FileManager().fileExists(atPath: destination.path) {
            locationToCopy = destination as URL
            openWithQL()
        } else {
            if Reachability.isConnectedToNetwork() {
                destinationURL = destination
                //                download(url: url, to: destination)
                downloadFile(downloadURL: url, localURL: destination) {
                    self.locationToCopy = destination
                    self.openFile()
                }
            } else {
                let offlineBanner = NotificationBanner(title: "Offline", subtitle: "Your device is offline.", style: .danger)
                if !offlineBanner.isDisplaying {
                    offlineBanner.show()
                }
            }
        }
    }
    
    func openFile() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        openWithQL()
    }
    
    func downloadFile(downloadURL: URL, localURL: URL, completion: @escaping () -> Void ) {
        constants.downloadManager.showLocalNotificationOnBackgroundDownloadDone = true
        constants.downloadManager.localNotificationText = "Module completed download."
        let request = URLRequest(url: downloadURL)
        let downloadKey = constants.downloadManager.downloadFile(withRequest: request, shouldDownloadInBackground: false, onProgress: { (progress) in
            self.progressBar.isHidden = false
            self.downloadProgressLabel.isHidden = false
            self.progressBar.progress = Float(progress)
            self.downloadProgressLabel.text = "Downloading: \(Int(progress * 100))%"
            self.cancelButton.isHidden = false
            self.cancelButton.isEnabled = true
        }) { (error, localFileURL) in
            if error != nil {
                print("There was an error while downloading the file. \(String(describing: error))")
            } else {
                print("The file was downloaded to the location: \(String(describing: localFileURL))")
                do {
                    try FileManager.default.copyItem(at: localFileURL!, to: localURL)
                } catch (let writeError) {
                    print("there was an error in writing: \(writeError)")
                }
                do {
                    try FileManager.default.removeItem(at: localFileURL!)
                } catch let removeError {
                    print("There was an error in removing: \(removeError)")
                }
                completion()
            }
        }
        print("The download key is: \(downloadKey ?? "")")
        locationToCopy = localURL as URL
        self.progressBar.isHidden = true
        self.cancelButton.isEnabled = false
        self.cancelButton.isHidden = true
        self.downloadProgressLabel.isHidden = true
    }
    
    @IBAction func openFileButtonPressed(_ sender: UIButton) {
        constants.downloadManager.cancelAllDownloads()
        sender.isEnabled = false
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
        if UIApplication.shared.applicationState == .active {
            setDescription()
        }
    }

    @IBAction func cancelDownloadButtonPressed(_ sender: UIButton) {
        constants.downloadManager.cancelAllDownloads()
        openButton.isEnabled = true
        self.progressBar.isHidden = true
        self.downloadProgressLabel.isHidden = true
        self.cancelButton.isHidden = true
        
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
        item.previewItemURL = locationToCopy!
        item.previewItemTitle = selectedModule.name
        return item
    }
}
