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
import UserNotifications

class DashboardViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchResultsUpdating, UIGestureRecognizerDelegate, URLSessionDownloadDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    let constant = Constants.Global.self
    var courseList = [Course]()
    var userDetails = User()
    var selectedCourse = Course()
    var searching : Bool = false
    let refreshControl = UIRefreshControl()
    var filteredCourseList = [Course]()
    let realm = try! Realm()
    let searchController = UISearchController(searchResultsController: nil)
    var locationToCopy = URL(string: "")
    var downloadArray : [URL] = []
    var localURLArray : [URL] = []
    
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
        destinationVC.currentCourse = selectedCourse
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
                
                if Reachability.isConnectedToNetwork() {
                    
                    var courseToDownload = Course()
                    if let rowNo = indexPath?.row{
                        courseToDownload = self.searchController.isActive ? self.filteredCourseList[rowNo] : self.courseList[rowNo]
                        self.downloadCourseData(course: courseToDownload) {
                            self.download(downloadArray: self.downloadArray, to: self.localURLArray) {
//                                print("completion inside didPressButton called")
//                                let state = UIApplication.shared.applicationState
//                                if state == .active {
//                                    SVProgressHUD.showSuccess(withStatus: "Downloaded course contents")
//                                    SVProgressHUD.dismiss(withDelay: 0.5)
//                                } else if state == .background || state == .inactive {
//                                    let content = UNMutableNotificationContent()
//                                    content.title = "Download Successful"
//                                    content.body = "The course \(actionSheet.title ?? "") was successfully downloaded.)"
//                                    content.sound = UNNotificationSound.default
//                                    content.badge = 1
//                                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//                                    let request = UNNotificationRequest(identifier: "DownloadCompelte", content: content, trigger: trigger)
//                                    let center = UNUserNotificationCenter.current()
//                                    center.add(request) { (error) in
//                                        print("There was an error in sending the notification. \(String(describing: error))")
//                                    }
//                                }
                            }
                        }
                    }
                } else {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    let alert = UIAlertController(title: "Unable to download", message: "The course cannot be downloaded as the device is offline.", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true)
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
    
    func downloadCourseData(course: Course, completion: @escaping() -> Void) {
        
        let params : [String:String] = ["courseid": String(course.courseid), "wstoken": KeychainWrapper.standard.string(forKey: "userPassword")!]
        
        Alamofire.request((constant.BASE_URL + constant.GET_COURSE_CONTENT), method: .get, parameters: params, headers: constant.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let courseData = JSON(response.value as Any)
                for i in 0 ..< courseData.count {
                    for j in 0 ..< courseData[i]["modules"].count {
                        if courseData[i]["modules"][j]["modname"].string! == "resource" {
                            let downloadUrl = courseData[i]["modules"][j]["contents"][0]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                            let moduleToDownload = Module()
                            moduleToDownload.coursename = course.displayname
                            moduleToDownload.id = courseData[i]["modules"][j]["id"].int!
                            moduleToDownload.filename = courseData[i]["modules"][j]["contents"][0]["filename"].string!
                            self.saveFileToStorage(mime: courseData[i]["modules"][j]["contents"][0]["mimetype"].string!, downloadUrl: downloadUrl, module: moduleToDownload)
                        } else if courseData[i]["modules"][j]["modname"].string! == "folder" {
                            for u in 0 ..< courseData[i]["modules"][j]["contents"].count {
                                let moduleToDownload = Module()
                                let downloadUrl = courseData[i]["modules"][j]["contents"][u]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                moduleToDownload.coursename = course.displayname
                                moduleToDownload.id = u
                                moduleToDownload.filename = courseData[i]["modules"][j]["contents"][u]["filename"].string!
                                self.saveFileToStorage(mime: courseData[i]["modules"][j]["contents"][u]["mimetype"].string!, downloadUrl: downloadUrl, module: moduleToDownload)
                            }
                        }
                    }
                }
            }
            self.download(downloadArray: self.downloadArray, to: self.localURLArray) {
            }
        }
        completion()
    }
    
    func download(downloadArray: [URL], to localUrl: [URL], completion: @escaping() -> Void) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        for k in 0 ..< downloadArray.count {
            locationToCopy = localUrl[k]
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
            
            let operation = DownloadOperation(session: session, downloadTaskURL: downloadArray[k]) { (localURL, response, error) in
                do {
                    try FileManager.default.copyItem(at: localURL!, to: self.localURLArray[k])
                } catch {
                    print("There was an error in copying the item")
                }
            }
            queue.addOperation(operation)
        }
    }
    
    func saveFileToStorage(mime: String, downloadUrl: String, module: Module) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        //        print(String(describing: documentsDirectory))
        let dataPath = documentsDirectory.absoluteURL
        
        guard let url = URL(string: downloadUrl) else { return }
        var destination1 : URL = dataPath
        var isDir : ObjCBool = false
        if FileManager.default.fileExists(atPath: dataPath.appendingPathComponent(module.coursename).path, isDirectory: &isDir) {
            if isDir.boolValue  {
                //                Directory exists
                destination1 = dataPath.appendingPathComponent(module.coursename)
            } else {
                do {
                    try FileManager.default.createDirectory(atPath: dataPath.appendingPathComponent(module.coursename).path, withIntermediateDirectories: true, attributes: nil)
                    destination1 = dataPath.appendingPathComponent(module.coursename)
                } catch {
                    print("There was an error in making the directory at path: \(dataPath.appendingPathComponent(module.coursename))")
                }
            }
        } else {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.appendingPathComponent(module.coursename).path, withIntermediateDirectories: true, attributes: nil)
                destination1 = dataPath.appendingPathComponent(module.coursename)
            } catch {
                print("There was an error in making the directory at path: \(dataPath.appendingPathComponent(module.coursename))")
            }
        }
        
        let destination = destination1.appendingPathComponent("\(String(module.id) + module.filename)")
        downloadArray.append(url)
        localURLArray.append(destination)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.copyItem(at: location, to: locationToCopy!)
        } catch (let writeError){
            print("there was an error: \(writeError)")
        }
    }
    
    func getRegisteredCourses(completion: @escaping() -> Void) {
        
        let realmCourses = self.realm.objects(Course.self)
        print("The device connection is: \(self.userDetails.isConnected)")
        if self.userDetails.isConnected{
            
            let params = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "userid" : userDetails.userid] as [String : Any]
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
                    for i in 0 ..< courses.count{
                        let currentCourse = Course()
                        currentCourse.courseid = courses[i]["id"].int!
                        currentCourse.displayname = courses[i]["displayname"].string!
                        currentCourse.enrolled = true
                        currentCourse.progress = 0.01 * Float(courses[i]["progress"].int ?? 0)
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return searchController.isActive ? filteredCourseList.count : courseList.count
    }
    
    /*
     old code
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredCourseList.count : courseList.count
    }
    */
    
    //making sure there is 1 row per section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    //row padding
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseTableViewCell", for: indexPath) as! CourseTableViewCell
        
        if searchController.isActive {
            
            cell.courseName.text = filteredCourseList[indexPath.section].displayname
            cell.courseProgress.progress = Float(filteredCourseList[indexPath.section].progress)
            
        } else {
            cell.courseName.text = courseList[indexPath.section].displayname
            cell.courseProgress.progress = Float(courseList[indexPath.section].progress)
        }
        
        //changing cell appearence
        
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 0.25
        cell.layer.cornerRadius = 20
        cell.clipsToBounds = true
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        if searchController.isActive {
            self.selectedCourse = filteredCourseList[indexPath.row]
        }
        else {
            self.selectedCourse = courseList[indexPath.row]
        }
        performSegue(withIdentifier: "goToCourseContent", sender: self)
    }
}
