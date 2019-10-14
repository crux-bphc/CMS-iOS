//
//  ViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 09/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import SwiftKeychainWrapper
import RealmSwift
import SafariServices
class LoginViewController: UIViewController {
    
    @IBOutlet weak var keyField: UITextField!
    
    @IBOutlet weak var googleLoginBtn: UIButton!
    
    let constant = Constants.Global.self
    
    var currentUser = User()
    let realm = try! Realm()
    
    override func viewDidLoad() {
        
//        googleLoginBtn.setImage(UIImage(named: "google_icon"), for: .normal)
//        googleLoginBtn.imageEdgeInsets = UIEdgeInsets(top: 10, left: 200, bottom: 10, right: 300)
        SVProgressHUD.dismiss()
        if Reachability.isConnectedToNetwork() {
            checkSavedPassword()
        }else{
            
            // get user from realm
            let realm = try! Realm()
            if let realmUser = realm.objects(User.self).first{
                currentUser = realmUser
            }
        }
        if #available(iOS 12.0, *) {
            if traitCollection.userInterfaceStyle == .dark{
                SVProgressHUD.setDefaultStyle(.dark)
            }else{
                SVProgressHUD.setDefaultStyle(.light)
            }
        } else {
            SVProgressHUD.setDefaultStyle(.dark)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !Reachability.isConnectedToNetwork() {
            let alert = UIAlertController(title: "Unable to connect", message: "You are not connected to the internet. Please check your connection and relaunch the app.", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "Dismiss", style: .default) { _ in
                
                let realm = try! Realm()
                let users = realm.objects(User.self)
                if (users.count != 0){
                    self.currentUser = users[0]
                }
                self.performSegue(withIdentifier: "goToDashboard", sender: self)
            }
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "goToDashboard":
            let tabVC = segue.destination as! UITabBarController
            let nextVC = tabVC.viewControllers![0] as! UINavigationController
            let destinationVC = nextVC.topViewController as! DashboardViewController
            destinationVC.userDetails = self.currentUser
        default:
            break
        }
    }
    
    func checkSavedPassword() {
        if let retrievedPassword: String = KeychainWrapper.standard.string(forKey: "userPassword") {
            self.view.isUserInteractionEnabled = false
            logIn (password: retrievedPassword, loggedin: true) {
                print(retrievedPassword)
                print("Password Retrieved. Logging in.")
                self.view.isUserInteractionEnabled = true
            }
        }
    }
    
    func logIn(password: String, loggedin: Bool, completion : @escaping () -> Void) {
        print("Password used for request is: \(password)")
        let params : [String:String] = ["wstoken" : password]
        let FINAL_URL = constant.BASE_URL + constant.LOGIN
        
        SVProgressHUD.show()
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let userData = JSON(response.value as Any)
                if (userData["exception"].string != nil) {
                    let alert = UIAlertController(title: "Invalid key", message: "The key that you have entered is invalid. Please check and try again.", preferredStyle: .alert)
                    let dismiss = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                    alert.addAction(dismiss)
                    self.present(alert, animated: true, completion: {
                        self.keyField.text = ""
                    })
                    print("Enter the key again.")
                } else {
                    if loggedin == false {
                        let savedPassword : Bool = KeychainWrapper.standard.set(password, forKey: "userPassword")
                        print(savedPassword)
                        
                    }
                    
                    self.currentUser.name = userData["firstname"].string!.capitalized
                    self.currentUser.userid = userData["userid"].int!
                    
                    let user = User()
                    user.name = self.currentUser.name
                    user.email = self.currentUser.email
                    user.loggedIn = self.currentUser.loggedIn
                    user.userid = self.currentUser.userid
                    let realm = try! Realm()
                    try! realm.write {
                        
                        realm.add(user)
                    }
                    
                    self.keyField.text = ""
                    self.performSegue(withIdentifier: "goToDashboard", sender: self)
                    completion()
                }
            }
        }
    }
    
    func loginWithGoogle(input: String){
        let base64String = input.replacingOccurrences(of: "token=", with: "")
        let decodedData = Data(base64Encoded: base64String)!
        let decodedString = String(data: decodedData, encoding: .utf8)!
        print("decoded string = \(decodedString)")
        let start = decodedString.index(decodedString.startIndex, offsetBy: 35)
        let end = decodedString.index(decodedString.startIndex, offsetBy: 67)
        let decodedUserIDSub = (decodedString[start..<end])
        let decodedUserID = String(decodedUserIDSub)
        print("decoded = \(decodedUserID)")
        logIn (password: decodedUserID, loggedin: false) {
            print("Password Retrieved. Logging in.")
            self.view.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        if keyField.text != "" {
            self.view.isUserInteractionEnabled = false
            logIn(password: keyField.text!, loggedin: false) {
                self.view.isUserInteractionEnabled = true
                print("Continue")
            }
        }
        else {
            let alert = UIAlertController(title: "Enter a key", message: "You have not entered a key. Please enter a valid key or press help.", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func helpButtonPressed(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://docs.google.com/document/d/1F21bBNZ-h7MQh0HWM-rSbo6j2qKLoOaFY5Tl_If9C_0/edit?usp=sharing")!, options: [:], completionHandler: nil)
        
    }
    
    @IBAction func googleLoginPressed(_ sender: UIButton) {
        self.view.isUserInteractionEnabled = false
        UIApplication.shared.open(URL(string: "https://td.bits-hyderabad.ac.in/moodle/admin/tool/mobile/launch.php?service=moodle_mobile_app&passport=144.05993500117754&urlscheme=cruxcmsios&oauthsso=1")!, options: [:], completionHandler: nil)
        
    }
    
}


