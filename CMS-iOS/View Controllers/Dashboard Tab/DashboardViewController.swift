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
import SwiftKeychainWrapper
import RealmSwift
import UserNotifications
import NotificationBannerSwift
import GradientLoadingBar

class DashboardViewController : UITableViewController, UISearchBarDelegate, UISearchResultsUpdating, UIGestureRecognizerDelegate {
    
    let banner = NotificationBanner(title: "Offline", subtitle: nil, style: .danger)
    let constant = Constants.Global.self
    var animated = false
    var courseList = [Course]()
    var tempRealmCount = 0
    var totalCourseCount = 0
    var userDetails = User()
    var selectedCourse = Course()
    var searching : Bool = false
    private let gradientLoadingBar = GradientActivityIndicatorView()
    var filteredCourseList = [Course]()
    let searchController = UISearchController(searchResultsController: nil)
    var downloadArray : [URL] = []
    var localURLArray : [URL] = []
    let sessionManager = Alamofire.SessionManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientLoadingBar()
        let realm = try! Realm()
        if let currentUser = realm.objects(User.self).first {
            userDetails = currentUser
        }
        
        setupNavBar()
        loadOfflineCourses()
        refreshData()
        
        if #available(iOS 13.0, *) {
            refreshControl?.tintColor = .label
        } else {
            // Fallback on earlier versions
            refreshControl?.tintColor = .black
            
        }
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        tableView.refreshControl = refreshControl
        tableView.reloadData()
        tableView.register(UINib(nibName: "CourseTableViewCell", bundle: nil), forCellReuseIdentifier: "CourseTableViewCell")
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delegate = self
        self.tableView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //        tableView.reloadData()
        UIApplication.shared.applicationIconBadgeNumber = 0
        if !animated{
            animateTable()
            self.animated = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //        refreshControl?.endRefreshing()
        gradientLoadingBar.fadeOut()
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
            let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
            selectionFeedbackGenerator.selectionChanged()
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
                        }
                    }
                } else {
                    self.showOfflineMessage()
                }
            }
            let markAllRead = UIAlertAction(title: "Mark Everything Read", style: .destructive) { (_) in
                let warning = UIAlertController(title: "Confirmation", message: "Are you sure you want to mark all modules and announcements as read?", preferredStyle: .actionSheet)
                let doItAction = UIAlertAction(title: "Yes", style: .destructive) { (_) in
                    DispatchQueue.global(qos: .userInteractive).async {
                        
                        let realm = try! Realm()
                        let allUnreadModules = realm.objects(Module.self).filter("read = NO")
                        while (allUnreadModules.count > 0) {
                            try! realm.write {
                                allUnreadModules[0].read = true
                            }
                        }
                        let allUnreadDiscussions = realm.objects(Discussion.self).filter("read = NO")
                        while (allUnreadDiscussions.count > 0) {
                            try! realm.write {
                                allUnreadDiscussions[0].read = true
                            }
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                warning.addAction(doItAction)
                warning.addAction(cancelAction)
                self.present(warning, animated: true, completion: nil)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(downloadAction)
            actionSheet.addAction(markAllRead)
            actionSheet.addAction(cancelAction)
            present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func filterCoursesForSearch(string: String) {
        
        filteredCourseList = courseList.filter() {$0.displayname.contains(string.uppercased())}
        self.tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        self.filterCoursesForSearch(string: searchController.searchBar.text!)
    }
    
    func downloadCourseData(course: Course, completion: @escaping() -> Void) {
        
        let params : [String:String] = ["courseid": String(course.courseid), "wstoken": KeychainWrapper.standard.string(forKey: "userPassword")!]
        
        Alamofire.request((constant.BASE_URL + constant.GET_COURSE_CONTENT), method: .get, parameters: params, headers: constant.headers).responseJSON { (response) in
            let realm = try! Realm()
            if response.result.isSuccess {
                let courseData = JSON(response.value as Any)
                try! realm.write {
                    realm.delete(realm.objects(CourseSection.self).filter("courseId = \(course.courseid)"))
                }
                for i in 0 ..< courseData.count {
                    let section = CourseSection()
                    section.name = courseData[i]["name"].string ?? ""
                    for j in 0 ..< courseData[i]["modules"].count {
                        let module = Module()
                        module.modname = courseData[i]["modules"][j]["modname"].string!
                        module.id = courseData[i]["modules"][j]["id"].int!
                        if courseData[i]["modules"][j]["modname"].string! == "resource" {
                            if (courseData[i]["modules"][j]["contents"][0]["fileurl"].string!).contains("td.bits-hyderabad.ac.in") {
                                module.fileurl = (courseData[i]["modules"][j]["contents"][0]["fileurl"].string! +
                                    "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)")
                                module.mimetype = courseData[i]["modules"][j]["contents"][0]["mimetype"].string!
                                module.filename = courseData[i]["modules"][j]["contents"][0]["filename"].string!
                            }
                            else {
                                module.fileurl = (courseData[i]["modules"][j]["contents"][0]["fileurl"].string!)
                            }
                            let downloadUrl = courseData[i]["modules"][j]["contents"][0]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                            let moduleToDownload = Module()
                            moduleToDownload.coursename = course.displayname
                            moduleToDownload.id = courseData[i]["modules"][j]["id"].int!
                            moduleToDownload.filename = courseData[i]["modules"][j]["contents"][0]["filename"].string!
                            self.saveFileToStorage(mime: courseData[i]["modules"][j]["contents"][0]["mimetype"].string!, downloadUrl: downloadUrl, module: moduleToDownload)
                        } else if courseData[i]["modules"][j]["modname"].string! == "folder" {
                            for u in 0 ..< courseData[i]["modules"][j]["contents"].count {
                                let newModule = Module()
                                newModule.filename = courseData[i]["modules"][j]["contents"][u]["filename"].string!
                                
                                if courseData[i]["modules"][j]["contents"][u]["fileurl"].string!.contains("td.bits-hyderabad.ac.in") {
                                    newModule.fileurl = courseData[i]["modules"][j]["contents"][u]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                }
                                newModule.mimetype = courseData[i]["modules"][j]["contents"][u]["mimetype"].string!
                                module.fileModules.append(newModule)
                                let moduleToDownload = Module()
                                let downloadUrl = courseData[i]["modules"][j]["contents"][u]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                moduleToDownload.coursename = course.displayname
                                moduleToDownload.id = u
                                moduleToDownload.filename = courseData[i]["modules"][j]["contents"][u]["filename"].string!
                                self.saveFileToStorage(mime: courseData[i]["modules"][j]["contents"][u]["mimetype"].string!, downloadUrl: downloadUrl, module: moduleToDownload)
                            }
                        }
                        section.key = String(course.courseid) + section.name
                        section.modules.append(module)
                        section.dateCreated = Date().timeIntervalSince1970
                    }
                    print("added to realm")
                    do {
                        try realm.write {
                            realm.add(section, update: .modified)
                        }
                    } catch let error{
                        print("There was an error writing to realm: \(error)")
                    }
                }
            }
            self.clearTempDirectory()
            self.downloadFiles(downloadArray: self.downloadArray, localURLArray: self.localURLArray, courseName: course.courseCode) {
                let successBanner = NotificationBanner(title: "Download Complete", subtitle: "All files from the course have been downloaded.", style: .success)
                successBanner.dismissOnSwipeUp = true
                successBanner.show()
            }
        }
        completion()
    }
    
    func downloadFiles(downloadArray: [URL], localURLArray: [URL], courseName: String, didFinishDownload: @escaping () -> Void) {
        for i in 0 ..< downloadArray.count {
            let request = URLRequest(url: downloadArray[i])
            constant.downloadManager.showLocalNotificationOnBackgroundDownloadDone = true
            constant.downloadManager.localNotificationText = "Files for \(courseName) downloaded."
            let downloadKey = constant.downloadManager.downloadFile(withRequest: request, shouldDownloadInBackground: true) { (error, localFileURL) in
                if error != nil {
                    print("There was an error while downloading the file. \(String(describing: error))")
                } else {
                    print("The file was downloaded to the location: \(String(describing: localFileURL))")
                    do {
                        try FileManager.default.copyItem(at: localFileURL!, to: localURLArray[i])
                    } catch (let writeError) {
                        print("there was an error in writing: \(writeError)")
                    }
                    do {
                        try FileManager.default.removeItem(at: localFileURL!)
                    } catch let removeError {
                        print("There was an error in removing: \(removeError)")
                    }
                }
                if i == downloadArray.count-1 {
                    didFinishDownload()
                }
            }
            print("The download key is: \(downloadKey ?? "")")
        }
    }
    
    func saveFileToStorage(mime: String, downloadUrl: String, module: Module) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
    
    func clearTempDirectory() {
        let fileManager = FileManager.default
        let cachesDirectory = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        do {
            try fileManager.removeItem(atPath: cachesDirectory)
        } catch let error {
            print("There was an error in deleting the caches directory: \(error)")
        }
    }
    
    func getRegisteredCourses() {
        
        if Reachability.isConnectedToNetwork() {
            let queue = DispatchQueue(label: "com.cruxbphc.getcoursetitles", qos: .userInteractive, attributes: .concurrent)
            let params = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "userid" : userDetails.userid] as [String : Any]
            let FINAL_URL : String = constant.BASE_URL + constant.GET_COURSES
            var coursesRef: ThreadSafeReference<Results<Course>>?
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON (queue: queue) { (courseData) in
                if courseData.result.isSuccess {
                    let bkgRealm = try! Realm()
                    var tempCourses : Results<Course>?
                    let realmCourses = bkgRealm.objects(Course.self)
                    if (realmCourses.count != 0) {
                        try! bkgRealm.write {
                            bkgRealm.delete(realmCourses)
                        }
                    }
                    
                    let courses = JSON(courseData.value as Any)
                    self.totalCourseCount = courses.count
                    self.courseList.removeAll()
                    if let _ = courses[0]["id"].int {
                        for i in 0 ..< courses.count{
                            let currentCourse = Course()
                            currentCourse.courseid = courses[i]["id"].int!
                            currentCourse.displayname = courses[i]["displayname"].string!
                            currentCourse.courseCode = Regex.match(pattern: "(..|...|....)\\s[A-Z][0-9][0-9][0-9]", text: currentCourse.displayname).first ?? ""
                            currentCourse.courseName = currentCourse.displayname.replacingOccurrences(of: "\(currentCourse.courseCode) ", with: "")
                            currentCourse.enrolled = true
                            try! bkgRealm.write {
                                //                            bkgRealm.add(currentCourse)
                                bkgRealm.add(currentCourse, update: .modified)
                            }
                            self.downloadDashboardCourseContents(courseName: currentCourse.displayname, courseId: currentCourse.courseid)
                        }
                        tempCourses = bkgRealm.objects(Course.self)
                        coursesRef = ThreadSafeReference(to: tempCourses!)
                        DispatchQueue.main.async {
                            let realm = try! Realm()
                            guard let coursesRef = coursesRef, let temp2 = realm.resolve(coursesRef) else {return}
                            for i in 0..<temp2.count{
                                self.courseList.append(temp2[i])
                                
                            }
                            
                            if #available(iOS 12.0, *) {
                                if self.traitCollection.userInterfaceStyle == .dark{
                                    // make this dark in the future
                                    //                                    self.setupColors(colors: DashboardCellColours().dark)
                                    self.setupColors(colors: DashboardCellColours().light)
                                }else{
                                    self.setupColors(colors: DashboardCellColours().light)
                                }
                            } else {
                                self.setupColors(colors: DashboardCellColours().light)
                            }
                            
                            self.tableView.reloadData()
                            
                        }
                    } else {
                        let alert = UIAlertController(title: "Error downloading data", message: "The site may be down or your token may have been updated. You will be logged out, try logging in again.", preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
                            self.logoutCurrentUser()
                            self.dismiss(animated: true, completion: nil)
                        }
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        } else{
            let realm = try! Realm()
            courseList = [Course]()
            let realmCourses = realm.objects(Course.self)
            for x in 0..<realmCourses.count{
                courseList.append(realmCourses[x])
            }
        }
    }
    
    func loadOfflineCourses() {
        let realm = try! Realm()
        let realmCourses = realm.objects(Course.self)
        if realmCourses.count != 0 {
            courseList.removeAll()
            for x in 0..<realmCourses.count{
                courseList.append(realmCourses[x])
            }
        }
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark{
                //                self.setupColors(colors: DashboardCellColours().dark)
                self.setupColors(colors: DashboardCellColours().light)
            }else{
                self.setupColors(colors: DashboardCellColours().light)
            }
        } else {
            self.setupColors(colors: DashboardCellColours().light)
        }
    }
    
    @objc func refreshData() {
        gradientLoadingBar.fadeIn()
        if !searchController.isActive {
            self.tableView.showsVerticalScrollIndicator = false
            gradientLoadingBar.fadeIn()
            self.refreshControl?.endRefreshing()
            tempRealmCount = 0
            totalCourseCount = 0
            getRegisteredCourses()
        }else{
            gradientLoadingBar.fadeOut()
            self.refreshControl?.endRefreshing()
        }
        
        if !Reachability.isConnectedToNetwork() {
            showOfflineMessage()
            gradientLoadingBar.fadeOut()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredCourseList.count : courseList.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CourseTableViewCell", for: indexPath) as! CourseTableViewCell
        
        let realm = try! Realm()
        if indexPath.row < courseList.count{
            if searchController.isActive {
                cell.courseName.text = filteredCourseList[indexPath.row].courseCode
                
                cell.courseFullName.text = filteredCourseList[indexPath.row].courseName.cleanUp()
                cell.courseName.textColor = UIColor.UIColorFromString(string: filteredCourseList[indexPath.row].allotedColor)
                let unreadModules = realm.objects(Module.self).filter("coursename = %@", filteredCourseList[indexPath.row].displayname).filter("read = NO")
                let currentDiscussionModule = realm.objects(Module.self).filter("coursename = %@", filteredCourseList[indexPath.row].displayname).filter("modname = %@", "forum").first
                let unreadDiscussions = realm.objects(Discussion.self).filter("read = NO").filter("moduleId = %@", currentDiscussionModule?.id ?? 0)
                if unreadModules.count + unreadDiscussions.count == 0 {
                    cell.unreadCounterLabel.isHidden = true
                } else {
                    cell.unreadCounterLabel.isHidden = false
                    cell.unreadCounterLabel.text = String(unreadModules.count + unreadDiscussions.count)
                }
            } else {
                cell.courseName.text = courseList[indexPath.row].courseCode
                cell.courseFullName.text = courseList[indexPath.row].courseName.cleanUp()
                cell.courseName.textColor = UIColor.UIColorFromString(string: courseList[indexPath.row].allotedColor)
                let unreadModules = realm.objects(Module.self).filter("coursename = %@", courseList[indexPath.row].displayname).filter("read = NO")
                let currentDiscussionModule = realm.objects(Module.self).filter("coursename = %@", courseList[indexPath.row].displayname).filter("modname = %@", "forum").first
                let unreadDiscussions = realm.objects(Discussion.self).filter("read = NO").filter("moduleId = %@", currentDiscussionModule?.id ?? 0)
                if unreadModules.count + unreadDiscussions.count == 0 {
                    cell.unreadCounterLabel.isHidden = true
                } else {
                    cell.unreadCounterLabel.isHidden = false
                    cell.unreadCounterLabel.text = String(unreadModules.count + unreadDiscussions.count)
                }
                
            }
        }
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        sessionManager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
        
        if courseList.count > indexPath.row{
            stopTheDamnRequests()
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
    
    func showOfflineMessage() {
        banner.show()
        self.perform(#selector(dismissOfflineBanner), with: nil, afterDelay: 1)
    }
    
    @objc func dismissOfflineBanner() {
        banner.dismiss()
    }
    
    func animateTable() {
        tableView.reloadData()
        let cells = tableView.visibleCells
        let tableHeight = tableView.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
        }
        
        var index = 0
        for m in cells {
            let cell: UITableViewCell = m as UITableViewCell
            UIView.animate(withDuration: 0.8, delay: 0.05*Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [], animations: {
                cell.transform = CGAffineTransform.identity;
            }, completion: nil)
            index+=1
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        tableView.reloadData()
        //        refreshData()
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
    func setupColors(colors: [UIColor]) {
        let realm = try! Realm()
        var currentCourseCode = String()
        var currentIndex = 0
        for i in 0..<courseList.count{
            if i == 0{
                currentCourseCode = courseList[0].courseCode
                currentIndex = 0
            }
            if courseList[i].courseCode == currentCourseCode{
                try! realm.write {
                    courseList[i].allotedColor = UIColor.StringFromUIColor(color: colors[currentIndex])
                }
                
            }else{
                currentIndex+=1;
                if currentIndex == colors.count{
                    currentIndex = 0
                }
                currentCourseCode = courseList[i].courseCode
                try! realm.write {
                    courseList[i].allotedColor = UIColor.StringFromUIColor(color: colors[currentIndex])
                }
                
            }
            
        }
    }
    func downloadDashboardCourseContents(courseName: String, courseId: Int) {
        
        
        let FINAL_URL = constant.BASE_URL + constant.GET_COURSE_CONTENT
        let params : [String:Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "courseid" : courseId]
        var readModuleIds = [Int]()
        let queue = DispatchQueue.global(qos: .userInteractive)
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON (queue: queue) { (response) in
            let realm = try! Realm()
            if response.result.isSuccess {
                let courseContent = JSON(response.value as Any)
                let realmSections = realm.objects(CourseSection.self).filter("courseId = \(courseId)")
                // get read status for all modules and add read ones to readModuleNames
                for i in 0..<realmSections.count {
                    for j in 0..<realmSections[i].modules.count {
                        if realmSections[i].modules[j].read && !readModuleIds.contains(realmSections[i].modules[j].id) {
                            readModuleIds.append(realmSections[i].modules[j].id)
                        }
                    }
                }
                if realmSections.count != 0{
                    try! realm.write {
                        realm.delete(realm.objects(Module.self).filter("coursename = %@", courseName))
                        realm.delete(realm.objects(CourseSection.self).filter("courseId = \(courseId)"))
                        
                    }
                }
                
                for i in 0 ..< courseContent.count {
                    if courseContent[i]["modules"].count > 0 || courseContent[i]["summary"] != "" {
                        let section = CourseSection()
                        section.name = courseContent[i]["name"].string!
                        if courseContent[i]["summary"] != "" {
                            // create a summary module and load it in a discussion cell
                            let summaryModule = Module()
                            summaryModule.name = "Summary"
                            summaryModule.coursename = courseName
                            summaryModule.moduleDescription = courseContent[i]["summary"].string!
                            summaryModule.modname = "summary"
                            summaryModule.id = courseContent[i]["id"].int!
                            summaryModule.read = true
                            section.modules.append(summaryModule)
                        } // add summary module
                        for j in 0 ..< courseContent[i]["modules"].array!.count {
                            let moduleData = Module()
                            moduleData.modname = courseContent[i]["modules"][j]["modname"].string!
                            moduleData.id = courseContent[i]["modules"][j]["id"].int!
                            if moduleData.modname == "resource" {
                                if (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!).contains("td.bits-hyderabad.ac.in") {
                                    moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string! +
                                        "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)")
                                    moduleData.mimetype = courseContent[i]["modules"][j]["contents"][0]["mimetype"].string!
                                    moduleData.filename = courseContent[i]["modules"][j]["contents"][0]["filename"].string!
                                }
                                else {
                                    moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!)
                                }
                            } else if moduleData.modname == "forum" {
                                readModuleIds.append(courseContent[i]["modules"][j]["instance"].int!)
                                moduleData.id = courseContent[i]["modules"][j]["instance"].int!
                                
                                moduleData.read = true
                            }else if moduleData.modname == "folder"{
                                
                                let itemCount = courseContent[i]["modules"][j]["contents"].count
                                for a in 0..<itemCount{
                                    let newModule = Module()
                                    newModule.coursename = courseName
                                    newModule.filename = courseContent[i]["modules"][j]["contents"][a]["filename"].string!
                                    newModule.read = true
                                    
                                    if courseContent[i]["modules"][j]["contents"][a]["fileurl"].string!.contains("td.bits-hyderabad.ac.in") {
                                        newModule.fileurl = courseContent[i]["modules"][j]["contents"][a]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                    }
                                    newModule.mimetype = courseContent[i]["modules"][j]["contents"][a]["mimetype"].string!
                                    newModule.id = (moduleData.id * 1000) + a + 1
                                    moduleData.fileModules.append(newModule)
                                }
                            } else if moduleData.modname == "url" {
                                moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!)
                            }
                            
                            moduleData.name = courseContent[i]["modules"][j]["name"].string!
                            if readModuleIds.contains(courseContent[i]["modules"][j]["id"].int!) {
                                moduleData.read = true
                            }
                            if courseContent[i]["modules"][j]["description"].string != nil {
                                moduleData.moduleDescription = courseContent[i]["modules"][j]["description"].string!
                            }
                            moduleData.coursename = courseName
                            section.modules.append(moduleData)
                        }
                        section.courseId = courseId
                        section.key = String(courseId) + section.name
                        section.dateCreated = Date().timeIntervalSince1970
                        try! realm.write {
                            realm.add(section, update: .modified)
                            
                        }
                    }
                }
            }
            self.tempRealmCount += 1
            if self.tempRealmCount == self.totalCourseCount {
                // download discussions here
                //
                self.downloadDiscussions {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.gradientLoadingBar.fadeOut()
                    }
                }
            }
        }
        
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
    
    func logoutCurrentUser() {
        let realm = try! Realm()
        
        try! realm.write {
            realm.deleteAll()
            
        }
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
    }
    
    func downloadDiscussions(completion : @escaping () -> Void) {
        let realm = try! Realm()
        let discussionModules = realm.objects(Module.self).filter("modname = %@", "forum")
        let totalCount = discussionModules.count
        var totalDone = 0
        for x in 0..<discussionModules.count {
            let constants = Constants.Global.self
            let moduleId = discussionModules[x].id
            let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "forumid" : String(discussionModules[x].id)]
            let FINAL_URL : String = constants.BASE_URL + constants.GET_FORUM_DISCUSSIONS
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON(queue: DispatchQueue.global(qos: .userInteractive)) { (response) in
                if response.result.isSuccess {
                    let discussionResponse = JSON(response.value as Any)
                    if discussionResponse["discussions"].count != 0 {
                        for i in 0 ..< discussionResponse["discussions"].count {
                            let discussion = Discussion()
                            discussion.name = discussionResponse["discussions"][i]["name"].string ?? "No Name"
                            discussion.author = discussionResponse["discussions"][i]["userfullname"].string?.capitalized ?? ""
                            discussion.date = discussionResponse["discussions"][i]["created"].int!
                            discussion.message = discussionResponse["discussions"][i]["message"].string ?? "No Content"
                            discussion.id = discussionResponse["discussions"][i]["id"].int!
                            discussion.moduleId = moduleId
                            if discussionResponse["discussions"][i]["attachment"].string! != "0" {
                                if discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string?.contains("td.bits-hyderabad.ac.in") ?? false {
                                    discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string! + "?&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                } else {
                                    discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string ?? ""
                                }
                                
                                discussion.filename = discussionResponse["discussions"][i]["attachments"][0]["filename"].string ?? ""
                                discussion.mimetype = discussionResponse["discussions"][i]["attachments"][0]["mimetype"].string ?? ""
                            }
                            let bkgRealm = try! Realm()
                            if bkgRealm.objects(Discussion.self).filter("id = %@", discussion.id).count == 0 {
                                try! bkgRealm.write {
                                    bkgRealm.add(discussion)
                                }
                            }
                            if i == discussionResponse["discussions"].count - 1 {
                                totalDone += 1
                                if totalDone == totalCount {
                                    print("Completed loading discussions")
                                    completion()
                                }
                            }
                        }
                    } else {
                        totalDone += 1
                    }
                }
            }
        }
        
    }
}
