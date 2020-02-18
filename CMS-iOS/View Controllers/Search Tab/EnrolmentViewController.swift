//
//  EnrolmentViewController.swift
//  CMS-iOS
//
//  Created by Hridik Punukollu on 18/08/19.
//  Copyright © 2019 Hridik Punukollu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SVProgressHUD
import SwiftKeychainWrapper

class EnrolmentViewController: UIViewController {
    
    @IBOutlet weak var courseLabel: UILabel!
    @IBOutlet weak var instructorLabel: UILabel!
    @IBOutlet weak var enrolButton: UIButton!
    let constants = Constants.Global.self
    var enrolmentCourse = Course()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enrolButton.layer.cornerRadius = 10
        courseLabel.text = enrolmentCourse.displayname.cleanUp()
        instructorLabel.text = enrolmentCourse.faculty
        self.navigationItem.largeTitleDisplayMode = .never
        self.title = "Course Details"
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        SVProgressHUD.dismiss()
    }
    
    func enrolCourse (completion: @escaping () -> Void) {
        
        let params : [String : Any] = ["wstoken" : KeychainWrapper.standard.string(forKey: "userPassword")!, "courseid" : enrolmentCourse.courseid]
        let FINAL_URL = constants.BASE_URL + constants.SELF_ENROL_USER
        SVProgressHUD.show()
        Alamofire.request(FINAL_URL, method: .get, parameters: params, headers: constants.headers).responseJSON { (response) in
            if response.result.isSuccess {
                let enrolmentData = JSON(response.value as Any)
                print(enrolmentData)
                if enrolmentData["status"].bool! {
                    print("Enrolled Successfully")
                    completion()
                } else {
                    let alert = UIAlertController(title: "Unable to Enrol", message: "Enrolment for this course is either disabled or you are already enrolled.", preferredStyle: .alert)
                    let dismiss = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
                    alert.addAction(dismiss)
                    SVProgressHUD.dismiss()
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToEnrolledCourse" {
            let destinationVC = segue.destination as! CourseDetailsViewController
            destinationVC.currentCourse = enrolmentCourse
        }
    }
    
    @IBAction func enrolButtonPresses(_ sender: UIButton) {
        
        enrolCourse {
            print("enrolled in course")
            SVProgressHUD.dismiss()
            self.performSegue(withIdentifier: "goToEnrolledCourse", sender: self)
        }
        
    }
    
}
