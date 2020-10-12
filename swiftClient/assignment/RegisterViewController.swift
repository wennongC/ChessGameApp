//
//  RegisterViewController.swift
//  assignment
//
//  Created by Wennong Cai on 22/5/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

// RegisterViewController is the register process screen of the app. When a new account is registered, the related new document will be inserted into Firebase as well.

class RegisterViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPassField: UITextField!
    @IBOutlet weak var userNameField: UITextField!
    
    var authController: Auth?
    var db: Firestore?
    var usersRef: CollectionReference?
    
    var loginDelegate: presetDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        authController = Auth.auth()
        db = Firestore.firestore()
        usersRef = db?.collection("users")
        
        // Set the TextField's delegate, for later closing softkeyboard use.
        emailField.delegate = self
        passwordField.delegate = self
        confirmPassField.delegate = self
        userNameField.delegate = self
    }
    
    // If user don't want to continue register a new account
    @IBAction func backButtonClick(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // If user has completed all information
    @IBAction func confirmButtonClick(_ sender: Any) {
        showSpinner(onView: view) // show a loading animation and disable users to press the button multiple times
        if integrityCheck() {
            if authController == nil {
                createAlertMsg(title: "AuthController Error", msg: "Sorry, there is something wrong about this app. You cannot register currently, please contact the developer")
                removeSpinner()
            } else {
                let email = emailField.text!
                let password = passwordField.text!
                let username = userNameField.text!
                authController!.createUser(withEmail: email, password: password) { (authResult, error) in
                    if let error = error {
                        print(error.localizedDescription)
                        self.createAlertMsg(title: "Register Error", msg: error.localizedDescription)
                        self.removeSpinner()
                        return
                    }
                    
                    if let result = authResult {
                        let email = result.user.email!
                        Firestore.firestore().collection("users")
                            .document(email)
                            .setData([
                                "userEmail": email,
                                "userName": username,
                                "win": 0,
                                "draw": 0,
                                "lose": 0
                                ], completion: { err in
                                    if let err = err {
                                        // If fail to create a new record in the Firestore, then delete the new Auth record as well
                                        authResult?.user.delete(completion: nil)
                                        self.createAlertMsg(title: "Database Error", msg: err.localizedDescription)
                                        self.removeSpinner()
                                    } else {
                                        self.loginDelegate?.presetFieldValue(email: email, password: password)
                                        do {
                                            // Sign out here because we need to give users a chance to select "save email" or "save password"
                                            try self.authController?.signOut()
                                        } catch let signOutError as NSError {
                                            print ("Error signing out: %@", signOutError)
                                        }
                                        
                                        // Send the email verification to prevent use other people's email to register account
                                        authResult?.user.sendEmailVerification(completion: { (error) in
                                            if let e = error {
                                                self.createAlertMsg(title: "Error", msg: e.localizedDescription)
                                            } else {
                                                self.removeSpinner()
                                                self.createAlertMsg(title: "Account created!", msg: "Just one last to go! We have sent a verification email to \(email), you need click the link in the email to finish you registration.\nThank you for playing Chess Game", returnVal: true)
                                            }
                                        })
                                    }
                        })
                    }
                    
                }
            }
        } else {
            removeSpinner()
        }
    }

    // check the integrity of text field
    func integrityCheck() -> Bool {
        var warning = ""
        // initial all field's background color
        emailField.backgroundColor = UIColor.white
        passwordField.backgroundColor = UIColor.white
        confirmPassField.backgroundColor = UIColor.white
        userNameField.backgroundColor = UIColor.white
        
        // check the email is not empty
        if emailField.text == nil || emailField.text!.count == 0 {
            emailField.backgroundColor = GlobalVars.FIELD_WARNING_COLOR
            warning += "❌Enter email address please\n"
        }
        
        // check the password is enough long and same with confirm password
        if passwordField.text == nil || passwordField.text!.count < 6 {
            passwordField.backgroundColor = GlobalVars.FIELD_WARNING_COLOR
            warning += "❌Password should be at least 6 characters\n"
        } else if confirmPassField.text == nil || confirmPassField.text != passwordField.text {
            confirmPassField.backgroundColor = GlobalVars.FIELD_WARNING_COLOR
            warning += "❌The confirm password should be same with password\n"
        }
        
        // check the user name is not empty
        if userNameField.text == nil || userNameField.text!.count == 0 {
            userNameField.backgroundColor = GlobalVars.FIELD_WARNING_COLOR
            warning += "❌Enter user name please\n"
        }
        
        // decide if it is a successful integrity check
        if warning != "" {
            createAlertMsg(title: "Something Wrong!", msg: warning)
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.backgroundColor = UIColor.white
    }
    // Enable the return button close the soft-keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    // Enable close the soft-keyboard when textField lose focus
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
