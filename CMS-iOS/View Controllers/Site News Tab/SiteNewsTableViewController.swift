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
    var discussionViewModels = [DiscussionViewModel]()
    var currentDiscussion = Discussion()
    private let gradientLoadingBar = GradientActivityIndicatorView()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UINib(nibName: "DiscussionTableViewCell", bundle: nil), forCellReuseIdentifier: "discussionCell")
        setupNavBar()
        setupGradientLoadingBar()
        self.refreshControl = UIRefreshControl()
        tableView.refreshControl = self.refreshControl
        refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        self.getOfflineSiteNews { (discussionViewModels) in
            self.discussionViewModels = discussionViewModels
            self.tableView.reloadData()
        }
        if Reachability.isConnectedToNetwork() {
            gradientLoadingBar.fadeIn()
            self.getSiteNews { (discussionViewModels) in
                self.gradientLoadingBar.fadeOut()
                self.discussionViewModels = discussionViewModels
                self.tableView.reloadData()
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
        return discussionViewModels.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 130
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "discussionCell", for: indexPath) as! DiscussionTableViewCell
        let discussionVM = discussionViewModels[indexPath.row]
        cell.timeLabel.text = discussionVM.date
        cell.contentPreviewLabel.text = discussionVM.description.html2String
        cell.titleLabel.text = discussionVM.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let realm = try! Realm()
        self.currentDiscussion = realm.objects(Discussion.self).filter("id = %@", self.discussionViewModels[indexPath.row].id).first!
        performSegue(withIdentifier: "goToDiscussion", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! DiscussionViewController
        destinationVC.selectedDiscussion = self.currentDiscussion
    }
    
    func getOfflineSiteNews(completion: @escaping ([DiscussionViewModel]) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let realm = try! Realm()
            let realmDiscussions = realm.objects(Discussion.self).filter("moduleId = %@", 0).sorted(byKeyPath: "date", ascending: false)
            let discussionViewModels = Array(realmDiscussions.map({ DiscussionViewModel(name: $0.name, id: $0.id, description: $0.message, date: self.epochConvert(epoch: $0.date), read: true) }))
            DispatchQueue.main.async {
                completion(discussionViewModels)
            }
        }
        
    }
    
    func getSiteNews(completion: @escaping ([DiscussionViewModel]) -> Void) {
        let params : [String : String] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!]
        let FINAL_URL : String = constants.BASE_URL + constants.GET_SITE_NEWS
        let queue = DispatchQueue.global(qos: .userInteractive)
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON(queue: queue) { (response) in
            if response.result.isSuccess {
                let siteNews = JSON(response.value as Any)
                let realm = try! Realm()
                try! realm.write {
                    realm.delete(realm.objects(Discussion.self).filter("moduleId = %@", 0)) // removes all site news since they dont have a module id
                    
                }
                var closureVMs = [DiscussionViewModel]()
                for i in 0 ..< siteNews["discussions"].count {
                    let discussion = Discussion()
                    discussion.name = siteNews["discussions"][i]["name"].string ?? "No Name"
                    discussion.author = siteNews["discussions"][i]["userfullname"].string?.capitalized ?? ""
                    discussion.date = siteNews["discussions"][i]["created"].int!
                    discussion.message = siteNews["discussions"][i]["message"].string ?? "No Content"
                    // sometimes site news and course discussions may have the same ids, leading to weird errors, so a factor of 1000 is multiplied to site news ids to keep the ids different to prevent these errors
                    discussion.id = (siteNews["discussions"][i]["discussion"].int ?? 0) * 1000
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
                    closureVMs.append(DiscussionViewModel(name: discussion.name, id: discussion.id, description: discussion.message, date: self.epochConvert(epoch: discussion.date), read: true))
                    try! realm.write {
                        realm.add(discussion, update: .modified)
                    }
                }
                DispatchQueue.main.async {
                    completion(closureVMs)
                }
            }
        }
        
    }
    
    @objc func refreshData() {
        if Reachability.isConnectedToNetwork() {
            gradientLoadingBar.fadeIn()
            self.getSiteNews { (discussionViewModels) in
                self.discussionViewModels = discussionViewModels
                self.gradientLoadingBar.fadeOut()
                self.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.refreshControl?.endRefreshing()
                }
            }
        } else {
            // display offline banner
            showOfflineMessage()
            self.refreshControl?.endRefreshing()
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
