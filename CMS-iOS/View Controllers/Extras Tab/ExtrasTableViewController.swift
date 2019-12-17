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
    let colorArray : [UIColor] = [UIColor.systemBlue, UIColor.systemPurple, UIColor.systemRed]
    let iconsArray : [UIImage] = [#imageLiteral(resourceName: "website"), #imageLiteral(resourceName: "info"), #imageLiteral(resourceName: "logout")]
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "ExtrasTableViewCell", bundle: nil), forCellReuseIdentifier: "ExtraTableViewCell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExtraTableViewCell", for: indexPath) as! ExtrasTableViewCell
        cell.optionLabel.text = categoriesArray[indexPath.row]
        cell.colorView.backgroundColor = colorArray[indexPath.row]
        cell.iconImage.image = iconsArray[indexPath.row]
        return cell

    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        tableView.reloadData()
    }
}
