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
import SwiftKeychainWrapper
import GradientLoadingBar

class SearchViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate , UISearchResultsUpdating{
    
    let constants = Constants.Global.self
    var resultArray = [Course]()
    var selectedCourse = Course()
    let searchController = UISearchController(searchResultsController: nil)
    private let gradientLoadingBar = GradientActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.contentInset.top = 16
        setupNavBar()
        setupGradientLoadingBar()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        gradientLoadingBar.fadeOut()
    }
    
    func setupNavBar() {
        
        self.navigationItem.searchController = searchController
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    
    func searchRequest (keyword: String, completion: @escaping() -> Void) {
        print("Made request to search for courses.")
        gradientLoadingBar.fadeIn()
        let params : [String : Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "criteriavalue" : keyword, "page" : 1]
        let FINAL_URL : String = constants.BASE_URL + constants.SEARCH_COURSES
        let queue = DispatchQueue.global(qos: .userInteractive)
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: self.constants.headers).responseJSON(queue : queue) { (response) in
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
            DispatchQueue.main.async {
                completion()
            }
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
                DispatchQueue.main.async {
                    self.gradientLoadingBar.fadeOut()
                    self.searchController.resignFirstResponder()
                    self.searchController.searchBar.endEditing(true)
                }
            }
        }
    }
    
//    code for real time search results
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        stopTheDamnRequests()
//        if searchController.searchBar.text != "" {
//            resultArray.removeAll()
//            searchRequest(keyword: searchController.searchBar.text!) {
//                self.tableView.reloadData()
//                DispatchQueue.main.async {
//                    self.searchController.resignFirstResponder()
//                    //                    self.tableView.scrollToRow(at: NSIndexPath(row: 0, section: 0) as IndexPath, at: .top, animated: false)
//                }
//            }
//        }
//    }

    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseCell")
        if resultArray.count > indexPath.row {
            cell.textLabel?.text = resultArray[indexPath.row].displayname.cleanUp()
            cell.detailTextLabel?.text = resultArray[indexPath.row].faculty
            return cell
        }
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
    
    func setupGradientLoadingBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        
        gradientLoadingBar.fadeOut(duration: 0)
        
        gradientLoadingBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.addSubview(gradientLoadingBar)
        
        NSLayoutConstraint.activate([
            gradientLoadingBar.leadingAnchor.constraint(equalTo: navigationBar.leadingAnchor),
            gradientLoadingBar.trailingAnchor.constraint(equalTo: navigationBar.trailingAnchor),
            
            gradientLoadingBar.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            gradientLoadingBar.heightAnchor.constraint(equalToConstant: 3.0)
        ])
    }
    func stopTheDamnRequests() {
        if #available(iOS 9.0, *) {
            Alamofire.SessionManager.default.session.getAllTasks { (tasks) in
                tasks.forEach{ $0.cancel() }
            }
        } else {
            Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
                sessionDataTask.forEach { $0.cancel() }
                uploadData.forEach { $0.cancel() }
                downloadData.forEach { $0.cancel() }
            }
        }
    }
}
