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

class DashboardViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating, UIGestureRecognizerDelegate {
    
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
        tableView.register(UINib(nibName: "CourseTableViewCell", bundle: nil), forCellReuseIdentifier: "CourseTableViewCell")
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delegate = self
        self.tableView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if courseList.isEmpty {
            refreshData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //        if !searchController.isActive{
        //            refreshData()
        //        }
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        refreshControl.endRefreshing()
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
    
    @objc func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
        let pressLocation = longPressGesture.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: pressLocation)
        if indexPath == nil {
            print("Tap on the row, not the tableview.")
        } else if longPressGesture.state == UIGestureRecognizer.State.began {
            var actionSheet = UIAlertController()
            if searchController.isActive{
                if let rowNo = indexPath?.row{
                    actionSheet = UIAlertController(title: filteredCourseList[rowNo].displayname, message: nil, preferredStyle: .actionSheet)
                }
            }else{
                if let rowNo = indexPath?.row{
                    actionSheet = UIAlertController(title: courseList[rowNo].displayname, message: nil, preferredStyle: .actionSheet)
                }
            }
            let downloadAction = UIAlertAction(title: "Download Course", style: .default) { (action) in
                print("Download Button Clicked for cell at \(indexPath ?? [69,69])")
                var courseToDownload = Course()
                if let rowNo = indexPath?.row{
                    courseToDownload = self.searchController.isActive ? self.filteredCourseList[rowNo] : self.courseList[rowNo]
                    //                    downloadCourse(courseToDownload)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(downloadAction)
            actionSheet.addAction(cancelAction)
            present(actionSheet, animated: true, completion: nil)
        }
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
                        currentCourse.progress = 0.01 * Float(courses[i]["progress"].int ?? 0)
                        //                        print("The progress of the course is: \(currentCourse.progress)")
                        self.courseList.append(currentCourse)
                        
                        try! self.realm.write {
                            self.realm.add(self.courseList[i])
                        }
                    }
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        SVProgressHUD.dismiss()
                    }
                }
            }
        }else{
            courseList.removeAll()
            for x in 0..<realmCourses.count{
                courseList.append(realmCourses[x])
            }
            print(courseList.count)
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseTableViewCell", for: indexPath) as! CourseTableViewCell
        
        if searchController.isActive {
            
            cell.courseName.text = filteredCourseList[indexPath.row].displayname
            cell.courseProgress.progress = Float(filteredCourseList[indexPath.row].progress)
            
        } else {
            cell.courseName.text = courseList[indexPath.row].displayname
            cell.courseProgress.progress = Float(courseList[indexPath.row].progress)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath)
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
