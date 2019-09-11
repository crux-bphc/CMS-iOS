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
    var filteredCourseList = [Course]()
    var userDetails = User()
    var selectedCourseId : Int = 0
    var selectedCourseName : String = ""
    let refreshControl = UIRefreshControl()
    var searching : Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        
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
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton{
            cancelButton.isEnabled = true
        }
        getRegisteredCourses {
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CourseDetailsViewController
        destinationVC.currentCourse.courseid = selectedCourseId
        destinationVC.currentCourse.displayname = selectedCourseName
    }
    
    func getRegisteredCourses(completion: @escaping() -> Void) {
        
        
        
        let realm = try! Realm()
        let realmCourses = realm.objects(Course.self)
        
        
        if Reachability.isConnectedToNetwork(){
            
            
            
            
            
            
            
            
            
            let params = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "userid" : userDetails.userid] as [String : Any]
            print("The secret used was: " + KeychainWrapper.standard.string(forKey: "userPassword")!)
            let FINAL_URL : String = constant.BASE_URL + constant.GET_COURSES
            SVProgressHUD.show()
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON { (courseData) in
                if courseData.result.isSuccess {
                    
                    
                    if (realmCourses.count != 0){
                        try! realm.write {
                            realm.delete(realmCourses)
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
                        
                        
                        
                        try! realm.write {
                            realm.add(self.courseList[i])
                        }
                        
                        
                        
                        
                    }
                    
                    
                    
                }
                
            }
            
            
        }else{
            print("OFFLINE")
            
            //            let alert = UIAlertController(title: "Offline", message: "You are not connected to the internet, courses displayed may not be updated.", preferredStyle: .alert)
            //            let action = UIAlertAction(title: "Ok", style: .default) { (_) in
            //                self.refreshControl.endRefreshing()
            //
            //            }
            //
            //            alert.addAction(action)
            //            self.present(alert, animated: true)
            
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
        if searching{
            cell.textLabel?.text = filteredCourseList[indexPath.row].displayname
        }else{
            cell.textLabel?.text = courseList[indexPath.row].displayname
            
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.endEditing(true)
        
        self.selectedCourseId = courseList[indexPath.row].courseid
        self.selectedCourseName = courseList[indexPath.row].displayname
        performSegue(withIdentifier: "goToCourseContent", sender: self)
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == ""{
            searching = false
        }else{
            searching = true
            
            
            filteredCourseList = courseList.filter(){$0.displayname.contains(searchText.uppercased())}
            
        }
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searching = false
        tableView.reloadData()
        searchBar.setShowsCancelButton(false, animated: true)
        
        searchBar.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        if let cancelButton = searchBar.value(forKey: "cancelButton") as? UIButton{
            cancelButton.isEnabled = true
        }
    }
}
