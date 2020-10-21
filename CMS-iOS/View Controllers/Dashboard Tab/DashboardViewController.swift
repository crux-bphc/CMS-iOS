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
import SafariServices

class DashboardViewController : UITableViewController, UISearchBarDelegate, UISearchResultsUpdating, UIGestureRecognizerDelegate {
    
    let banner = NotificationBanner(title: "Offline", subtitle: nil, style: .danger)
    let constant = Constants.Global.self
    var courseViewModels = [DashboardViewModel]()
    var userDetails = User()
    var selectedCourse = Course()
    var selectedModule = Module()
    var selectedAnnouncement = Discussion()
    var shouldHideSemester = false
    var searching : Bool = false
    private let gradientLoadingBar = GradientActivityIndicatorView()
    var filteredCourseViewModels = [DashboardViewModel]()
    let searchController = UISearchController(searchResultsController: nil)
    var downloadArray : [URL] = []
    var localURLArray : [URL] = []
    let sessionManager = Alamofire.SessionManager.default
    var searchModules = [FilterModule]()
    var searchAnnouncements = [FilterDiscussion]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldHideSemester = UserDefaults.standard.bool(forKey: "hidesSemester")
        setupGradientLoadingBar()
        let realm = try! Realm()
        if let currentUser = realm.objects(User.self).first {
            userDetails = currentUser
        }
        
        setupNavBar()
        loadOfflineCourses()
        refreshData()
        
