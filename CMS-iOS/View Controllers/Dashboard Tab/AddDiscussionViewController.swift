//
//  AddDiscussionViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 17/09/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import SwiftKeychainWrapper

class AddDiscussionViewController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var messageBodyTextField: UITextView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    let constants = Constants.Global.self
    var currentForum : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let toolbar = UIToolbar(frame: CGRect(origin: .zero, size: .init(width: view.frame.width, height: 37)))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButtonKeyBoard = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonAction))
        toolbar.setItems([flexSpace,doneButtonKeyBoard], animated: false)
        titleTextField.inputAccessoryView = toolbar
        messageBodyTextField.inputAccessoryView = toolbar
        
    }
    
    func addDiscussion(completion: @escaping () -> Void) {
        
        let headers = constants.headers
        let params : [String : String] = ["wstoken":KeychainWrapper.standard.string(forKey: "userPassword")!, "subject" : self.titleTextField.text!, "message" : self.messageBodyTextField.text!, "forumid" : self.currentForum]
        let FINAL_URL = constants.BASE_URL + constants.ADD_DISCUSSION
        
        Alamofire.request(FINAL_URL, method: .post, parameters: params, headers: headers).responseJSON { (response) in
            if response.result.isSuccess {
                let confirmation = JSON(response.value as Any)
                if confirmation["exception"].string == nil {
                    SVProgressHUD.showSuccess(withStatus: "Added discussion.")
                    SVProgressHUD.dismiss(withDelay: 0.5)
                    completion()
                } else {
                    let alert = UIAlertController(title: "Error", message: "There was an error in adding the discussion.", preferredStyle: .alert)
                    let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                    alert.addAction(action)
                    self.present(alert, animated: true, completion: {
                        completion()
                    })
                }
            }
        }
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        if (titleTextField.text!.count>0 && messageBodyTextField.text!.count>0) {
            titleTextField.isEnabled = false
            messageBodyTextField.isEditable = false
            addDiscussion {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            let alert = UIAlertController(title: "No Title/Body text", message: "Your title and/or body is empty. Please check them and try again.", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
}
