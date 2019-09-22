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

class SearchViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate , UISearchResultsUpdating{
    
    @IBOutlet weak var searchBar: UISearchBar!
    var searchValue : String = ""
    let constants = Constants.Global.self
    var resultArray = [Course]()
    var selectedCourse = Course()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        searchBar.delegate = self
//        searchBar.isHidden = true
        setupNavBar()
        // Do any additional setup after loading the view.
    }
    
    func setupNavBar() {
        
        self.navigationItem.searchController = searchController
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
    }
    
    func searchRequest (keyword: String, completion: @escaping() -> Void) {
        print("Made request to search for courses.")
        SVProgressHUD.show()
        let params : [String : Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "criteriavalue" : keyword, "page" : 1]
        let FINAL_URL : String = constants.BASE_URL + constants.SEARCH_COURSES
        
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: self.constants.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let searchResults = JSON(response.value as Any)
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
    
    func updateSearchResults(for searchController: UISearchController) {

    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resultArray.removeAll()
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchController.searchBar.text != "" {
            resultArray.removeAll()
            searchRequest(keyword: searchController.searchBar.text!) {
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
                DispatchQueue.main.async {
                    self.searchController.resignFirstResponder()
                    self.searchController.searchBar.endEditing(true)
                }
            }
        }
    }
    
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        if searchBar.text?.count == 0 {
//            resultArray.removeAll()
//            tableView.reloadData()
//            DispatchQueue.main.async {
//                searchBar.resignFirstResponder()
//            }
//        }
//    }
    
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
        
        return (self.searchController.isActive ? resultArray.count : 0)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEnrolment" {
            let destinationVC = segue.destination as! EnrolmentViewController
            destinationVC.enrolmentCourse = self.selectedCourse
        }
    }
}
