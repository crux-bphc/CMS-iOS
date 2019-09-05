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

class DashboardViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let constant = Constants.Global.self
    var courseList = [Course]()
    var userDetails = User()
    var selectedCourseId : Int = 0
    var selectedCourseName : String = ""
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        tableView.reloadData()
        print("loaded")
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CourseDetailsViewController
        destinationVC.currentCourse.courseid = selectedCourseId
        destinationVC.currentCourse.displayname = selectedCourseName
    }
    
    func getRegisteredCourses(completion: @escaping() -> Void) {
        let params = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "userid" : 4626] as [String : Any]
        print("The secret used was: " + KeychainWrapper.standard.string(forKey: "userPassword")!)
        let FINAL_URL : String = constant.BASE_URL + constant.GET_COURSES
        SVProgressHUD.show()
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON { (courseData) in
            if courseData.result.isSuccess {
                let courses = JSON(courseData.value as Any)
                self.courseList.removeAll()
                for i in 0 ..< courses.count{
                    let currentCourse = Course()
                    currentCourse.courseid = courses[i]["id"].int!
                    currentCourse.displayname = courses[i]["displayname"].string!
                    currentCourse.enrolled = true
                    self.courseList.append(currentCourse)
                }
            }
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
            completion()
        }
    }
    
    @objc func refreshData() {
        self.refreshControl.beginRefreshing()
        getRegisteredCourses {
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courseList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "reuseCell")
        cell.textLabel?.text = courseList[indexPath.row].displayname
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.selectedCourseId = courseList[indexPath.row].courseid
        self.selectedCourseName = courseList[indexPath.row].displayname
        performSegue(withIdentifier: "goToCourseContent", sender: self)
    }
}
