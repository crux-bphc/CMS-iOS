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
import SVProgressHUD
import SwiftKeychainWrapper
import MobileCoreServices
import RealmSwift

class CourseDetailsViewController : UITableViewController {
    
    @IBOutlet var courseLabel: UITableView!
    
    var sectionArray = [CourseSection]()
    var currentCourse = Course()
    var selectedModule = Module()
    var discussionArray = [Discussion]()
    let refreshController = UIRefreshControl()
    let realm = try! Realm()
    
    let constants = Constants.Global.self
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        self.title = currentCourse.displayname
        if #available(iOS 13.0, *) {
            refreshControl?.tintColor = .label
        } else {
            // Fallback on earlier versions
            refreshControl?.tintColor = .black
            
        }
        refreshController.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshController
        tableView.reloadData()
        
        if sectionArray.isEmpty {
            getCourseContent { (courses) in
                self.updateUI()
                SVProgressHUD.dismiss()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    func getCourseContent(completion: @escaping ([CourseSection]) -> Void) {
        
        if Reachability.isConnectedToNetwork(){
            let FINAL_URL = constants.BASE_URL + constants.GET_COURSE_CONTENT
            let params : [String:Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "courseid" : currentCourse.courseid]
            SVProgressHUD.show()
            
            Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
                if response.result.isSuccess {
                    let courseContent = JSON(response.value as Any)
                    let realmSections = self.realm.objects(CourseSection.self).filter("courseId = \(self.currentCourse.courseid)")
                    if realmSections.count != 0{
                        try! self.realm.write {
                            self.realm.delete(realmSections)
                        }
                    }
                    
                    self.sectionArray.removeAll()
                    for i in 0 ..< courseContent.count {
                        if courseContent[i]["modules"].count > 0 {
                            let section = CourseSection()
                            section.name = courseContent[i]["name"].string!
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
                                }else if moduleData.modname == "folder"{
                                    
                                    let itemCount = courseContent[i]["modules"][j]["contents"].count
                                    for a in 0..<itemCount{
                                        let newModule = Module()
                                        newModule.coursename = self.currentCourse.displayname
                                        newModule.filename = courseContent[i]["modules"][j]["contents"][a]["filename"].string!
                                        
                                        if courseContent[i]["modules"][j]["contents"][a]["fileurl"].string!.contains("td.bits-hyderabad.ac.in"){
                                            newModule.fileurl = courseContent[i]["modules"][j]["contents"][a]["fileurl"].string! + "&token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                                        }
                                        newModule.mimetype = courseContent[i]["modules"][j]["contents"][a]["mimetype"].string!
                                        moduleData.fileModules.append(newModule)
                                    }
                                } else if moduleData.modname == "url" {
                                    moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string!)
                                }
                                
                                moduleData.name = courseContent[i]["modules"][j]["name"].string!
                                if courseContent[i]["modules"][j]["description"].string != nil {
                                    moduleData.moduleDescription = courseContent[i]["modules"][j]["description"].string!
                                }
                                moduleData.coursename = self.currentCourse.displayname
                                section.modules.append(moduleData)
                                section.courseId = self.currentCourse.courseid
                            }
                            self.sectionArray.append(section)
                            try! self.realm.write {
                                self.realm.add(section)
                            }
                        }
                    }
                }
                completion(self.sectionArray)
            }
        }
        else{
            // try to get modules from memory
            
            let sections = self.realm.objects(CourseSection.self).filter("courseId = \(currentCourse.courseid)")
            
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
        self.refreshControl!.beginRefreshing()
        getCourseContent{ (courses) in
            self.refreshControl!.endRefreshing()
            SVProgressHUD.dismiss()
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseCourse")
        cell.textLabel?.text = sectionArray[indexPath.section].modules[indexPath.row].name
        if !sectionArray[indexPath.section].modules[indexPath.row].read {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.absoluteURL.appendingPathComponent(sectionArray[indexPath.section].modules[indexPath.row].coursename)
        let destination = dataPath.appendingPathComponent("\(String(sectionArray[indexPath.section].modules[indexPath.row].id) + sectionArray[indexPath.section].modules[indexPath.row].filename)")
        if FileManager().fileExists(atPath: destination.path){
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
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionArray[section].modules.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionArray[section].name
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let realmModule = realm.objects(Module.self)[indexPath.row]
        try! realm.write {
            realmModule.read = true
        }
        
        self.selectedModule = sectionArray[indexPath.section].modules[indexPath.row]
        if self.selectedModule.modname == "assign" {
            let alert = UIAlertController(title: "Assignments not supported", message: "Assignments are not supported on the mobile version of CMS.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
        if selectedModule.modname == "forum" {
            performSegue(withIdentifier: "goToAnnoucements", sender: self)
        }else if selectedModule.modname == "folder"{
            // set destination view controllers module as
            performSegue(withIdentifier: "goToFolder", sender: self)
        }else {
            performSegue(withIdentifier: "goToModule", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updateUI() {
        self.title = currentCourse.displayname
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
}
