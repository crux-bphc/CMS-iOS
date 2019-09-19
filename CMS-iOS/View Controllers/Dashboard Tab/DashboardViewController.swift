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

class DashboardViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let constant = Constants.Global.self
    var courseList = [Course]()
    var userDetails = User()
    var selectedCourseId : Int = 0
    var selectedCourseName : String = ""
    var searching : Bool = false
    let refreshControl = UIRefreshControl()
    var filteredCourseList = [Course]()
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = realm.objects(User.self).first
        userDetails = currentUser!
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        tableView.refreshControl = refreshControl
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if courseList.isEmpty {
            getRegisteredCourses {
                self.refreshControl.endRefreshing()
            }
        }
        welcomeLabel.text = "Welcome, \(userDetails.name)"
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        SVProgressHUD.dismiss()
        if !searching{
            getRegisteredCourses {
            }
        }
        
        tableView.reloadData()

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CourseDetailsViewController
        
        destinationVC.currentCourse.courseid = selectedCourseId
        destinationVC.currentCourse.displayname = selectedCourseName
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
        self.refreshControl.beginRefreshing()
        getRegisteredCourses {
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searching ? filteredCourseList.count : courseList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "reuseCell")
        
        
        if searching {
            cell.textLabel?.text = filteredCourseList[indexPath.row].displayname
            
        }
        else {
            cell.textLabel?.text = courseList[indexPath.row].displayname
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if searching {
            self.selectedCourseId = filteredCourseList[indexPath.row].courseid
            self.selectedCourseName = filteredCourseList[indexPath.row].displayname
        }
        else {
            self.selectedCourseId = courseList[indexPath.row].courseid
            self.selectedCourseName = courseList[indexPath.row].displayname
        }
        performSegue(withIdentifier: "goToCourseContent", sender: self)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searching = false
        searchBar.text = ""
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
        tableView.reloadData()
        
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searching = true
        filteredCourseList = courseList.filter(){$0.displayname.contains(searchText.uppercased())}
        
        if searchText == ""{
            searching = false
        }
        
        tableView.reloadData()
    }
}
