//
//  FolderContentViewController.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 9/13/19.
//  Copyright © 2019 Crux BPHC. All rights reserved.
//

import UIKit
import RealmSwift

class FolderContentViewController: UITableViewController {
    
    var currentModule = Module()
    var currentModuleContents = [Module]()
    var folderSelectedModule = Module()
    override func viewDidLoad() {
        super.viewDidLoad()
        print(currentModule)
        navigationItem.largeTitleDisplayMode = .never
        self.title = currentModule.name
        let realm = try! Realm()
        try! realm.write{
            self.currentModule.read = true
        }
        for i in 0..<currentModule.fileModules.count {
            currentModuleContents.append(currentModule.fileModules[i])
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return currentModuleContents.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseCell", for: indexPath)
        cell.textLabel?.text = currentModuleContents[indexPath.row].filename
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.absoluteURL.appendingPathComponent(currentModule.coursename)
        let destination = dataPath.appendingPathComponent("\(String(currentModuleContents[indexPath.row].id) + currentModuleContents[indexPath.row].filename)")
        if FileManager().fileExists(atPath: destination.path) {
            // module has already been downloaded
            cell.textLabel?.textColor = .systemGreen
        }
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                changeImage(mode: "_dark", cell: cell, module: currentModuleContents, indexPath: indexPath)
            } else {
                changeImage(mode: "", cell: cell, module: currentModuleContents, indexPath: indexPath)
            }
        } else {
            changeImage(mode: "", cell: cell, module: currentModuleContents, indexPath: indexPath)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        folderSelectedModule = currentModuleContents[indexPath.row]
        let realm = try! Realm()
        try! realm.write {
            currentModuleContents[indexPath.row].read = true
        }
        performSegue(withIdentifier: "goToFolderModule", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! ModuleViewController
        let realm = try! Realm()
        try! realm.write {
            folderSelectedModule.modname = "resource"
            
        }
        destinationVC.selectedModule = folderSelectedModule
    }
    
    func changeImage(mode: String, cell: UITableViewCell, module: [Module], indexPath: IndexPath) {
        switch module[indexPath.row].mimetype {
        case "application/pdf":
            cell.imageView?.image = UIImage(named: "pdf\(mode)")
            break
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
            cell.imageView?.image = UIImage(named: "doc\(mode)")
            break
        case "text/plain":
            cell.imageView?.image = UIImage(named: "txt\(mode)")
            break
        case "image/jpeg":
            cell.imageView?.image = UIImage(named: "img\(mode)")
            break
        case "image/png":
            cell.imageView?.image = UIImage(named: "img\(mode)")
            break
        case "application/vnd.ms-excel":
            cell.imageView?.image = UIImage(named: "xls\(mode)")
            break
        case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
            cell.imageView?.image = UIImage(named: "xls\(mode)")
            break
        case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
            cell.imageView?.image = UIImage(named: "ppt\(mode)")
            break
        case "application/zip":
            cell.imageView?.image = UIImage(named: "zip\(mode)")
            break
        case "application/x-rar-compressed":
            cell.imageView?.image = UIImage(named: "zip\(mode)")
            break
        default:
            cell.imageView?.image = UIImage(named: "raw\(mode)")
            break
        }
    }
    
}
