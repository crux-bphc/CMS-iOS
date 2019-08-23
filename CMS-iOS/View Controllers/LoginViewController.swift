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

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var keyField: UITextField!
    let constant = Constants.Global.self
    let defaults = UserDefaults.standard
    
    var secretKey = ""
    var currentUser = User()
    
    override func viewDidLoad() {
        SVProgressHUD.dismiss()
        checkSavedPassword()
        //        super.viewDidLoad()
        //        if defaults.string(forKey: "secret") != nil {
        //            performSegue(withIdentifier: "goToDashboard", sender: self)
        //        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //        if defaults.string(forKey: "secret") != nil {
        //            performSegue(withIdentifier: "goToDashboard", sender: self)
        //        }
    }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            let segueID = segue.identifier ?? ""
            switch segueID {
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
            logIn (password: retrievedPassword, loggedin: true) {
                print(retrievedPassword)
                print("Password Retrieved. Logging in.")
            }
        }
    }
    
    func logIn(password: String, loggedin: Bool, completion : @escaping () -> Void) {
        print("Password used for request is: \(password)")
        let params : [String:String] = ["wstoken" : password]
        let FINAL_URL = constant.BASE_URL + constant.LOGIN
        
        SVProgressHUD.show()
        let req = Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let userData = JSON(response.value)
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
                    self.keyField.text = ""
                    self.performSegue(withIdentifier: "goToDashboard", sender: self)
                    completion()
                }
            }
        }
        print(req)
    }
    
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        print("click")
        if keyField.text != "" {
            logIn(password: keyField.text!, loggedin: false) {
                print("Continue")
            }
        }
        else {
            let alert = UIAlertController(title: "Enter a key", message: "You have not entered a key. Please enter a valid key or press help.", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "Dismisss", style: .default, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func helpButtonPressed(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://docs.google.com/document/d/1FUMAdVXCWhrnFT18LpYdeIMwlWPAnOezRweKOE-CRtA/edit")!, options: [:], completionHandler: nil)
    }
    
    
}

