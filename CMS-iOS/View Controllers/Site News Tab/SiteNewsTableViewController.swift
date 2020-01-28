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
import SwiftKeychainWrapper
import GradientLoadingBar

class SiteNewsTableViewController: UITableViewController {
    
    let constants = Constants.Global.self
    var discussionArray = [Discussion]()
    var currentDiscussion = Discussion()
    private let gradientLoadingBar = GradientActivityIndicatorView()
    
    let refreshController = UIRefreshControl()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupNavBar()
        setupGradientLoadingBar()
        
        if #available(iOS 13.0, *) {
            refreshController.tintColor = .label
        } else {
            // Fallback on earlier versions
            refreshController.tintColor = .black
            
        }
        refreshController.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshController
        
        getSiteNews {
            self.gradientLoadingBar.fadeOut()
            self.tableView.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        gradientLoadingBar.fadeOut()
    }
    
    func setupNavBar() {
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
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
        gradientLoadingBar.fadeIn()
        let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!]
        let FINAL_URL : String = constants.BASE_URL + constants.GET_SITE_NEWS
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let siteNews = JSON(response.value as Any)
                self.discussionArray.removeAll()
                for i in 0 ..< siteNews["discussions"].count {
                    let discussion = Discussion()
                    discussion.name = siteNews["discussions"][i]["name"].string ?? "No Name"
                    discussion.author = siteNews["discussions"][i]["userfullname"].string?.capitalized ?? ""
                    discussion.date = siteNews["discussions"][i]["created"].int!
                    discussion.message = siteNews["discussions"][i]["message"].string ?? "No Content"
                    if siteNews["discussions"][i]["attachment"].string! != "0" {
                        //                        discussion.attachment = (siteNews["discussions"][i]["attachments"][0]["fileurl"].string ?? "") + "?token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                        if siteNews["discussions"][i]["attachments"][0]["fileurl"].string != nil {
                            discussion.attachment = siteNews["discussions"][i]["attachments"][0]["fileurl"].string! + "?token=\(KeychainWrapper.standard.string(forKey: "userPassword")!)"
                        } else {
                            discussion.attachment = ""
                        }
                        discussion.filename = siteNews["discussions"][i]["attachments"][0]["filename"].string ?? ""
                        discussion.mimetype = siteNews["discussions"][i]["attachments"][0]["mimetype"].string ?? ""
                    }
                    self.discussionArray.append(discussion)
                }
                completion()
            }
        }
                
    }
    
    @objc func refreshData() {
        self.refreshControl!.endRefreshing()
        getSiteNews {
            self.tableView.reloadData()
            self.gradientLoadingBar.fadeOut()
        }
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
}
