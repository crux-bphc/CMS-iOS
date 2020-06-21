//
//  CourseContentsViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 13/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftKeychainWrapper
import MobileCoreServices
import RealmSwift
import GradientLoadingBar
import BadgeSwift

class CourseDetailsViewController : UITableViewController, UIGestureRecognizerDelegate{
    
    @IBOutlet var courseLabel: UITableView!
    
    private let gradientLoadingBar = GradientActivityIndicatorView()
    var sectionArray = [CourseSection]()
    var currentCourse = Course()
    var selectedModule = Module()
    let refreshController = UIRefreshControl()
    let constants = Constants.Global.self
    let sessionManager = Alamofire.SessionManager.default
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "DiscussionTableViewCell", bundle: nil), forCellReuseIdentifier: "discussionCell")
        setupGradientLoadingBar()
        loadModulesFromMemory()
        
        navigationItem.largeTitleDisplayMode = .never
        
        self.title = currentCourse.displayname.cleanUp()
        if #available(iOS 13.0, *) {
            refreshControl?.tintColor = .label
        } else {
            // Fallback on earlier versions
            refreshControl?.tintColor = .black
            
        }
        refreshController.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshController
        tableView.reloadData()
        
        getCourseContent { (courses) in
            self.updateUI()
            self.gradientLoadingBar.fadeOut()
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delegate = self
        self.tableView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        gradientLoadingBar.fadeOut()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func loadModulesFromMemory() {
        let realm = try! Realm()
        let sections = realm.objects(CourseSection.self).filter("courseId = \(currentCourse.courseid)").sorted(byKeyPath: "dateCreated", ascending: true)
        if sections.count != 0 {
            sectionArray.removeAll()
            for i in 0..<sections.count {
                sectionArray.append(sections[i])
                print(sections[i].name)
            }
        } else {
            gradientLoadingBar.fadeIn()
        }
        
    }
    
    func getCourseContent(completion: @escaping ([CourseSection]) -> Void) {
        
        if Reachability.isConnectedToNetwork() {
            let FINAL_URL = constants.BASE_URL + constants.GET_COURSE_CONTENT
            let params : [String:Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "courseid" : currentCourse.courseid]
            var readModuleIds = [Int]()
            gradientLoadingBar.fadeIn()
            
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
                let realm = try! Realm()
                if response.result.isSuccess {
                    let courseContent = JSON(response.value as Any)
                    let realmModules = realm.objects(Module.self).filter("coursename = %@" ,self.currentCourse.displayname)
                    for i in 0..<realmModules.count {
                        if realmModules[i].read && !readModuleIds.contains(realmModules[i].id) {
                                readModuleIds.append(realmModules[i].id)
                            }
                        
                    }
                    let realmSections = realm.objects(CourseSection.self).filter("courseId = \(self.currentCourse.courseid)")
                    if realmSections.count != 0{
                        try! realm.write {
//                            realm.delete(realmSections)
//                            realm.delete(realm.objects(Module.self).filter("coursename = %@", self.currentCourse.displayname))
                        }
                    }
                    
                    self.sectionArray.removeAll()
                    for i in 0 ..< courseContent.count {
                        if courseContent[i]["modules"].count > 0 || courseContent[i]["summary"] != "" {
                            let section = CourseSection()
                            section.name = courseContent[i]["name"].string!
                            if courseContent[i]["summary"] != "" {
                                // create a summary module and load it in a discussion cell
                                let summaryModule = Module()
                                summaryModule.name = "Summary"
                                summaryModule.coursename = self.currentCourse.displayname
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
                                    moduleData.id = courseContent[i]["modules"][j]["instance"].int!
                                    self.downloadDiscussions(currentModule: moduleData) {
                                        DispatchQueue.main.async {
                                            self.tableView.reloadData()
                                        }
                                    }
                                }else if moduleData.modname == "folder"{
                                    
                                    let itemCount = courseContent[i]["modules"][j]["contents"].count
                                    for a in 0..<itemCount{
                                        let newModule = Module()
                                        newModule.coursename = self.currentCourse.displayname
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
                                if readModuleIds.contains(moduleData.id) {
                                    moduleData.read = true
                                    
                                }else if moduleData.name == "Announcements"{
                                    moduleData.read = true
                                }else{
                                    moduleData.read = false
                                }
                                if courseContent[i]["modules"][j]["description"].string != nil {
                                    moduleData.moduleDescription = courseContent[i]["modules"][j]["description"].string!
                                }
                                moduleData.coursename = self.currentCourse.displayname
                                section.modules.append(moduleData)
                            }
                            section.courseId = self.currentCourse.courseid
                            section.key = String(self.currentCourse.courseid) + section.name
                            section.dateCreated = NSDate().timeIntervalSince1970
                            self.sectionArray.append(section)
                            try! realm.write {
                                realm.add(section, update: .modified)
                            }
                        }
                    }
                }
                
                completion(self.sectionArray)
            }
        }
        else{
            // try to get modules from memory
            let realm = try! Realm()
            let sections = realm.objects(CourseSection.self).filter("courseId = \(currentCourse.courseid)")
            if sections.count != 0{
                sectionArray.removeAll()
                for i in 0..<sections.count{
                    sectionArray.append(sections[i])
                }
            }
            updateUI()
        }
    }
    
    @objc func refreshData() {
        if Reachability.isConnectedToNetwork() {
            self.refreshControl!.beginRefreshing()
            
            getCourseContent{ (courses) in
                self.refreshControl!.endRefreshing()
                self.gradientLoadingBar.fadeOut()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToAnnoucements" {
            let destinationVC = segue.destination as! DiscussionTableViewController
            destinationVC.currentModule = self.selectedModule
        }else if segue.identifier == "goToFolder"{
            
            let destinationVC = segue.destination as! FolderContentViewController
            destinationVC.currentModule = self.selectedModule
        } else {
            let destinationVC = segue.destination as! ModuleViewController
            destinationVC.selectedModule = self.selectedModule
            
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionArray.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if sectionArray[indexPath.section].modules[indexPath.row].modname == "summary" {
            return 130
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sectionArray[indexPath.section].modules[indexPath.row].modname == "summary" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "discussionCell") as! DiscussionTableViewCell
            cell.contentPreviewLabel.text = sectionArray[indexPath.section].modules[indexPath.row].moduleDescription.html2String
            cell.titleLabel.text = sectionArray[indexPath.section].modules[indexPath.row].name
            cell.timeLabel.text = ""
            return cell
            
        }
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "reuseCourse")
        cell.textLabel?.text = sectionArray[indexPath.section].modules[indexPath.row].name.cleanUp()
        if !sectionArray[indexPath.section].modules[indexPath.row].read {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.absoluteURL.appendingPathComponent(sectionArray[indexPath.section].modules[indexPath.row].coursename)
        let destination = dataPath.appendingPathComponent("\(String(sectionArray[indexPath.section].modules[indexPath.row].id) + sectionArray[indexPath.section].modules[indexPath.row].filename)")
        if FileManager().fileExists(atPath: destination.path) {
            // module has already been downloaded
            cell.textLabel?.textColor = .systemGreen
        }
        
        if sectionArray[indexPath.section].modules[indexPath.row].modname == "folder"{
            if #available(iOS 12.0, *) {
                if self.traitCollection.userInterfaceStyle == .dark {
                    cell.imageView?.image = UIImage(named: "folder_dark")
                } else {
                    cell.imageView?.image = UIImage(named: "folder")
                }
            } else {
                // Fallback on earlier versions
                cell.imageView?.image = UIImage(named: "folder")
            }
        } else if sectionArray[indexPath.section].modules[indexPath.row].modname == "resource" {
            if #available(iOS 12.0, *) {
                if self.traitCollection.userInterfaceStyle == .dark {
                    changeImage(mode: "_dark", cell: cell, sectionArray: sectionArray, indexPath: indexPath)
                } else {
                    changeImage(mode: "", cell: cell, sectionArray: sectionArray, indexPath: indexPath)
                }
            } else {
                changeImage(mode: "", cell: cell, sectionArray: sectionArray, indexPath: indexPath)
            }
        } else if sectionArray[indexPath.section].modules[indexPath.row].modname == "url" {
            if #available(iOS 12.0, *) {
                if self.traitCollection.userInterfaceStyle == .dark {
                    cell.imageView?.image = UIImage(named: "web_dark")
                } else {
                    cell.imageView?.image = UIImage(named: "web")
                }
            } else {
                cell.imageView?.image = UIImage(named: "web")
            }
        } else if sectionArray[indexPath.section].modules[indexPath.row].modname == "forum" {
            // this code should show a badge showing the count of announcements, however the badge is not centred vertically
            // *********************************************************************************************************
            //            let announcementsBadge = BadgeSwift()
            //            announcementsBadge.text = "2"
            //            announcementsBadge.frame.size = CGSize(width: 22, height: 22)
            //            announcementsBadge.font = UIFont.preferredFont(forTextStyle: .body)
            //            announcementsBadge.textColor = .white
            //            announcementsBadge.badgeColor = .systemBlue
            //            cell.accessoryView = announcementsBadge
            // *********************************************************************************************************
            
            // this code just shows the count on the right side like the iOS mail app
            // *********************************************************************************************************
            let realm = try! Realm()
            let counterText = String(realm.objects(Discussion.self).filter("moduleId = %@", sectionArray[indexPath.section].modules[indexPath.row].id).filter("read = NO").count)
            cell.detailTextLabel?.text = (counterText == "0") ? "" : counterText
            cell.accessoryType = .disclosureIndicator
            // *********************************************************************************************************
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionArray[section].modules.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionArray[section].name.cleanUp()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        sessionManager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
        dataTasks.forEach { $0.cancel() }
        uploadTasks.forEach { $0.cancel() }
        downloadTasks.forEach { $0.cancel() }
        }
        
        let realm = try! Realm()
        let realmModule = realm.objects(Module.self)[indexPath.row]
        try! realm.write {
            realmModule.read = true
        }
        
        self.selectedModule = sectionArray[indexPath.section].modules[indexPath.row]
        if self.selectedModule.modname == "assign" {
            let alert = UIAlertController(title: "Assignments not supported", message: "Assignments are not supported on the mobile version of CMS.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            try! realm.write {
                self.selectedModule.read = true
            }
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
        if selectedModule.modname == "forum" {
            // if name is not announcements show description
            if selectedModule.name == "Announcements" {
                performSegue(withIdentifier: "goToAnnoucements", sender: self)
            } else {
                performSegue(withIdentifier: "goToModule", sender: self)
            }
            
        }else if selectedModule.modname == "folder"{
            // set destination view controllers module as
            performSegue(withIdentifier: "goToFolder", sender: self)
        }else {
            performSegue(withIdentifier: "goToModule", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updateUI() {
        self.title = currentCourse.displayname.cleanUp()
        self.tableView.reloadData()
    }
    
    func changeImage(mode: String, cell: UITableViewCell, sectionArray: [CourseSection], indexPath: IndexPath) {
        switch sectionArray[indexPath.section].modules[indexPath.row].mimetype {
        case "application/pdf":
            cell.imageView?.image = UIImage(named: "pdf\(mode)")
            break
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
            cell.imageView?.image = UIImage(named: "doc\(mode)")
            break
        case "text/plain":
            cell.imageView?.image = UIImage(named: "txt\(mode)")
            break
        case "image/jpeg":
            cell.imageView?.image = UIImage(named: "img\(mode)")
            break
        case "image/png":
            cell.imageView?.image = UIImage(named: "img\(mode)")
            break
        case "application/vnd.ms-excel":
            cell.imageView?.image = UIImage(named: "xls\(mode)")
            break
        case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
            cell.imageView?.image = UIImage(named: "xls\(mode)")
            break
        case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
            cell.imageView?.image = UIImage(named: "ppt\(mode)")
            break
        case "application/zip":
            cell.imageView?.image = UIImage(named: "zip\(mode)")
            break
        case "application/x-rar-compressed":
            cell.imageView?.image = UIImage(named: "zip\(mode)")
            break
        default:
            cell.imageView?.image = UIImage(named: "raw\(mode)")
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateUI()
    }
        func markAllRead() {
            let realm = try! Realm()
            let realmSections = realm.objects(CourseSection.self).filter("courseId = \(self.currentCourse.courseid)")
            for i in 0..<realmSections.count {
                for j in 0..<realmSections[i].modules.count{
                    try! realm.write {
                        realmSections[i].modules[j].read = true
                    }
                }
            }
            tableView.reloadData()
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
    @objc func handleLongPress(longPressGesture: UILongPressGestureRecognizer) {
        let pressLocation = longPressGesture.location(in: self.tableView)
        let indexPath = self.tableView.indexPathForRow(at: pressLocation)
        if indexPath == nil {
        } else if longPressGesture.state == UIGestureRecognizer.State.began {
            let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
            selectionFeedbackGenerator.selectionChanged()
            var actionSheet = UIAlertController()
            if let _ = indexPath?.row{
                actionSheet = UIAlertController(title: sectionArray[indexPath?.section ?? 0].modules[indexPath?.row ?? 0].name, message: nil, preferredStyle: .actionSheet)
            }
            let readAction = UIAlertAction(title: "Mark Read", style: .default) { (_) in
                // mark as read
                let realm = try! Realm()
                try! realm.write {
                    self.sectionArray[indexPath?.section ?? 0].modules[indexPath?.row ?? 0].read = true
                }
                self.tableView.reloadData()
            }
            let markAllRead = UIAlertAction(title: "Mark All Read", style: .default) { (_) in
                self.markAllRead()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(readAction)
            actionSheet.addAction(markAllRead)
            actionSheet.addAction(cancelAction)
            self.present(actionSheet, animated: true, completion: nil)
            
            
            
            
        }
    }
    
    func downloadDiscussions(currentModule : Module, completion : @escaping () -> Void) {
        let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "forumid" : String(currentModule.id)]
        let FINAL_URL : String = constants.BASE_URL + constants.GET_FORUM_DISCUSSIONS
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let discussionResponse = JSON(response.value as Any)
                if discussionResponse["discussions"].count == 0 {
                    completion()
                } else {
                    let realm = try! Realm()
                    var readDiscussionIds = [Int]()
                    let readDiscussions = realm.objects(Discussion.self).filter("read = YES")
                    for i in 0..<readDiscussions.count {
                        readDiscussionIds.append(readDiscussions[i].id)
                    }
                    try! realm.write {
                        realm.delete(realm.objects(Discussion.self).filter("moduleId = %@", currentModule.id))
                    }
                    for i in 0 ..< discussionResponse["discussions"].count {
                        let discussion = Discussion()
                        discussion.name = discussionResponse["discussions"][i]["name"].string ?? "No Name"
                        discussion.author = discussionResponse["discussions"][i]["userfullname"].string?.capitalized ?? ""
                        discussion.date = discussionResponse["discussions"][i]["created"].int!
                        discussion.message = discussionResponse["discussions"][i]["message"].string ?? "No Content"
                        discussion.id = discussionResponse["discussions"][i]["id"].int!
                        discussion.read = readDiscussionIds.contains(discussion.id) ? true : false
                        discussion.moduleId = currentModule.id
                        if discussionResponse["discussions"][i]["attachment"].string! != "0" {
                            if discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string?.contains("td.bits-hyderabad.ac.in") ?? false {
                                discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string! + "?&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                            } else {
                                discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string ?? ""
                            }
                            
                            discussion.filename = discussionResponse["discussions"][i]["attachments"][0]["filename"].string ?? ""
                            discussion.mimetype = discussionResponse["discussions"][i]["attachments"][0]["mimetype"].string ?? ""
                        }
                        try! realm.write {
                            realm.add(discussion, update: .modified)
                        }
                        
                    }
                    completion()
                }
            }
        }
    }
}
