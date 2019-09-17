//
//  DiscussionTableViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 28/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import SwiftyJSON
import Alamofire
import SVProgressHUD

class DiscussionTableViewController: UITableViewController {
    
    let constants = Constants.Global.self
    var discussionArray = [Discussion]()
    var currentDiscussion = Discussion()
    var currentModule = Module()
    
    @IBOutlet weak var addDiscussionButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SVProgressHUD.dismiss()
        canAddDiscussion()
        getCourseDiscussions {
            self.tableView.reloadData()
            SVProgressHUD.dismiss()
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if discussionArray.count == 0 {
            return 1
        } else {
            return discussionArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if discussionArray.count != 0 {
            self.currentDiscussion = discussionArray[indexPath.row]
            performSegue(withIdentifier: "goToDiscussionDetails", sender: self)
        } else {
            self.tableView.isScrollEnabled = false
            self.tableView.allowsSelection = false
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "reuseCell")
        if discussionArray.count == 0 {
            cell.textLabel?.text = "No discussions"
        } else {
            cell.textLabel?.text = discussionArray[indexPath.row].name
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToDiscussionDetails" {
            let destinationVC = segue.destination as! DiscussionViewController
            destinationVC.selectedDiscussion = self.currentDiscussion
        } else if segue.identifier == "goToAddDiscussion" {
            let destinationVC = segue.destination as! AddDiscussionViewController
            destinationVC.currentForum = String(self.currentModule.id)
        }
    }
    
    func getCourseDiscussions(completion: @escaping () -> Void) {
        
        let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "forumid" : String(currentModule.id)]
        let FINAL_URL : String = constants.BASE_URL + constants.GET_FORUM_DISCUSSIONS
        SVProgressHUD.show()
        
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let discussionResponse = JSON(response.value as Any)
                if discussionResponse["discussions"].count == 0 {
                    completion()
                } else {
                    for i in 0 ..< discussionResponse["discussions"].count {
                        let discussion = Discussion()
                        discussion.name = discussionResponse["discussions"][i]["name"].string ?? "No Name"
                        discussion.author = discussionResponse["discussions"][i]["userfullname"].string?.capitalized ?? ""
                        discussion.date = discussionResponse["discussions"][i]["created"].int!
                        discussion.message = discussionResponse["discussions"][i]["message"].string ?? "No Content"
                        if discussionResponse["discussions"][i]["attachment"].string! != "0" {
                            discussion.attachment = discussionResponse["discussions"][i]["attachments"][0]["fileurl"].string ?? ""
                            discussion.filename = discussionResponse["discussions"][i]["attachments"][0]["filename"].string ?? ""
                            discussion.mimetype = discussionResponse["discussions"][i]["attachments"][0]["mimetype"].string ?? ""
                        }
                        self.discussionArray.append(discussion)
                    }
                    completion()
                }
            }
        }
        
    }
    
    func canAddDiscussion() {
        let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "forumid" : String(currentModule.id)]
        let headers = constants.headers
        let FINAL_URL = constants.BASE_URL + constants.CAN_ADD_DISCUSSIONS
        
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: headers).responseJSON { (response) in
            if response.result.isSuccess {
                let canAdd = JSON(response.value as Any)
                if canAdd["status"].bool == false {
//                    self.addDiscussionButton.width = 0.0
                    self.addDiscussionButton.style = .plain
                    self.addDiscussionButton.isEnabled = false
                }
            }
        }
    }
    @IBAction func addDiscussionButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "goToAddDiscussion", sender: self)
    }
    
}
