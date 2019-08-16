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

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var keyField: UITextField!
    let constant = Constants.Global.self
    let defaults = UserDefaults.standard
    
    var secretKey = ""
    var currentUser = User()
    
    override func viewDidLoad() {
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
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func logIn(completion : @escaping (User) -> Void) {
        
        let params : [String:String] = ["wstoken" : self.keyField.text ?? ""]
        let FINAL_URL = constant.BASE_URL + constant.LOGIN
        
        SVProgressHUD.show()
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constant.headers).responseJSON { (response) in
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
                    self.defaults.set(self.keyField.text, forKey: "secret")
                    self.currentUser.name = userData["firstname"].string!.capitalized
                    self.performSegue(withIdentifier: "goToDashboard", sender: self)
                    completion(self.currentUser)
                }
            }
        }
        SVProgressHUD.dismiss()
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        print("click")
        if keyField.text != "" {
            self.secretKey = keyField.text!
            logIn { (userdeets) in
                print(userdeets)
            }
        } else {
            print("Enter a key")
        }
    }
    
    @IBAction func helpButtonPressed(_ sender: UIButton) {
        UIApplication.shared.open(URL(string: "https://docs.google.com/document/d/1FUMAdVXCWhrnFT18LpYdeIMwlWPAnOezRweKOE-CRtA/edit")!, options: [:], completionHandler: nil)
    }
    
    
}

