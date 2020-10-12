//
//  LoginViewController.swift
//  assignment
//
//  Created by Wennong Cai on 30/3/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit
import FirebaseAuth

// LoginViewController is the login screen, you can login, register, reset password from here.

protocol presetDelegate {
    // automatically enter the detail to the text field after registration
    func presetFieldValue(email: String, password: String)
}

class LoginViewController: UIViewController, UITextFieldDelegate, presetDelegate {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var saveEmailSwitch: UISwitch!
    @IBOutlet weak var savePasswordSwitch: UISwitch!
    
    var authController: Auth?
    
    let udKey_saveEmailSwitch = "saveEmailSwitch"
    let udKey_savePassSwitch = "savePassSwitch"
    let udKey_savedEmail = "savedEmail"
    let udKey_savedPass = "savedPass"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authController = Auth.auth()
        
        // Set the TextField's delegate, for later closing softkeyboard use.
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        detectIfAlreadyLogin() // Detect if user already logged in
        
        // Detect if user has saved previous login details
        if let email = UserDefaults.standard.string(forKey: udKey_savedEmail) {
            emailField.text = email
        }
        if let password = UserDefaults.standard.string(forKey: udKey_savedPass) {
            passwordField.text = password
        }
        saveEmailSwitch.isOn = UserDefaults.standard.bool(forKey: udKey_saveEmailSwitch)
        savePasswordSwitch.isOn = UserDefaults.standard.bool(forKey: udKey_savePassSwitch)
    }
    
    // bakc to main menu
    @IBAction func backButtonClick(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func forgetPasswordButtonClick(_ sender: Any) {
        showResetPasswordAlert()
    }
    
    // login
    @IBAction func loginButtonClick(_ sender: Any) {
        if emailField.text == nil || emailField.text?.count == 0 {
            createAlertMsg(title: "Woops", msg: "Enter the email please")
        } else if passwordField.text == nil || passwordField.text?.count == 0 {
            createAlertMsg(title: "Woops", msg: "Enter the password please")
        } else {
            login()
        }
    }
    
    // Prepare for the OnlineViewController
    func detectIfAlreadyLogin() {
        if authController?.currentUser != nil {
            signOut()
            
            //   In my testing of the app, I found that it is a little bit annoying if the screen automatically jump to the next screen when user just come back from the Registration, user will not able to select the "Save Email" or "Save Pass" Switch.
            //   So the below code is commented out in the final design.
//            performSegue(withIdentifier: "onlineLoginSegue", sender: self)
        }
    }
    
    // Perform firebase Auth login action
    func login() {
        showSpinner(onView: view) // prevent from logining multiple times
        let email = emailField.text!
        let password = passwordField.text!
        authController?.signIn(withEmail: email, password: password) { (user, error) in
            if let error = error {
                self.createAlertMsg(title: "Woops!", msg: error.localizedDescription)
                self.removeSpinner()
                return
            }
            
            // If login successfully
            // Save the value in the persistent data is requested by users
            if self.saveEmailSwitch.isOn {
                UserDefaults.standard.set(email, forKey: self.udKey_savedEmail)
                UserDefaults.standard.set(true, forKey: self.udKey_saveEmailSwitch)
            } else {
                UserDefaults.standard.set(nil, forKey: self.udKey_savedEmail)
                UserDefaults.standard.set(false, forKey: self.udKey_saveEmailSwitch)
            }
            if self.savePasswordSwitch.isOn {
                UserDefaults.standard.set(password, forKey: self.udKey_savedPass)
                UserDefaults.standard.set(true, forKey: self.udKey_savePassSwitch)
            } else {
                UserDefaults.standard.set(nil, forKey: self.udKey_savedPass)
                UserDefaults.standard.set(false, forKey: self.udKey_savePassSwitch)
            }
            self.removeSpinner()
            
            // Then check if user has already verify their email
            if let user = self.authController?.currentUser {
                if user.isEmailVerified {
                    self.performSegue(withIdentifier: "onlineLoginSegue", sender: self)
                } else {
                    self.showEmailDidNotVerifyAlert(user: user)
                }
                
            } else {
                self.createAlertMsg(title: "Error", msg: "Some problem occurred when login")
            }
        }
    }
    
    
    func showResetPasswordAlert() {
        let alert = UIAlertController(title: "Reset Password", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Send", style: .default) { (_) in
            if let txtField = alert.textFields?.first, let text = txtField.text {
                self.showSpinner(onView: self.view)
                self.authController?.sendPasswordReset(withEmail: text, completion: { error in
                    self.removeSpinner()
                    if let e = error {
                        self.createAlertMsg(title: "Error", msg: e.localizedDescription)
                    } else {
                        self.createAlertMsg(title: "Send", msg: "An email with password reset link has been sent to this email address")
                    }
                })
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alert.addTextField { (textField) in
            textField.placeholder = "Enter your email address"
        }
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func showEmailDidNotVerifyAlert(user: User) {
        let email = user.email ?? "error"
        let alert = UIAlertController(title: "Woops", message: "It seemed that your email account <\(email)> is still not verified yet. If you did not receive the verification email, you could click the button to let us send it again.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Send", style: .default) { _ in
            self.showSpinner(onView: self.view, msg: "Sending")
            user.sendEmailVerification(completion: { (error) in
                self.removeSpinner()
                if let e = error {
                    self.createAlertMsg(title: "Error", msg: e.localizedDescription)
                } else {
                    self.createAlertMsg(title: "Email sent", msg: "We have sent another email to the \(email).\nPlease follow the instructions on that email, then come back to re-login, Thank You!")
                }
                self.signOut()
            })
        }
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in self.signOut() })
        self.present(alert, animated: true, completion: nil)
    }
    
    func signOut() {
        do {
            try authController?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    
    // Prepare for the RegisterViewController
    func presetFieldValue(email: String, password: String) {
        emailField.text = email
        passwordField.text = password
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "registerSegue" {
            if let vc = segue.destination as? RegisterViewController {
                vc.loginDelegate = self
            }
        }
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
