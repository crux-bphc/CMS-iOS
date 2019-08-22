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

class CourseDetailsViewController : UITableViewController {
    
    @IBOutlet var courseLabel: UITableView!
    
    var sectionArray = [CourseSection]()
    var currentCourse = Course()
    var selectedModule = Module()
    
    let constants = Constants.Global.self
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SVProgressHUD.dismiss()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if sectionArray.isEmpty {
            getCourseContent { (courses) in
                self.updateUI()
                for i in 0 ..< self.sectionArray.count {
                    print(self.sectionArray[i].name)
                }
                SVProgressHUD.dismiss()
            }
        }
        
    }
    
    func getCourseContent(completion: @escaping ([CourseSection]) -> Void) {
        print("Function called")
        let FINAL_URL = constants.BASE_URL + constants.GET_COURSE_CONTENT
        let params : [String:Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "courseid" : currentCourse.courseid]
        SVProgressHUD.show()
        
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let courseContent = JSON(response.value)
                for i in 0 ..< courseContent.count {
                    if courseContent[i]["modules"].count > 0 {
                        let section = CourseSection()
                        section.name = courseContent[i]["name"].string!
                        print("module count is \(courseContent[i]["modules"].count)")
                        
                        for j in 0 ..< courseContent[i]["modules"].array!.count {
                            let moduleData = Module()
                            moduleData.modname = courseContent[i]["modules"][j]["modname"].string!
                            if moduleData.modname != "forum" {
                                moduleData.fileurl = (courseContent[i]["modules"][j]["contents"][0]["fileurl"].string! + "&token=\(self.constants.secret)")
                                print(courseContent[i]["modules"][j]["contents"][0]["fileurl"].string! + "&token=\(self.constants.secret)")
                            }
                            moduleData.name = courseContent[i]["modules"][j]["name"].string!
                            if courseContent[i]["modules"][j]["description"].string != nil {
                                moduleData.description = courseContent[i]["modules"][j]["description"].string!
                            }
                            section.modules.append(moduleData)
                            print(moduleData.name)
                        }
                        self.sectionArray.append(section)
                    }
                }
            }
            completion(self.sectionArray)
            print("function complete")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! ModuleViewController
        destinationVC.selectedModule = self.selectedModule
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseCourse")
        cell.textLabel?.text = sectionArray[indexPath.section].modules[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionArray[section].modules.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionArray[section].name
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedModule = sectionArray[indexPath.section].modules[indexPath.row]
        performSegue(withIdentifier: "goToModule", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func updateUI() {
        self.tableView.reloadData()
        self.title = currentCourse.displayname
    }
    
}
