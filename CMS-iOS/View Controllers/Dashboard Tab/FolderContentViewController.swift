//
//  FolderContentViewController.swift
//  CMS-iOS
//
//  Created by Aryan Chaubal on 9/13/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import RealmSwift

class FolderContentViewController: UITableViewController {
    
    var currentModule = Module()
    var currentModuleContents = [Module]()
    var folderSelectedModule = Module()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = currentModule.name
        
        for i in 0..<currentModule.fileModules.count {
            currentModuleContents.append(currentModule.fileModules[i])
        }
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
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        folderSelectedModule = currentModuleContents[indexPath.row]
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
}
