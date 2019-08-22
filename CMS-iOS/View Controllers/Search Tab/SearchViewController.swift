//
//  SearchViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 17/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import SwiftKeychainWrapper

class SearchViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    
    @IBOutlet weak var searchBar: UISearchBar!
    var searchValue : String = ""
    let constants = Constants.Global.self
    var resultArray = [Course]()
    var selectedCourse = Course()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        // Do any additional setup after loading the view.
    }
    
    func searchRequest (keyword: String, completion: @escaping() -> Void) {
        
        SVProgressHUD.show()
        let params : [String : Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "criteriavalue" : keyword, "page" : 1]
        let FINAL_URL : String = constants.BASE_URL + constants.SEARCH_COURSES
        
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: self.constants.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let searchResults = JSON(response.value)
                for i in 0 ..< searchResults["courses"].count {
                    let course = Course()
                    course.courseid = searchResults["courses"][i]["id"].int!
                    course.displayname = searchResults["courses"][i]["displayname"].string!
                    course.faculty = searchResults["courses"][i]["contacts"][0]["fullname"].string?.capitalized ?? ""
                    self.resultArray.append(course)
                }
            }
            completion()
        }
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            resultArray.removeAll()
            searchRequest(keyword: searchBar.text!) {
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    searchBar.resignFirstResponder()
                }
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            resultArray.removeAll()
            tableView.reloadData()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseCell")
        cell.textLabel?.text = resultArray[indexPath.row].displayname
        cell.detailTextLabel?.text = resultArray[indexPath.row].faculty
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.selectedCourse = resultArray[indexPath.row]
        performSegue(withIdentifier: "goToEnrolment", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultArray.count
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEnrolment" {
            let destinationVC = segue.destination as! EnrolmentViewController
            destinationVC.enrolmentCourse = self.selectedCourse
        }
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
