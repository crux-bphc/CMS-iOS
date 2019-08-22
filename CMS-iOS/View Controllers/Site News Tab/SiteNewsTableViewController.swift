//
//  SiteNewsTableViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 20/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import SwiftKeychainWrapper

class SiteNewsTableViewController: UITableViewController {

    let constants = Constants.Global.self
    var discussionArray = [Discussion]()
    var currentDiscussion = Discussion()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getSiteNews {
            SVProgressHUD.dismiss()
            self.tableView.reloadData()
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return discussionArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = discussionArray[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.currentDiscussion = discussionArray[indexPath.row]
        performSegue(withIdentifier: "goToDiscussion", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! DiscussionViewController
        destinationVC.selectedDiscussion = self.currentDiscussion
    }
    
    func getSiteNews(completion: @escaping () -> Void) {
        
        let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!]
        let FINAL_URL : String = constants.BASE_URL + constants.GET_SITE_NEWS
        SVProgressHUD.show()
        
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let siteNews = JSON(response.value)
                for i in 0 ..< siteNews["discussions"].count {
                    let discussion = Discussion()
                    discussion.name = siteNews["discussions"][i]["name"].string ?? "No Name"
                    discussion.author = "Admin User"
                    discussion.date = siteNews["discussions"][i]["created"].int!
                    discussion.message = siteNews["discussions"][i]["message"].string ?? "No Content"
                    if siteNews["discussions"][i]["attachment"].int != nil {
                        discussion.attachment = siteNews["discussions"][i]["attachments"][0]["fileurl"].string!
                    }
                    self.discussionArray.append(discussion)
                    completion()
                }
                
            }
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
