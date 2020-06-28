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
    
    fileprivate let cellId = "ExtrasCell"
    let items = [["T.D. Website"], ["Profile", "Logout"], ["About", "Report Bug", "Rate"]]
    let constants = Constants.Global.self
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        let item = items[indexPath.section][indexPath.row]
        cell.textLabel?.text = item
        if item == "Logout" {
            cell.textLabel?.textColor = .systemRed
        } else {
            cell.accessoryType = .disclosureIndicator
            cell.imageView?.image = UIImage(named: item)
        }
        return cell

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
            switch indexPath.row {
            case 0:
                // profile go to profile page
                break
            case 1:
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
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        tableView.reloadData()
    }
}

// MARK: - User functions

extension ExtrasTableViewController {
    
    func logout() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
    }
    
    func setupNavBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }
}
