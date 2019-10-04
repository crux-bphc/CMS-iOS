//
//  ExtrasTableViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 20/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftKeychainWrapper
class ExtrasTableViewController: UITableViewController {
    
    let categoriesArray : [String] = ["Website", "About", "Logout"]
    let constants = Constants.Global.self
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
    }
    
    func setupNavBar() {
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    func logout(){
        let realm = try! Realm()
        
        try! realm.write {
            realm.deleteAll()
            
        }
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseCell", for: indexPath)
        cell.textLabel?.text = categoriesArray[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            UIApplication.shared.open(URL(string: constants.BASE_URL)!, options: [:], completionHandler: nil)
            break
        case 1:
            performSegue(withIdentifier: "showAboutPage", sender: self)
            break
        case 2:
            tabBarController?.dismiss(animated: true, completion: nil)
            logout()
            
            break
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
