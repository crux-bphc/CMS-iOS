//
//  SidebarController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 15/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit

class SidebarController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let sections : [String] = ["Moodle", "Communicate", "Help"]
    let moodle : [String] = ["My Courses", "Site News", "Search Courses", "Website"]
    let communicate : [String] = ["Share", "Feedback"]
    let help : [String] = ["About", "Logout"]
    let constant = Constants.Global.self
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.isHidden = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.frame.size.width = self.view.frame.width - 69
        tableView.frame.size.height = self.view.frame.height - 147
        tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor )
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var row = 0
        switch section {
        case 0:
            row = moodle.count
            break
        case 1:
            row = communicate.count
            break
        case 2:
            row = help.count
            break
        default:
            break
        }
        return row
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "reuseCell")
//        cell.textLabel?.text = options[indexPath.row]
        switch indexPath.section {
        case 0:
           cell.textLabel?.text = moodle[indexPath.row]
            break
        case 1:
            cell.textLabel?.text = communicate[indexPath.row]
            break
        case 2:
            cell.textLabel?.text = help[indexPath.row]
            break
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                self.sideMenuController?.hideMenu(animated: true, completion: nil)
//            case 1:
//                performSegue(withIdentifier: <#String#>, sender: <#T##Any?#>)
//            case 2:
//                performSegue(withIdentifier: <#T##String#>, sender: <#T##Any?#>)
            case 3:
                UIApplication.shared.open(URL(string: self.constant.BASE_URL)!, options: [:], completionHandler: nil)
                break
            default:
                break
            }
//        case 1:
//            switch indexPath.row {
//            case 0:
//                performSegue(withIdentifier: <#T##String#>, sender: <#T##Any?#>)
//            case 1:
//                performSegue(withIdentifier: <#String#>, sender: <#T##Any?#>)
//            default:
//                <#code#>
//            }
        case 2:
            switch indexPath.row {
            case 0:
                performSegue(withIdentifier: "goToAbout", sender: self)
            case 1:
                sideMenuController?.dismiss(animated: true, completion: nil)
            default:
                break
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    

    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
