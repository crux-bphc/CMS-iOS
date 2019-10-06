//
//  DashboardViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 11/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import SVProgressHUD
import SwiftKeychainWrapper
import RealmSwift

class DashboardViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var tableView: UITableView!
    
    let constant = Constants.Global.self
    var courseList = [Course]()
    var userDetails = User()
    var selectedCourseId : Int = 0
    var selectedCourseName : String = ""
    var searching : Bool = false
    let refreshControl = UIRefreshControl()
    var filteredCourseList = [Course]()
    let realm = try! Realm()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = realm.objects(User.self).first
        userDetails = currentUser!
        
        setupNavBar()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if #available(iOS 13.0, *) {
            refreshControl.tintColor = .label
        } else {
            // Fallback on earlier versions
            refreshControl.tintColor = .black

        }
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        tableView.refreshControl = refreshControl
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if courseList.isEmpty {
            getRegisteredCourses {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !searchController.isActive{
            getRegisteredCourses {
            }
        }
        
        tableView.reloadData()

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CourseDetailsViewController
        
        destinationVC.currentCourse.courseid = selectedCourseId
        destinationVC.currentCourse.displayname = selectedCourseName
    }
    
    func setupNavBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.searchController = self.searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }
    
    func filterCoursesForSearch(string: String) {
        
        filteredCourseList = courseList.filter(){$0.displayname.contains(string.uppercased())}
        self.tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        self.filterCoursesForSearch(string: searchController.searchBar.text!)
    }
    
    func getRegisteredCourses(completion: @escaping() -> Void) {
        
        let realmCourses = self.realm.objects(Course.self)
        print("The device connection is: \(self.userDetails.isConnected)")
        if self.userDetails.isConnected{
            
            let params = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "userid" : userDetails.userid] as [String : Any]
            print("The secret used was: " + KeychainWrapper.standard.string(forKey: "userPassword")!)
            let FINAL_URL : String = constant.BASE_URL + constant.GET_COURSES
            SVProgressHUD.show()
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON { (courseData) in
                if courseData.result.isSuccess {
                    if (realmCourses.count != 0){
                        try! self.realm.write {
                            self.realm.delete(realmCourses)
                        }
                    }
                    
                    let courses = JSON(courseData.value as Any)
                    self.courseList.removeAll()
                    print("number of courses = \(courses.count)")
                    for i in 0 ..< courses.count{
                        let currentCourse = Course()
                        currentCourse.courseid = courses[i]["id"].int!
                        currentCourse.displayname = courses[i]["displayname"].string!
                        currentCourse.enrolled = true
                        self.courseList.append(currentCourse)
                        
                        try! self.realm.write {
                            self.realm.add(self.courseList[i])
                        }
                    }
                }
            }
        }
        else {
            courseList.removeAll()
            for x in 0..<realmCourses.count{
                courseList.append(realmCourses[x])
            }
            print(courseList.count)
        }
        self.tableView.reloadData()
        SVProgressHUD.dismiss()
        completion()
    }
    
    @objc func refreshData() {
        if !searchController.isActive {
            self.refreshControl.beginRefreshing()
            getRegisteredCourses {
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            }
        }else{
            self.refreshControl.endRefreshing()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredCourseList.count : courseList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseCell")
        
        if searchController.isActive {
            cell.textLabel?.text = filteredCourseList[indexPath.row].displayname
            cell.detailTextLabel?.text = filteredCourseList[indexPath.row].faculty
            
        }
        else {
            cell.textLabel?.text = courseList[indexPath.row].displayname
            cell.detailTextLabel?.text = courseList[indexPath.row].faculty
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if searchController.isActive {
            self.selectedCourseId = filteredCourseList[indexPath.row].courseid
            self.selectedCourseName = filteredCourseList[indexPath.row].displayname
        }
        else {
            self.selectedCourseId = courseList[indexPath.row].courseid
            self.selectedCourseName = courseList[indexPath.row].displayname
        }
        performSegue(withIdentifier: "goToCourseContent", sender: self)
    }
}