        if #available(iOS 13.0, *) {
            refreshControl?.tintColor = .secondaryLabel
        } else {
            // Fallback on earlier versions
            refreshControl?.tintColor = .darkGray
            
        }
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        
        tableView.refreshControl = refreshControl
        tableView.reloadData()
        tableView.register(UINib(nibName: "CourseTableViewCell", bundle: nil), forCellReuseIdentifier: "CourseTableViewCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ModuleTableViewCellSearching")
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
        self.reloadUnreadCounts()
        let newVal = UserDefaults.standard.bool(forKey: "hidesSemester")
        if newVal != self.shouldHideSemester {
            self.shouldHideSemester = newVal
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //        refreshControl?.endRefreshing()
        gradientLoadingBar.fadeOut()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "goToCourseContent":
            let destinationVC = segue.destination as! CourseDetailsViewController
            destinationVC.currentCourse = selectedCourse
        case "goToModuleDirectly":
                let destinationVC = segue.destination as! ModuleViewController
                destinationVC.selectedModule = selectedModule
        case "goToFolderModuleDirectly":
                let destinationVC = segue.destination as! FolderContentViewController
                destinationVC.currentModule = self.selectedModule
        case "goToDiscussionDirectly":
            let destinationVC = segue.destination as! DiscussionViewController
            destinationVC.selectedDiscussion = selectedAnnouncement
        default:
            break
        }
    }
    
    func setupNavBar() {
        navigationItem.largeTitleDisplayMode = .always
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
                    actionSheet = UIAlertController(title: filteredCourseViewModels[rowNo].courseName.cleanUp(), message: nil, preferredStyle: .actionSheet)
                }
            }else{
                if let rowNo = indexPath?.row{
                    actionSheet = UIAlertController(title: courseViewModels[rowNo].courseName.cleanUp(), message: nil, preferredStyle: .actionSheet)
                }
            }
            let downloadAction = UIAlertAction(title: "Download Course", style: .default) { (action) in
                
                if Reachability.isConnectedToNetwork() {
                    
                    var courseToDownload = Course()
                    if let rowNo = indexPath?.row{
                        let realm = try! Realm()
                        let courseId = self.searchController.isActive ? self.filteredCourseViewModels[rowNo].courseId : self.courseViewModels[rowNo].courseId
                        courseToDownload = realm.objects(Course.self).filter("courseId = %@", courseId).first!
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
                            self.reloadUnreadCounts()
                            
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                warning.addAction(doItAction)
                warning.addAction(cancelAction)
                self.present(warning, animated: true, completion: nil)
            }
            let unenrollAction = UIAlertAction(title: "Unenroll from Website", style: .destructive) { (_) in
                let courseId = self.searchController.isActive ? self.filteredCourseViewModels[indexPath!.row].courseId : self.courseViewModels[indexPath!.row].courseId
                let alertShownBefore = UserDefaults.standard.bool(forKey: "unenrollAlertShown")
                if !alertShownBefore {
                    let alert = UIAlertController(title: "Important", message: "Since the Moodle API doesn't support unenrolling from a course, you will be redirected to the course page on the CMS website where you can unenroll. You may need to log in.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        UserDefaults.standard.setValue(true, forKey: "unenrollAlertShown")
                        self.presentUnenrollVC(for: courseId)
                    }))
                    self.present(alert, animated: true)
                } else {
                    self.presentUnenrollVC(for: courseId)
                }
                
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(downloadAction)
            actionSheet.addAction(unenrollAction)
            actionSheet.addAction(markAllRead)
            actionSheet.addAction(cancelAction)
            present(actionSheet, animated: true, completion: nil)
        }
    }
    
    func presentUnenrollVC(for courseId: Int) {
        let url = URL(string: "https://td.bits-hyderabad.ac.in/moodle/course/view.php?id=\(courseId)")
        let safariVC = SFSafariViewController(url: url!)
        safariVC.delegate = self
        self.present(safariVC, animated: true, completion: nil)
    }
    
    func filterItemsForSearch(string: String) {
        
        filteredCourseViewModels = courseViewModels.filter() { $0.courseName.contains(string.uppercased()) }
        DispatchQueue.global(qos: .userInteractive).async {
            let realm = try! Realm()
            let filterModules = realm.objects(Module.self).filter("name CONTAINS[c] %@ AND modname != 'forum'", string.lowercased())
            let filterAnnouncements = realm.objects(Discussion.self).filter("name CONTAINS[c] %@ AND moduleId != 0", string.lowercased())
            self.searchModules.removeAll()
            for mod in filterModules {
                let filterModule = FilterModule(name: mod.name, coursename: mod.coursename, id: mod.id)
                self.searchModules.append(filterModule)
            }
            self.searchAnnouncements.removeAll()
            for ann in filterAnnouncements {
                let annName = ann.name
                var annCourseName = ""
                if let annoucenmentModule = realm.objects(Module.self).filter("id = %@", ann.moduleId).first {
                    annCourseName = annoucenmentModule.coursename
                }
                let filterAnnouncement = FilterDiscussion(name: annName, coursename: annCourseName, id: ann.id)
                self.searchAnnouncements.append(filterAnnouncement)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        self.filterItemsForSearch(string: searchController.searchBar.text!)
        if !searchController.isActive {
            self.tableView.reloadData()

        }
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
    
    func loadOfflineCourses() {
        let realm = try! Realm()
        let realmCourses = realm.objects(Course.self)
        let offlineCourseViewModels = Array(realmCourses.map({ DashboardViewModel(courseCode: $0.courseCode, courseName: $0.courseName, courseId: $0.courseid, courseColor: UIColor.UIColorFromString(string: $0.allotedColor)) }))
        DashboardDataManager.shared.calculateUnreadCounts(courseViewModels: offlineCourseViewModels) { (newOfflineViewModels) in
            self.courseViewModels = offlineCourseViewModels
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func refreshData() {
        gradientLoadingBar.fadeIn()
        if !searchController.isActive && Reachability.isConnectedToNetwork() {
            self.tableView.showsVerticalScrollIndicator = false
            gradientLoadingBar.fadeIn()
            self.refreshControl?.endRefreshing()
            DashboardDataManager.shared.getAndStoreCourses(userId: userDetails.userid) { (dashboardViewModels, shouldLogOut) in
                if shouldLogOut {
                    // show message
                } else if dashboardViewModels != nil {
                    DashboardDataManager.shared.getAndStoreModules {
                        DashboardDataManager.shared.getAndStoreDiscussions {
                            DashboardDataManager.shared.calculateUnreadCounts(courseViewModels: dashboardViewModels!) { (newCourseViewModels) in
                                self.courseViewModels = newCourseViewModels
                                DispatchQueue.main.async {
                                    self.gradientLoadingBar.fadeOut()
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    }
                }
            }
            
        } else {
            gradientLoadingBar.fadeOut()
            self.refreshControl?.endRefreshing()
        }
        
        if !Reachability.isConnectedToNetwork() {
            showOfflineMessage()
            gradientLoadingBar.fadeOut()
        }
    }
    
    func reloadUnreadCounts() {
        DashboardDataManager.shared.calculateUnreadCounts(courseViewModels: self.courseViewModels) { (newCourseViewModels) in
            self.courseViewModels = newCourseViewModels
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive {
            switch section {
            case 0:
                if filteredCourseViewModels.count > 0 {
                    return "Courses"
                }
            case 1:
                if searchModules.count > 0 {
                    return "Modules"
                }
            case 2:
                if searchAnnouncements.count > 0 {
                    return "Announcements"
                }
            default:
                return nil
            }
        }
        return nil
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return searchController.isActive ? 3 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return searchController.isActive ? filteredCourseViewModels.count : courseViewModels.count
        case 1:
            return searchModules.count
        case 2:
            return searchAnnouncements.count
        default:
            return 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.masksToBounds = true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CourseTableViewCell", for: indexPath) as! CourseTableViewCell
            
            let realm = try! Realm()
            let count = searchController.isActive ? filteredCourseViewModels.count : courseViewModels.count
            if indexPath.row < count {
                if searchController.isActive {
                    cell.courseName.text = filteredCourseViewModels[indexPath.row].courseCode
                    
                    cell.courseFullName.text = filteredCourseViewModels[indexPath.row].courseName.cleanUp().removeSemester()
                    if filteredCourseViewModels[indexPath.row].courseName.contains("FIRST SEMESTER 2020-21") && !self.shouldHideSemester {
                        cell.semesterLabel.isHidden = false
                        cell.semesterLabel.text = "2020-21"
                    } else {
                        cell.semesterLabel.isHidden = true
                    }
                    cell.courseName.textColor = filteredCourseViewModels[indexPath.row].courseColor
                    cell.unreadCounterLabel.text = String(filteredCourseViewModels[indexPath.row].unreadCount)
                    cell.unreadCounterLabel.isHidden = !filteredCourseViewModels[indexPath.row].shouldShowUnreadCounter
                } else {
                    cell.courseName.text = courseViewModels[indexPath.row].courseCode
                    cell.courseFullName.text = courseViewModels[indexPath.row].courseName.cleanUp().removeSemester()
                    if courseViewModels[indexPath.row].courseName.contains("FIRST SEMESTER 2020-21") && !self.shouldHideSemester {
                        cell.semesterLabel.isHidden = false
                        cell.semesterLabel.text = "2020-21"
                    } else {
                        cell.semesterLabel.isHidden = true
                    }
                    cell.courseName.textColor = courseViewModels[indexPath.row].courseColor
                    cell.unreadCounterLabel.text = String(courseViewModels[indexPath.row].unreadCount)
                    cell.unreadCounterLabel.isHidden = !courseViewModels[indexPath.row].shouldShowUnreadCounter
                }
            }
            
            
            return cell
        } else if indexPath.section == 1 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ModuleTableViewCellSearching")
            
            if indexPath.row < searchModules.count {
                cell.textLabel?.text = searchModules[indexPath.row].name
                cell.detailTextLabel?.text = searchModules[indexPath.row].coursename
                
            }
            
            
            return cell
        } else if indexPath.section == 2 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ModuleTableViewCellSearching")
            
            if indexPath.row < searchAnnouncements.count {
                cell.textLabel?.text = searchAnnouncements[indexPath.row].name
                cell.detailTextLabel?.text = searchAnnouncements[indexPath.row].coursename
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 100
        case 1:
            return 50
        case 2:
            return 50
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.tableView.deselectRow(at: indexPath, animated: true)
        sessionManager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
        stopTheDamnRequests()
        
        if indexPath.section == 0 {
            if courseViewModels.count > indexPath.row {
                tableView.deselectRow(at: indexPath, animated: true)
                let realm = try! Realm()
                if searchController.isActive {
                    self.selectedCourse = realm.objects(Course.self).filter("courseid = %@", filteredCourseViewModels[indexPath.row].courseId).first!
                }
                else {
                    self.selectedCourse = realm.objects(Course.self).filter("courseid = %@", courseViewModels[indexPath.row].courseId).first!
                }
                performSegue(withIdentifier: "goToCourseContent", sender: self)
            }
        } else if indexPath.section == 1 {
            let realm = try! Realm()
            self.selectedModule = realm.objects(Module.self).filter("id = %@", searchModules[indexPath.row].id).first!
            if self.selectedModule.modname == "folder" {
                self.redirectToFolderModule()
            } else if self.selectedModule.modname == "assign" {
                let alert = UIAlertController(title: "Assignments not supported", message: "Assignments are not supported on the mobile version of CMS.", preferredStyle: .alert)
                let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                alert.addAction(action)
                present(alert, animated: true, completion: nil)
            } else {
                self.redirectToModule()
            }
        } else if indexPath.section == 2 {
            let realm = try! Realm()
            self.selectedAnnouncement = realm.objects(Discussion.self).filter("id = %@", searchAnnouncements[indexPath.row].id).first!
            redirectToAnnouncement()
        }
    }
    
    func showOfflineMessage() {
        banner.show()
        self.perform(#selector(dismissOfflineBanner), with: nil, afterDelay: 1)
    }
    
    @objc func dismissOfflineBanner() {
        banner.dismiss()
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
        SpotlightIndex.shared.deindexAllItems()
        let _: Bool = KeychainWrapper.standard.removeObject(forKey: "userPassword")
    }
    
    func redirectToModule() {
        self.performSegue(withIdentifier: "goToModuleDirectly", sender: self)
    }
    
    func redirectToAnnouncement() {
        self.performSegue(withIdentifier: "goToDiscussionDirectly", sender: self)
    }
    
    func redirectToFolderModule() {
        self.performSegue(withIdentifier: "goToFolderModuleDirectly", sender: self)
    }
}

extension DashboardViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.refreshData()
    }
}
