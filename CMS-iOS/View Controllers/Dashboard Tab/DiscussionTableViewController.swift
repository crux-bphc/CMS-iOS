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
import GradientLoadingBar
import RealmSwift

class DiscussionTableViewController: UITableViewController {
    
    private let gradientLoadingBar = GradientActivityIndicatorView()
    let constants = Constants.Global.self
    var discussionArray = [Discussion]()
    var currentDiscussion = Discussion()
    var currentModule = Module()
    let sessionManager = Alamofire.SessionManager.default
    
    @IBOutlet weak var addDiscussionButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "DiscussionTableViewCell", bundle: nil), forCellReuseIdentifier: "discussionCell")
        self.addDiscussionButton.isEnabled = false
        setupGradientLoadingBar()
        gradientLoadingBar.fadeOut()
        canAddDiscussion()
        self.title = currentModule.name
        getCourseDiscussions {
            self.tableView.reloadData()
            self.gradientLoadingBar.fadeOut()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        gradientLoadingBar.fadeOut()
//        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if discussionArray.count == 0 {
            return 0
        } else {
            return discussionArray.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        sessionManager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
        
        if discussionArray.count != 0 {
            self.currentDiscussion = discussionArray[indexPath.row]
            let realm = try! Realm()
            try! realm.write {
                    discussionArray[indexPath.row].read = true
            }
            
            performSegue(withIdentifier: "goToDiscussionDetails", sender: self)
        } else {
            self.tableView.isScrollEnabled = false
            self.tableView.allowsSelection = false
        }
        self.tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "discussionCell", for: indexPath) as! DiscussionTableViewCell
        
//        let cell = UITableViewCell(reuseIdentifier: "discussionCell") as! DiscussionTableViewCell
        if discussionArray.count == 0 {
//            cell.textLabel?.text = "No discussions"
//            cell.textLabel?.textAlignment = .center
//            self.tableView.separatorStyle = .none
        } else {
//            cell.textLabel?.text = discussionArray[indexPath.row].name
//            cell.cellDiscussion = discussionArray[indexPath.row]
            cell.timeLabel.text = epochConvert(epoch: self.discussionArray[indexPath.row].date)
//            print(self.discussionArray[indexPath.row].date)
            cell.contentPreviewLabel.text = discussionArray[indexPath.row].message.html2String
            cell.titleLabel.text = discussionArray[indexPath.row].name
            if !discussionArray[indexPath.row].read {
                cell.titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .bold)
                cell.timeLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
                cell.contentPreviewLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .semibold)
            } else {
                cell.titleLabel.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
                cell.timeLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
                cell.contentPreviewLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
            }
            self.tableView.separatorStyle = .singleLine
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToDiscussionDetails" {
            let destinationVC = segue.destination as! DiscussionViewController
            destinationVC.selectedDiscussion = self.currentDiscussion
            destinationVC.discussionName = self.currentModule.coursename
        } else if segue.identifier == "goToAddDiscussion" {
            let destinationVC = segue.destination as! AddDiscussionViewController
            destinationVC.currentForum = String(self.currentModule.id)
        }
    }
    
    func getCourseDiscussions(completion: @escaping () -> Void) {
        
        if Reachability.isConnectedToNetwork() {
            let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "forumid" : String(currentModule.id)]
            let FINAL_URL : String = constants.BASE_URL + constants.GET_FORUM_DISCUSSIONS
            gradientLoadingBar.fadeIn()
            
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
                            realm.delete(realm.objects(Discussion.self).filter("moduleId = %@", self.currentModule.id))
                        }
                        for i in 0 ..< discussionResponse["discussions"].count {
                            let discussion = Discussion()
                            if discussionResponse["discussions"][i]["pinned"].bool! {
                               discussion.name = "📌 " + (discussionResponse["discussions"][i]["name"].string ?? "No Name")
                            } else {
                                discussion.name = discussionResponse["discussions"][i]["name"].string ?? "No Name"
                            }
                            
                            discussion.author = discussionResponse["discussions"][i]["userfullname"].string?.capitalized ?? ""
                            discussion.date = discussionResponse["discussions"][i]["created"].int!
                            discussion.message = discussionResponse["discussions"][i]["message"].string ?? "No Content"
                            discussion.id = discussionResponse["discussions"][i]["id"].int!
                            discussion.read = readDiscussionIds.contains(discussion.id) ? true : false
                            discussion.moduleId = self.currentModule.id
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
                            
                            self.discussionArray.append(discussion)
                        }
                        completion()
                    }
                }
            }
        } else {
            let realm = try! Realm()
            let realmDiscussions = realm.objects(Discussion.self).filter("moduleId = %@", self.currentModule.id)
            self.discussionArray.removeAll()
            for i in 0..<realmDiscussions.count {
                discussionArray.append(realmDiscussions[i])
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
                    self.addDiscussionButton.tintColor = UIColor.clear
                    self.addDiscussionButton.style = .plain
                    self.addDiscussionButton.isEnabled = false
                } else {
                    self.addDiscussionButton.isEnabled = true
                }
            }
        }
    }
    @IBAction func addDiscussionButtonPressed(_ sender: Any) {
        
        sessionManager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
        
        performSegue(withIdentifier: "goToAddDiscussion", sender: self)
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
    
    func epochConvert(epoch: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epoch))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        dateFormatter.timeZone = .current
        let localDate = dateFormatter.string(from: date)
        return localDate
    }
    
}

extension Data {
    var html2AttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: self, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}

extension String {
    var html2AttributedString: NSAttributedString? {
        return Data(utf8).html2AttributedString
    }
    var html2String: String {
        return html2AttributedString?.string ?? ""
    }
}
