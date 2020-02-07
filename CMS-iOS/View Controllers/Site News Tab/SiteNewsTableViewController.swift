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
import RealmSwift
import NotificationBannerSwift

class SiteNewsTableViewController: UITableViewController {
    
    let banner = NotificationBanner(title: "Offline", subtitle: nil, style: .danger)
    let constants = Constants.Global.self
    var discussionArray = [Discussion]()
    var currentDiscussion = Discussion()
    private let gradientLoadingBar = GradientActivityIndicatorView()
    
    let refreshController = UIRefreshControl()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: "DiscussionTableViewCell", bundle: nil), forCellReuseIdentifier: "discussionCell")
        
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
        
        if Reachability.isConnectedToNetwork() {
            getSiteNews {
                self.gradientLoadingBar.fadeOut()
                self.tableView.reloadData()
            }
        } else {
            // load from realm
            let realm = try! Realm()
            let realmDiscussions = realm.objects(Discussion.self).filter("moduleId = %@", 0)
            if realmDiscussions.count > 0 {
                discussionArray.removeAll()
                for discussion in realmDiscussions {
                    discussionArray.append(discussion)
                }
            }
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "discussionCell", for: indexPath) as! DiscussionTableViewCell
        cell.timeLabel.text = epochConvert(epoch: self.discussionArray[indexPath.row].date)
        cell.contentPreviewLabel.text = discussionArray[indexPath.row].message.html2String
        cell.titleLabel.text = discussionArray[indexPath.row].name
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
                print(siteNews)
                self.discussionArray.removeAll()
                let realm = try! Realm()
                try! realm.write {
                    realm.delete(realm.objects(Discussion.self).filter("moduleId = %@", 0)) // removes all site news since they dont have a module id
                }
                for i in 0 ..< siteNews["discussions"].count {
                    let discussion = Discussion()
                    discussion.name = siteNews["discussions"][i]["name"].string ?? "No Name"
                    discussion.author = siteNews["discussions"][i]["userfullname"].string?.capitalized ?? ""
                    discussion.date = siteNews["discussions"][i]["created"].int!
                    discussion.message = siteNews["discussions"][i]["message"].string ?? "No Content"
                    discussion.id = siteNews["discussions"][i]["discussion"].int ?? 0
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
                    try! realm.write {
                        realm.add(discussion, update: .modified)
                    }
                }
                completion()
            }
        }
        
    }
    
    @objc func refreshData() {
        self.refreshControl!.endRefreshing()
        if Reachability.isConnectedToNetwork() {
            getSiteNews {
                self.gradientLoadingBar.fadeOut()
                self.tableView.reloadData()
            }
        } else {
            // display offline banner
            showOfflineMessage()
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
    
    func epochConvert(epoch: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epoch))
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = DateFormatter.Style.none //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        dateFormatter.timeZone = .current
        let localDate = dateFormatter.string(from: date)
        return localDate
    }
    
    func showOfflineMessage() {
        banner.show()
        self.perform(#selector(dismissOfflineBanner), with: nil, afterDelay: 1)
    }
    
    @objc func dismissOfflineBanner() {
        banner.dismiss()
    }
    
}
