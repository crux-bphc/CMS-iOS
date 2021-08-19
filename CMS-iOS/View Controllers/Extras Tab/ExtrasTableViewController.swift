//
//  ExtrasTableViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 20/08/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftKeychainWrapper
import QuickLook

class ExtrasTableViewController: UITableViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate, QLPreviewControllerDataSource {
    
    let realm = try! Realm()
    let ql = QLPreviewController()
    let defaults = UserDefaults.standard
    
    fileprivate let cellId = "ExtrasCell"
    let pickerController = UIImagePickerController()
    let items = [["CMS Website"], ["My Timetable"], ["About", "Report Bug", "Rate"], ["Logout"]]
    let constants = Constants.Global.self
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerController.delegate = self
        pickerController.allowsEditing = false
        pickerController.mediaTypes = ["public.image"]
        pickerController.sourceType = .photoLibrary
        ql.dataSource = self
        
        setupNavBar()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
    }
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        if #available(iOS 13.0, *) {
            cell.textLabel?.textColor = .label
        } else {
            // Fallback on earlier versions
            cell.textLabel?.textColor = .black
        }
        
        let item = items[indexPath.section][indexPath.row]
        cell.textLabel?.text = item
        if item == "Logout" {
            cell.textLabel?.textColor = .systemRed
            cell.imageView?.image = nil
        } else if item == "My Timetable" {
            cell.accessoryType = .detailButton
            cell.imageView?.image = UIImage(named: "Timetable")
        }
        else {
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.image = UIImage(named: item)
        }
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if indexPath.section == 1 {
            let warning = UIAlertController()
            let changeImage = UIAlertAction(title: "Update Timetable Image", style: .default) { (action) in
                self.present(self.pickerController, animated: true, completion: nil)
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            warning.addAction(changeImage)
            warning.addAction(cancel)
            self.present(warning, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                // T.D. Website
                UIApplication.shared.open(URL(string: constants.BASE_URL)!, options: [:], completionHandler: nil)
                break
            default:
                break
            }
            break
        case 1:
            if defaults.string(forKey: "timetableURL") != "" {
                self.present(ql, animated: true, completion: nil)
                
            } else {
                present(pickerController, animated: true, completion: nil)
            }
            break
        case 2:
            switch indexPath.row {
            case 0:
                // about page
                performSegue(withIdentifier: "showAboutPage", sender: self)
                break
            case 1:
                // bug report
                UIApplication.shared.open(URL(string: constants.GITHUB_URL)!, options: [:], completionHandler: nil)
                break
            case 2:
                // rate
                if let url = URL(string: "itms-apps://itunes.apple.com/app/\(constants.APP_ID)"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    
                }
                break
            default:
                break
            }
            break
        case 3:
            switch indexPath.row {
            case 0:
                // logout
                let warning = UIAlertController(title: "Confirmation", message: "Are you sure you want to log out?", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                warning.addAction(cancelAction)
                let logOutAction = UIAlertAction(title: "Yes", style: .destructive) { (_) in
                    self.logout()
                    self.tabBarController?.dismiss(animated: true, completion: nil)
                    
                }
                warning.addAction(logOutAction)
                self.present(warning, animated: true, completion: nil)
                break
            default:
                break
            }
            break
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Website", "Timetable", "App", ""][section]
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        tableView.reloadData()
    }
}


// MARK: - ImagePicker Delegate Functions

extension ExtrasTableViewController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let imagePath = documentsPath!.appendingPathComponent("image.jpg")
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            let imageData = pickedImage.jpegData(compressionQuality: 1.00)
            try! imageData?.write(to: imagePath)

            pickerController.dismiss(animated: true) {
                self.defaults.set(imagePath.absoluteString, forKey: "timetableURL")
            }
        }
    }
}

// MARK: - Quick Look Functions

extension ExtrasTableViewController {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let item = PreviewItem()
        let fileManager = FileManager()
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let imagePath = documentsPath!.appendingPathComponent("image.jpg")
        
        item.previewItemURL = imagePath
        item.previewItemTitle = "Timetable"
        return item
    }
    
    
}

// MARK: - User functions

extension ExtrasTableViewController {
    
    func logout() {
        //        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        SpotlightIndex.shared.deindexAllItems()
        let wstoken = KeychainWrapper.standard.string(forKey: "userPassword") ?? ""
        NotificationManager.shared.deregisterDevice(wstoken: wstoken) {
            
        }
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "MoodleSession")
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "privateToken")
        
        UserDefaults.standard.removeObject(forKey: "sessionTimestamp")
    }
    
    func setupNavBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @objc func switchChanged(_ sender : UISwitch!){
        defaults.setValue(sender.isOn, forKey: "hidesSemester")
    }
    
}

